import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/features/global_widget/app_status_overlay/controller/app_status_overlay_controller.dart';

class AppStatusOverlay extends StatelessWidget {
  const AppStatusOverlay({super.key});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double b = bytes.toDouble();
    while (b >= 1024 && i < suffixes.length - 1) {
      b /= 1024;
      i++;
    }
    return '${b.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AppStatusOverlayController(), permanent: true);

    return Obx(() {
      final state = c.state.value;
      final connected = c.hasInternet.value && c.isServerConnected.value;

      final isConnError = !connected && !c.dismissed.value;
      final isUpdateState =
          [
            AppOverlayStatus.updateAvailable,
            AppOverlayStatus.downloadingUpdate,
            AppOverlayStatus.noUpdate,
            AppOverlayStatus.failedUpdate,
          ].contains(state) &&
          !c.dismissed.value;

      final successFull = connected && c.successBanner.value;
      final successIconOnly =
          connected && c.successIcon.value && !c.successBanner.value;
      final isSuccess = successFull || successIconOnly;

      if (!isConnError && !isUpdateState && !isSuccess) {
        return const SizedBox.shrink();
      }

      final screenW = MediaQuery.of(context).size.width;
      final bannerWidth = (screenW * 0.75).clamp(220.0, 340.0);
      final iconSize = (bannerWidth * 0.06).clamp(16.0, 22.0);
      final fontSize = (bannerWidth * 0.045).clamp(12.0, 14.0);
      final actionSize = (bannerWidth * 0.08).clamp(24.0, 32.0);
      final bannerHeight = actionSize + bannerWidth * 0.08 + 4;

      Color color;
      IconData icon;
      String message;
      Widget? actionWidget;

      if (isConnError) {
        final noInternet = !c.hasInternet.value;
        color = noInternet ? const Color(0xFFB00020) : const Color(0xFFB26A00);
        icon = noInternet ? Icons.wifi_off : Icons.cloud_off;
        message = noInternet ? 'Нет интернета' : 'Сервер недоступен';
      } else if (isUpdateState) {
        switch (state) {
          case AppOverlayStatus.updateAvailable:
            color = const Color(0xFF1976D2);
            icon = Icons.system_update;
            message = 'Доступно обновление';
            actionWidget = TextButton(
              onPressed: c.startUpdate,
              child: const Text(
                'Скачать',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
            break;
          case AppOverlayStatus.downloadingUpdate:
            color = const Color(0xFF1976D2);
            icon = Icons.downloading;
            final done = c.downloadedBytes.value;
            final total = c.totalBytes.value;
            final pct = (c.downloadProgress.value * 100).toStringAsFixed(0);

            message = total > 0
                ? 'Скачано: $pct% (${_formatBytes(done)} / ${_formatBytes(total)})'
                : 'Скачивание... (${_formatBytes(done)})';

            actionWidget = SizedBox(
              width: bannerWidth * 0.4,
              child: LinearProgressIndicator(
                value: total > 0 ? c.downloadProgress.value : null,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
            break;
          case AppOverlayStatus.noUpdate:
            color = const Color(0xFF2E7D32);
            icon = Icons.check_circle;
            message = 'Установлена последняя версия';
            break;
          case AppOverlayStatus.failedUpdate:
            color = const Color(0xFFB00020);
            icon = Icons.error;
            message = 'Ошибка при обновлении';
            actionWidget = IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: c.checkUpgrade,
            );
            break;
          default:
            return const SizedBox.shrink();
        }
      } else {
        color = const Color(0xFF2E7D32);
        icon = Icons.done_all;
        message = 'Подключено';
      }

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        left: 16,
        bottom: MediaQuery.of(context).size.height * 0.1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          width: successIconOnly ? (iconSize + 20) : bannerWidth,
          height: successIconOnly ? (iconSize + 20) : bannerHeight,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(
              successIconOnly ? (iconSize + 20) / 2 : 14,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: SizedBox(
              width: bannerWidth,
              height: bannerHeight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  bannerWidth * 0.05,
                  bannerWidth * 0.02,
                  bannerWidth * 0.02,
                  bannerWidth * 0.02,
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: iconSize),
                    SizedBox(width: bannerWidth * 0.03),
                    Expanded(
                      child: Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ?actionWidget,
                    if (state != AppOverlayStatus.downloadingUpdate)
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: iconSize * 0.9,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: actionSize,
                          minHeight: actionSize,
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: isSuccess ? c.dismissSuccess : c.dismiss,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
