import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/pages/signup/signup_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // TODO: change to your live web URL used in Play Console Data safety form
  static const String kAccountDeletionWebUrl = 'https://babycue.in/delete-account';

  Future<void> _openWebDeletion() async {
    final url = Uri.parse(kAccountDeletionWebUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _deleteAllUserStorage(Reference ref) async {
    // Recursively delete all files/folders under a reference
    final listResult = await ref.listAll();
    for (final fileRef in listResult.items) {
      await fileRef.delete();
    }
    for (final prefix in listResult.prefixes) {
      await _deleteAllUserStorage(prefix);
    }
  }

  Future<void> _deleteFirestoreUserData(String uid) async {
    final db = FirebaseFirestore.instance;

    // Delete root user doc
    final userRef = db.collection('Users').doc(uid);

    // Example: delete known subcollections safely if you have them
    // (Adjust to your schema)
    final subcollections = <String>[
      'Reports',        // if you store survey results here
      'Notifications',  // example
      'Sessions',       // example
    ];

    // Best effort: if subcollection doesn't exist, loop will do nothing.
    for (final sub in subcollections) {
      final colRef = userRef.collection(sub);
      final snap = await colRef.get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }

    // Finally delete the root document
    await userRef.delete();
  }

  Future<void> _reauthIfRequired(User user) async {
    // Firebase requires recent login for sensitive ops like delete().
    // If delete() throws requires-recent-login, we’ll prompt for password (email+password case).
    try {
      await user.reload(); // noop-ish, but keeps session fresh sometimes
    } catch (_) {}
  }

  Future<void> _deleteAccount() async {
    if (_deleting) return;

    setState(() {
      _deleting = true;
      _error = '';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user.');
      }
      final uid = user.uid;

      await _reauthIfRequired(user);

      // 1) Delete Storage folder(s) for this user (best-effort)
      try {
        final storageRoot = FirebaseStorage.instance.ref().child('users').child(uid);
        await _deleteAllUserStorage(storageRoot);
      } catch (_) {
        // swallow storage errors; continue with best-effort
      }

      // 2) Delete Firestore user data
      await _deleteFirestoreUserData(uid);

      // 3) Delete Firebase Auth user
      await user.delete();

      // 4) Bounce to a neutral screen
      if (mounted) {
        Get.offAll(() => _DeletedSuccessScreen());
      }
    } on FirebaseAuthException catch (e) {
      // Re-auth flow for requires-recent-login
      if (e.code == 'requires-recent-login') {
        await _handleReauthAndRetry();
        return;
      }
      setState(() => _error = e.message ?? e.code);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _handleReauthAndRetry() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // If user signed up with email/password, ask for password.
    final email = user.email;
    if (email != null && email.isNotEmpty) {
      final pwd = await _askPassword(email);
      if (pwd == null) {
        setState(() => _error = 'Re-authentication cancelled.');
        return;
      }
      try {
        final cred = EmailAuthProvider.credential(email: email, password: pwd);
        await user.reauthenticateWithCredential(cred);
        // Try delete again
        await _deleteAccount();
        return;
      } on FirebaseAuthException catch (e) {
        setState(() => _error = e.message ?? e.code);
        return;
      }
    }

    // For Google/Apple/etc., tell them to re-login
    await _showReauthInfo();
    setState(() {
      _error = 'Please re-login and try again.';
    });
  }

  Future<String?> _askPassword(String email) async {
    final controller = TextEditingController();
    return await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.lock, size: 40, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text('Re-authentication required',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Enter your password for $email to continue.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: Text('Cancel', style: GoogleFonts.poppins()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () => Navigator.pop(context, controller.text.trim()),
                        child: Text('Confirm', style: GoogleFonts.poppins(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showReauthInfo() async {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Iconsax.info_circle, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text('Re-login required',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'For accounts created with Google/Apple/etc., please log out and sign in again, then retry deletion.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(context),
              child: Text('Got it', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ]),
        ),
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
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          // Top red header wave
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

          // Content card
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16 + 120, 16, 24),
            child: Column(
              children: [
                // Glass card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.15),
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
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Iconsax.warning_2, color: Colors.redAccent),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This will permanently delete your account',
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Before you proceed, please review the consequences:',
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _point('All your profile data and settings will be removed.'),
                      _point('All survey reports and history will be permanently deleted.'),
                      _point('Any uploaded images/files will be erased from storage.'),
                      _point('This action cannot be undone.'),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _confirmed,
                            onChanged: (v) => setState(() => _confirmed = v ?? false),
                            activeColor: Colors.redAccent,
                          ),
                          Expanded(
                            child: Text(
                              'I understand the consequences and want to permanently delete my account.',
                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
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
                            color: Colors.redAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error,
                            style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: (!_confirmed || _deleting) ? null : _deleteAccount,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                              ),
                              icon: const Icon(Iconsax.trash, color: Colors.white),
                              label: _deleting
                                  ? SizedBox(
                                height: 18, width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white,
                                ),
                              )
                                  : Text('Delete my account',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _deleting ? null : () => Get.back(),
                        icon: const Icon(Iconsax.arrow_left_2, color: Colors.black,),
                        label: Text('Go back', style: GoogleFonts.poppins(color: Colors.black)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _point(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 13.2, color: Colors.black87, height: 1.35),
          ),
        ),
      ],
    );
  }
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
                child: const Icon(Iconsax.verify, size: 40, color: Colors.redAccent),
              ),
              const SizedBox(height: 14),
              Text('Account deleted',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'We\'re sorry to see you go. Your account and data have been removed.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                ),
                onPressed: () {
                  // Send to your welcome/login screen
                  Get.offAll(SignupPage()); // <-- adjust route
                },
                child: Text('Continue', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
