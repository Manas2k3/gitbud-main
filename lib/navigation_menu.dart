import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/features/screens/Scanner/camera.dart';
import 'package:gibud/features/screens/gut_test/gut_test_screen.dart';
import 'package:gibud/features/screens/home/home_page.dart';
import 'package:gibud/features/screens/kids/kids_section.dart';
import 'package:gibud/features/screens/shop/shop_section.dart';
import 'package:iconsax/iconsax.dart';

import 'features/personalization/profile/settings.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());

    // Define colors for each page
    final List<Color> navigationColors = [
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.purple.shade100,
      Colors.indigo.shade100,
      Colors.orange.shade100,
      Colors.red.shade100
    ];

    // Define colors without shade for border and active item color
    final List<Color> baseColors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.indigo,
      Colors.orange,
      Colors.red
    ];

    return Scaffold(
      bottomNavigationBar: Obx(
            () => Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: baseColors[controller.selectedIndex.value],
                width: 0.5, // Adjust the width as needed
              ),
            ),
          ),
          child: NavigationBar(
            backgroundColor: navigationColors[controller.selectedIndex.value],
            height: 80,
            elevation: 0,
            selectedIndex: controller.selectedIndex.value,
            indicatorColor: baseColors[controller.selectedIndex.value], // Active color
            onDestinationSelected: (index) => controller.selectedIndex.value = index,
            destinations: [
              NavigationDestination(icon: Icon(Iconsax.home), label: "Home"),
              NavigationDestination(icon: Icon(Iconsax.activity), label: "Gut Test"),
              NavigationDestination(icon: Icon(Iconsax.scan), label: "Scanner"),
              NavigationDestination(icon: Icon(Iconsax.shop), label: "Shop"),
              NavigationDestination(icon: Icon(Icons.child_care), label: "Kids"),
              NavigationDestination(icon: Icon(Iconsax.profile_2user), label: "Profile"),
            ],
          ),
        ),
      ),
      body: Obx(
            () => Container(
          color: navigationColors[controller.selectedIndex.value],
          child: controller.screens[controller.selectedIndex.value],
        ),
      ),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;
  final screens = [
    HomePage(),
    GutTestScreen(),
    Camera(),
    ShopSection(),
    KidsSection(),
    SettingsScreen()
  ];
}
