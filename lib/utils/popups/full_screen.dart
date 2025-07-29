import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../common/loader/animation_loader.dart';

class FullScreenLoader {
  static bool _isShowing = false;
  static VoidCallback? _onCancel;

  static final List<String> _factImages = List.generate(
    9,
        (index) => 'assets/images/loader_facts/fact_${index + 1}.png',
  );

  static void openLoadingDialog(String text, String animation,
      {VoidCallback? onCancel}) {
    if (_isShowing) return;

    _isShowing = true;
    _onCancel = onCancel;

    final randomFactImage = (_factImages..shuffle()).first;

    Get.dialog(
      WillPopScope(
        onWillPop: () async {
          _handleCancel();
          return false;
        },
        child: Material(
          color: Colors.white,
          child: Center(
            child: AnimationLoader(
              text: text,
              animation: animation,
              infoImagePath: randomFactImage,
            ),
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
    _onCancel?.call();
    stopLoading();
  }
}

