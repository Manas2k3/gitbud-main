import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../pages/privacy_policy_page.dart';
import '../../../survey/recent_reports.dart';
import '../../../utils/popups/loaders.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String kDefaultAvatarUrl =
      'https://i.pinimg.com/474x/e6/e4/df/e6e4df26ba752161b9fc6a17321fa286.jpg';


  String? _appVersion;
  final _auth = FirebaseAuth.instance;
  File? _localProfileImage; // only for temporary preview while uploading
  String? _photoUrl; // override URL after upload/remove without waiting FB
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _ensureDefaultPhotoUrl();
    PackageInfo.fromPlatform().then((info) {
      setState(() {
        _appVersion = "v${info.version} (${info.buildNumber})";
      });
    });

  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.warning_2, color: Colors.redAccent, size: 40),
                const SizedBox(height: 16),
                Text(
                  "Log out?",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Are you sure you want to log out of your account?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text("Cancel",
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                            )),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          AuthenticationRepository.instance.logOut();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text("Log Out",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                            )),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _ensureDefaultPhotoUrl() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance.collection('Users').doc(uid);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return;

    if (data['photoUrl'] == null || (data['photoUrl'] as String).isEmpty) {
      await ref.update({'photoUrl': kDefaultAvatarUrl});
      setState(() => _photoUrl = kDefaultAvatarUrl);
    } else {
      setState(() => _photoUrl = data['photoUrl']);
    }
  }

  Future<Map<String, dynamic>> _getUserData() async {
    final userId = _auth.currentUser?.uid ?? '';
    final userDoc =
    await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  void rateUs() async {
    const String appId = "com.mosaif.gibud";
    final url =
    Uri.parse('https://play.google.com/store/apps/details?id=$appId');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Loaders.errorSnackBar(
          title: 'Oops', message: 'Failed to launch the Play Store');
    }
  }

  Future<void> _uploadAndSaveProfileImage(File file) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      setState(() {
        _isUploading = true;
        _localProfileImage = file;
      });

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('avatar.jpg');

      await storageRef.putFile(file);
      final url = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .update({'photoUrl': url});

      setState(() {
        _photoUrl = url;
        _localProfileImage = null;
      });
    } catch (e) {
      Loaders.errorSnackBar(title: 'Upload failed', message: e.toString());
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _removeProfileImage() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      setState(() => _isUploading = true);
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .update({'photoUrl': kDefaultAvatarUrl});
      setState(() {
        _photoUrl = kDefaultAvatarUrl;
        _localProfileImage = null;
      });
    } catch (e) {
      Loaders.errorSnackBar(title: 'Failed', message: e.toString());
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // ---- Avatar picker bottom sheet ----
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Iconsax.gallery),
                  title: const Text("Choose from Gallery"),
                  onTap: () async {
                    Navigator.pop(context);
                    final picked = await ImagePicker()
                        .pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      await _uploadAndSaveProfileImage(File(picked.path));
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Iconsax.camera),
                  title: const Text("Take a Photo"),
                  onTap: () async {
                    Navigator.pop(context);
                    final picked = await ImagePicker()
                        .pickImage(source: ImageSource.camera);
                    if (picked != null) {
                      await _uploadAndSaveProfileImage(File(picked.path));
                    }
                  },
                ),
                if ((_photoUrl != null && _photoUrl != kDefaultAvatarUrl) ||
                    _localProfileImage != null)
                  ListTile(
                    leading: const Icon(Iconsax.trash),
                    title: const Text("Remove Picture"),
                    onTap: () async {
                      Navigator.pop(context);
                      await _removeProfileImage();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- Avatar widget ----
  Widget _buildProfileAvatar(String effectivePhotoUrl) {
    final imageProvider = _localProfileImage != null
        ? FileImage(_localProfileImage!)
        : NetworkImage(effectivePhotoUrl) as ImageProvider;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade400,
          backgroundImage: imageProvider,
        ),
        if (_isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,),
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 4,
          child: InkWell(
            onTap: _isUploading ? null : _showImagePickerOptions,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.edit_2,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Shimmer loader aligned with real content ----
  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 20,
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 14,
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Align(
            alignment: Alignment.centerLeft,
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 16,
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingShimmer();
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading data 💥", style: GoogleFonts.poppins()),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text("No user data found 🫠", style: GoogleFonts.poppins()),
            );
          }

          final data = snapshot.data!;
          final name = data['name'] ?? 'Unnamed';
          final email = data['email'] ?? 'Email missing';
          final effectivePhotoUrl =
              _photoUrl ?? data['photoUrl'] ?? kDefaultAvatarUrl;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Avatar (editable, network default)
                _buildProfileAvatar(effectivePhotoUrl),

                const SizedBox(height: 16),

                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 15),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Account Settings",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                _buildSettingTile(
                  icon: Iconsax.document,
                  title: 'Reports',
                  subtitle: 'View your past survey results',
                  onTap: () {
                    final userId = _auth.currentUser?.uid;
                    if (userId != null) {
                      Get.to(() => RecentReportsPage(userId: userId));
                    }
                  },
                ),
                const SizedBox(height: 16),

                _buildSettingTile(
                  icon: Iconsax.shield_tick,
                  title: 'Privacy',
                  subtitle: 'Manage your data and preferences',
                  onTap: () => Get.to(() => PrivacyPolicyPage()),
                ),
                const SizedBox(height: 16),

                _buildSettingTile(
                  icon: Iconsax.star,
                  title: 'Rate Us',
                  subtitle: 'Share your feedback',
                  onTap: rateUs,
                ),
                const SizedBox(height: 16),

                _buildSettingTile(
                  icon: Iconsax.logout,
                  title: 'Logout',
                  subtitle: '',
                  onTap: () => _showLogoutConfirmationDialog(context),
                ),
                const SizedBox(height: 20),
                if (_appVersion != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "App Version: $_appVersion",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
