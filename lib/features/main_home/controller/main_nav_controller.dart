import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainNavController extends GetxController {
  final isExpanded = true.obs;
  Timer? _autoCollapseTimer;
  bool _isScrollingUp = false;

  @override
  void onInit() {
    super.onInit();
    _startAutoCollapseTimer();
  }

  @override
  void onClose() {
    _autoCollapseTimer?.cancel();
    super.onClose();
  }

  void _startAutoCollapseTimer() {
    _autoCollapseTimer?.cancel();
    _autoCollapseTimer = Timer(const Duration(seconds: 2), () {
      if (isExpanded.value) {
        isExpanded.value = false;
      }
    });
  }

  void expandMenu() {
    if (isExpanded.value) return;
    isExpanded.value = true;
    _startAutoCollapseTimer();
  }

  void collapseMenu() {
    if (!isExpanded.value) return;
    isExpanded.value = false;
    _autoCollapseTimer?.cancel();
  }

  void handleScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _isScrollingUp = false;
    } else if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0.0;

      if (notification.metrics.pixels <= 0) {
        expandMenu();
        _isScrollingUp = false;
      } else if (delta < 0) {
        if (!_isScrollingUp) {
          expandMenu();
          _isScrollingUp = true;
        } else {
          collapseMenu();
        }
      } else if (delta > 0) {
        collapseMenu();
        _isScrollingUp = false;
      }
    } else if (notification is ScrollEndNotification) {
      _isScrollingUp = false;
      _startAutoCollapseTimer();
    }
  }
}
