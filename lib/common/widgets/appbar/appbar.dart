import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Importing GetX
import 'package:gibud/navigation_menu.dart';
import 'package:iconsax/iconsax.dart'; // Importing Iconsax for icons

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    Key? key,
    this.title,
    this.leadingIcon,
    this.actions,
    this.leadingOnPressed,
    this.showBackArrow = false,
    this.backgroundColor = Colors.transparent, // Added background color
    this.elevation = 0.0, // Optional elevation
  }) : super(key: key);

  final Widget? title;
  final bool showBackArrow;
  final IconData? leadingIcon;
  final List<Widget>? actions;
  final VoidCallback? leadingOnPressed;
  final Color backgroundColor; // Optional background color
  final double elevation; // Optional elevation

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16), // Standard padding
      child: AppBar(
        backgroundColor: backgroundColor, // Customizable background color
        automaticallyImplyLeading: false,
        elevation: elevation, // Customizable elevation
        leading: showBackArrow
            ? IconButton(
          color: Colors.white,
          onPressed: () => Get.back(), // Using Get.back() for navigation
          icon: const Icon(Iconsax.arrow_left),
        )
            : leadingIcon != null
            ? IconButton(
          onPressed: leadingOnPressed, // Handle leading icon action
          icon: Icon(leadingIcon, color: Colors.white,),
        )
            : null, // Show leadingIcon if provided
        title: title,
        actions: actions, // Support for custom actions
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight); // Standard AppBar height
}
