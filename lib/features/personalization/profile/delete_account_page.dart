import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/pages/signup/signup_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _auth = FirebaseAuth.instance;
  bool _confirmed = false;
  bool _deleting = false;
  String _error = '';

  Future<void> _deleteAccount() async {
    if (_deleting) return;
    setState(() {
      _deleting = true;
      _error = '';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user.');
      final providers = user.providerData.map((e) => e.providerId).toList();

      // 1) Re-auth
      if (providers.contains('password')) {
        final password = await _askPassword(user.email!);
        if (password == null) {
          setState(() => _error = 'Account deletion cancelled.');
          setState(() => _deleting = false);
          return;
        }
        final cred =
        EmailAuthProvider.credential(email: user.email!, password: password);
        await user.reauthenticateWithCredential(cred);
      } else if (providers.contains('google.com')) {
        await _showReauthInfo();
        setState(() {
          _error = 'Please log out and sign in again, then retry deletion.';
          _deleting = false;
        });
        return;
      }

      final uid = user.uid;

      // 2) Delete Firestore
      await _deleteFirestoreUserData(uid);

      // 3) Delete Storage
      await _deleteAllFilesInStoragePath('users/$uid');

      // 4) Delete user from Auth
      await user.delete();

      // 5) Sign out + Success screen
      await _auth.signOut();
      if (mounted) Get.offAll(() => _DeletedSuccessScreen());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        setState(() => _error =
        'You need to sign in again before deleting your account.');
      } else {
        setState(() => _error = e.message ?? e.code);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _deleteFirestoreUserData(String uid) async {
    final db = FirebaseFirestore.instance;
    final userRef = db.collection('Users').doc(uid);

    // subcollections you want to wipe
    const subcollections = ['Reports', 'Notifications', 'Sessions'];

    for (final sub in subcollections) {
      final snap = await userRef.collection(sub).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }

    await userRef.delete();
  }

  Future<void> _deleteAllFilesInStoragePath(String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    try {
      final listResult = await ref.listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
      for (final prefix in listResult.prefixes) {
        await _deleteAllFilesInStoragePath(prefix.fullPath);
      }
    } catch (_) {
      // ignore if not found
    }
  }

  Future<String?> _askPassword(String email) async {
    final controller = TextEditingController();
    bool obscure = true;

    return await Get.dialog<String?>(
      AlertDialog(
        title: Text("Confirm password"),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter your password for $email"),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: null), child: Text("Cancel")),
          TextButton(
              onPressed: () => Get.back(result: controller.text.trim()),
              child: Text("Confirm", style: TextStyle(color: Colors.red))),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _showReauthInfo() async {
    await Get.dialog(
      AlertDialog(
        title: Text("Re-login required"),
        content: Text(
            "Your account is linked with Google/Apple/etc. Please log out and sign in again before retrying deletion."),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final red = Colors.redAccent;
    final light = Colors.white;

    return Scaffold(
      backgroundColor: light,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: light,
        centerTitle: true,
        title: Text('Delete Account',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          // Red header wave
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [red, red.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
          ),

          // Glass card
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16 + 120, 16, 24),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: red.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: red.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Iconsax.warning_2,
                            color: Colors.redAccent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This will permanently delete your account',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Before you proceed, please review the consequences:',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _point('All your profile data and settings will be removed.'),
                  _point(
                      'All survey reports and history will be permanently deleted.'),
                  _point('Any uploaded images/files will be erased.'),
                  _point('This action cannot be undone.'),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _confirmed,
                        onChanged: (v) =>
                            setState(() => _confirmed = v ?? false),
                        activeColor: red,
                      ),
                      Expanded(
                        child: Text(
                          'I understand the consequences and want to permanently delete my account.',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_error,
                          style: GoogleFonts.poppins(
                              color: red, fontSize: 12)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                          (!_confirmed || _deleting) ? null : _deleteAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: red,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Iconsax.trash, color: Colors.white),
                          label: _deleting
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                              : Text('Delete my account',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _deleting ? null : () => Get.back(),
                    icon: const Icon(Iconsax.arrow_left_2, color: Colors.black),
                    label: Text('Go back',
                        style: GoogleFonts.poppins(color: Colors.black)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _point(String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(width: 8),
      Expanded(
        child: Text(text,
            style: GoogleFonts.poppins(
                fontSize: 13.2, color: Colors.black87, height: 1.35)),
      ),
    ],
  );
}

class _DeletedSuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withOpacity(0.08),
                ),
                child: const Icon(Iconsax.verify,
                    size: 40, color: Colors.redAccent),
              ),
              const SizedBox(height: 14),
              Text('Account deleted',
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'We\'re sorry to see you go. Your account and data have been removed.',
                textAlign: TextAlign.center,
                style:
                GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                ),
                onPressed: () {
                  Get.offAll(() => const SignupPage());
                },
                child: Text('Continue',
                    style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
