import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/features/home/home.dart';
import 'package:vaulth_app/features/main_home/controller/main_home_controller.dart';
import 'package:vaulth_app/features/profile/profile.dart';
import 'package:vaulth_app/features/settings/settings.dart';

class MainHomeScreen extends StatelessWidget {
  MainHomeScreen({super.key});

  // Инициализируем контроллер
  final MainHomeController controller = Get.put(MainHomeController());

  // Список экранов
  final List<Widget> _screens = [
    const HomeScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => IndexedStack(index: controller.currentIndex, children: _screens),
      ),

      // Нижняя навигация
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: controller.currentIndex,
          onTap: (index) {
            controller.currentIndex = index; // Меняем индекс
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
           
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Настройки',
            ),
          ],
        ),
      ),
    );
  }
}
