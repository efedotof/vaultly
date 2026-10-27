import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/features/home/home.dart';
import 'package:vaulth_app/features/main_home/controller/main_home_controller.dart';
import 'package:vaulth_app/features/main_home/controller/main_nav_controller.dart';
import 'package:vaulth_app/features/main_home/widget/my_nav_button.dart';
import 'package:vaulth_app/features/profile/controller/profile_controller.dart';
import 'package:vaulth_app/features/settings/settings.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen>
    with SingleTickerProviderStateMixin {
  static const _navBg = Color(0xFF43416d);
  static const _navHeight = 44.0;
  static const _avatarSize = 36.0;
  static const _buttonsWidth = 88.0;
  static const _padding = 4.0;

  static const _collapsedWidth = _avatarSize + (_padding * 2);

  late final MainHomeController homeController;
  late final ProfileController profileController;
  late final MainNavController navController;

  late final AnimationController _animController;
  late final Animation<double> _animation;

  final List<Widget> _screens = const [HomeScreen(), SettingsScreen()];

  @override
  void initState() {
    super.initState();

    if (!Get.isRegistered<MainHomeController>()) {
      Get.put(MainHomeController());
    }
    homeController = Get.find<MainHomeController>();

    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController(), permanent: true);
    }
    profileController = Get.find<ProfileController>();

    if (!Get.isRegistered<MainNavController>()) {
      Get.put(MainNavController());
    }
    navController = Get.find<MainNavController>();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.fastOutSlowIn,
    );

    ever(navController.isExpanded, (expanded) {
      if (expanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });

    if (navController.isExpanded.value) {
      _animController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onAvatarTap() {
    if (navController.isExpanded.value) {
      navController.collapseMenu();
      Get.toNamed('/profile/my_profile');
    } else {
      navController.expandMenu();
    }
  }

  void _onNavTap(int index) {
    homeController.currentIndex = index;
    navController.collapseMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          navController.handleScroll(notification);
          return false;
        },
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Obx(
                () => IndexedStack(
                  index: homeController.currentIndex,
                  children: _screens,
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: AnimatedBuilder(
                animation: _animation,
                child: GestureDetector(
                  onTap: _onAvatarTap,
                  child: Container(
                    width: _avatarSize,
                    height: _avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                      border: Border.all(
                        color: Colors.white.withAlpha(5),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Obx(() {
                        final avatarUrl = profileController.avatarUrl;
                        return avatarUrl.isNotEmpty
                            ? Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.person,
                                  size: 22,
                                  color: _navBg,
                                ),
                              )
                            : const Icon(Icons.person, size: 22, color: _navBg);
                      }),
                    ),
                  ),
                ),
                builder: (context, child) {
                  final t = _animation.value;
                  final currentWidth = _collapsedWidth + (_buttonsWidth * t);

                  return Container(
                    width: currentWidth,
                    height: _navHeight,
                    padding: const EdgeInsets.all(_padding),
                    decoration: BoxDecoration(
                      color: _navBg,
                      borderRadius: BorderRadius.circular(_navHeight / 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRect(
                          child: Align(
                            alignment: Alignment.centerRight,
                            widthFactor: t,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MyNavButton(
                                  icon: Icons.home,
                                  selected: homeController.currentIndex == 0,
                                  onTap: () => _onNavTap(0),
                                ),
                                MyNavButton(
                                  icon: Icons.settings,
                                  selected: homeController.currentIndex == 1,
                                  onTap: () => _onNavTap(1),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                        child!,
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
