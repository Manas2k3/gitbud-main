import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomProfileTileWidget extends StatelessWidget {
  final String name; // Single parameter for name
  final String email; // Parameter for email

  const CustomProfileTileWidget({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.person,
        color: Colors.white,
        size: 40,
      ),
      title: Text(
        name, // Display name directly
        style: GoogleFonts.poppins(
            color: Colors.grey.shade200,
            fontWeight: FontWeight.w600,
            fontSize: 20),
      ),
      subtitle: Text(
        email, // Display email directly
        style: GoogleFonts.poppins(
            color: Colors.grey.shade200,
            fontWeight: FontWeight.w500),
      ),
    );
  }
}
