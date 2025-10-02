import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/features/screens/food_swap/food_swap_image_upload_page.dart';
import 'package:gibud/features/screens/gut_test/gut_test_screen.dart';
import 'package:gibud/features/screens/home/home_page.dart';
import 'package:gibud/features/screens/shop/shop_section.dart';
import 'package:iconsax/iconsax.dart';

import 'features/personalization/profile/settings.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());

    // Different active colors for each tab
    final List<Color> activeColors = [
      Colors.blue,
      Colors.green,
      Colors.indigo,
      Colors.red,
    ];

    return Scaffold(
      bottomNavigationBar: Obx(
            () => NavigationBar(
          backgroundColor: Colors.white, // static white background
          height: 80,
          elevation: 0,
          selectedIndex: controller.selectedIndex.value,
          indicatorColor: Colors.transparent, // remove default indicator pill
          onDestinationSelected: (index) => controller.selectedIndex.value = index,
          destinations: [
            NavigationDestination(
              icon: controller.selectedIndex.value == 0
                  ? Icon(Icons.home, color: activeColors[0])
                  : const Icon(Icons.home_outlined, color: Colors.grey),
              label: "Home",
            ),
            NavigationDestination(
              icon: controller.selectedIndex.value == 1
                  ? Icon(Iconsax.activity5, color: activeColors[1])
                  : const Icon(Iconsax.activity, color: Colors.grey),
              label: "Gut Test",
            ),
            NavigationDestination(
              icon: controller.selectedIndex.value == 2
                  ? Icon(Icons.fastfood, color: activeColors[2])
                  : const Icon(Icons.fastfood_outlined, color: Colors.grey),
              label: "Food Swap",
            ),
            NavigationDestination(
              icon: controller.selectedIndex.value == 3
                  ? Icon(Iconsax.profile_2user5, color: activeColors[3])
                  : const Icon(Iconsax.profile_2user, color: Colors.grey),
              label: "Profile",
            ),
          ],
        ),
      ),
      body: Obx(
            () => controller.screens[controller.selectedIndex.value],
      ),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;
  final screens = [
    HomePage(),
    GutTestScreen(),
    FoodSwapImageUploadPage(),
    SettingsScreen(),
  ];
}
