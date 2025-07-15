import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../common/loader/animation_loader.dart';

class FullScreenLoader {
  static bool _isShowing = false;
  static VoidCallback? _onCancel;

  static void openLoadingDialog(String text, String animation, {VoidCallback? onCancel}) {
    if (_isShowing) return;

    _isShowing = true;
    _onCancel = onCancel;

    Get.dialog(
      WillPopScope(
        onWillPop: () async {
          _handleCancel(); // 👈 manually trigger cancel
          return false;
        },
        child: Material(
          color: Colors.white,
          child: Center(
            child: AnimationLoader(text: text, animation: animation),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void stopLoading() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
    _isShowing = false;
    _onCancel = null;
  }

  static void _handleCancel() {
    if (_onCancel != null) {
      _onCancel!(); // 👈 call the controller-defined cancel logic
    }
    stopLoading(); // 👈 ensures the dialog actually closes
  }
}
