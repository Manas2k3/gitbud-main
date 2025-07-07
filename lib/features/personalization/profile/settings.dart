import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:gibud/common/components/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:gibud/common/widgets/appbar/appbar.dart';
import 'package:gibud/data/repositories/authentication/authentication_repository.dart';
import 'package:gibud/survey/survey_report.dart';
import 'package:gibud/utils/popups/loaders.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../common/widgets/list_tiles/custom_user_profile_tille.dart';
import '../../../common/widgets/list_tiles/settings_menu_tile.dart';
import '../../../pages/privacy_policy_page.dart';
import '../../../survey/recent_reports.dart';
import 'edit_profile_page.dart';

class SettingsScreen extends StatelessWidget {
  final _auth = FirebaseAuth.instance;
  SettingsScreen({super.key});

  Future<Map<String, dynamic>> _getUserData() async {
    // Assuming you have the user ID from the authentication repository
    String userId = _auth.currentUser?.uid ?? ''; // Fetch user ID

    // Retrieve user data from Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();

    // Return the user data as a map
    return userDoc.data() as Map<String, dynamic>;
  }



  void rateUs() async {
    const String appId = "com.mosaif.gibud";
    final url = Uri.parse('https://play.google.com/store/apps/details?id=$appId');

    if(await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }else {
      Loaders.errorSnackBar(title: 'OOPs', message: 'Failed to Launch the App');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ///Header
            PrimaryHeaderContainer(
              color: Colors.redAccent,
              child: Column(
                children: [
                  CustomAppBar(
                    title: Row(
                      children: [
                        Text(
                          "Account",
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade200,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Spacer(),
                        // IconButton(
                        //   icon: Icon(Icons.edit, color: Colors.white),
                        //   onPressed: () {
                        //     // Navigate to EditProfilePage
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //         builder: (context) => EditProfilePage(),
                        //       ),
                        //     );
                        //   },
                        // ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _getUserData(), // Call the async function to get user data
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator(color: Colors.white,); // Loading state
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}'); // Error handling
                        } else if (snapshot.hasData) {
                          final userData = snapshot.data!;
                          final name = '${userData['name']}'; // Combine names
                          final email = userData['email'] ?? 'User'; // Get email
                          return CustomProfileTileWidget(
                            name: name, // Pass the full name
                            email: email, // Pass the email
                          );
                        } else {
                          return Text('No data found'); // No data fallback
                        }
                      },
                    ),
                  ),

                  const SizedBox(
                    height: 32,
                  ),
                ],
              ),
            ),

            ///Body
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Account Settings",
                        style: GoogleFonts.poppins(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 20
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 16,),
                  SettingsMenuTile(icon: Iconsax.graph, title: 'Reports', subTitle: 'Checkout your recent reports', onTap: () { final userId = FirebaseAuth.instance.currentUser?.uid; // Retrieve the current user ID
                  if (userId != null) {
                    Get.to(RecentReportsPage(userId: userId)); // Pass the userId to SurveyReport
                  } else {
                    // Handle case where user is not logged in or userId is null
                    print('User not logged in');
                  }},),
                  SizedBox(height: 16,),
                  SettingsMenuTile(icon: Iconsax.document, title: 'Privacy & Policy', subTitle: 'Review our Privacy and Policy terms at your convenience.', onTap: () => Get.to(PrivacyPolicyPage()),),
                  SizedBox(height: 16,),
                  SettingsMenuTile(icon: Iconsax.star, title: 'Rate Us', subTitle: 'Please take a moment to rate us; your feedback helps us improve.', onTap: rateUs),
                  SizedBox(height: 16,),
                  SettingsMenuTile(icon: Iconsax.logout, title: 'Logout', subTitle: '', onTap: AuthenticationRepository.instance.logOut,),
                ],
              ),
            )

          ],
        ),
      ),
    );
  }
}
