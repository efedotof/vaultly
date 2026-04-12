import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/features/home/cubit/home_cubit.dart';
import 'package:vaulth_app/features/home/widget/content_widget.dart';

class OverlayLoading extends StatefulWidget {
  const OverlayLoading({
    super.key,
    required this.message,
    required this.scrollController,
  });
  final String message;
  final ScrollController scrollController;
  @override
  State<OverlayLoading> createState() => _OverlayLoadingState();
}

class _OverlayLoadingState extends State<OverlayLoading> {
  Future<void> _refresh() async {
    await context.read<HomeCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refresh,
          child: ContentWidget(
            folders: [],
            recentFiles: [],
            allFiles: [],
            scrollController: widget.scrollController,
          ),
        ),
        Container(
          color: Colors.black.withValues(alpha: 0.4),
          child: Center(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(widget.message),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
