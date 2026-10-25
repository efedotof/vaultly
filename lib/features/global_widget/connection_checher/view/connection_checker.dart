import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/features/global_widget/connection_checher/controller/connection_checker_controller.dart';

class ConnectionChecker extends StatelessWidget {
  const ConnectionChecker({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ConnectionCheckerController(), permanent: true);
    return Obx(() {
      final connected = c.hasInternet.value && c.isServerConnected.value;
      final successFull = connected && c.successBanner.value;
      final successIconOnly =
          connected && c.successIcon.value && !c.successBanner.value;
      final success = successFull || successIconOnly;
      final error = !connected && !c.dismissed.value;
      final visible = success || error;

      final noInternet = !c.hasInternet.value;
      final checking = c.state.value == CheckersStatus.checking;

      final screenW = MediaQuery.of(context).size.width;
      final bannerWidth = (screenW * 0.65).clamp(160.0, 300.0);
      final iconSize = (bannerWidth * 0.065).clamp(14.0, 20.0);
      final fontSize = (bannerWidth * 0.045).clamp(10.0, 13.0);
      final actionSize = (bannerWidth * 0.09).clamp(22.0, 30.0);
      final iconOnlySize = iconSize + 20;
      final bannerHeight = actionSize + bannerWidth * 0.06 + 2;

      final color = success
          ? const Color(0xFF2E7D32)
          : noInternet
              ? const Color(0xFFB00020)
              : const Color(0xFFB26A00);

      final icon = success
          ? Icons.done_all
          : noInternet
              ? Icons.wifi_off
              : Icons.cloud_off;

      final message = success
          ? 'Подключено'
          : noInternet
              ? 'Нет интернета'
              : 'Сервер недоступен';

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        left: visible ? 16 : -360,
        bottom: MediaQuery.of(context).size.height * 0.1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: successIconOnly ? iconOnlySize : bannerWidth,
          height: successIconOnly ? iconOnlySize : bannerHeight,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(
              successIconOnly ? iconOnlySize / 2 : 14,
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
                  bannerWidth * 0.045,
                  bannerWidth * 0.03,
                  bannerWidth * 0.015,
                  bannerWidth * 0.03,
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
                    if (error && !success && !checking)
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: iconSize * 0.9,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: actionSize,
                          minHeight: actionSize,
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: c.check,
                      ),
                    if (error && !success && checking)
                      SizedBox(
                        width: iconSize * 0.9,
                        height: iconSize * 0.9,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
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
                      onPressed: success ? c.dismissSuccess : c.dismiss,
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