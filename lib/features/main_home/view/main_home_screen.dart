import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:vaulth_app/features/main_home/widget/widget.dart';
import 'package:vaulth_app/route/app_router.dart';

@RoutePage()
class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter.builder(
      routes: const [HomeRoute(), ProfileRoute(), SettingsRoute()],
      builder: (context, children, tabsRouter) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.03, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(tabsRouter.activeIndex),
                  child: children[tabsRouter.activeIndex],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: FloatingBottomNavBar(
                  currentIndex: tabsRouter.activeIndex,
                  onTap: (index) => tabsRouter.setActiveIndex(index),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
