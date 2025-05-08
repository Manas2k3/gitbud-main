import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsMenuTile extends StatelessWidget {
  const SettingsMenuTile({super.key, required this.icon, required this.title, this.subTitle, this.onTap});

  final IconData icon;
  final String title;
  final String? subTitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 28, color: Colors.grey.shade800,),
        title: Text(title, style: GoogleFonts.poppins(color: Colors.grey.shade800, fontWeight: FontWeight.w600),),
        subtitle: Text(subTitle!, style: GoogleFonts.poppins(color: Colors.grey.shade800),),
        onTap: onTap,
    );
  }
}
