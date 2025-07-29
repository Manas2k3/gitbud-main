import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:gibud/common/components/custom_button.dart';
import 'package:gibud/common/components/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:gibud/common/widgets/appbar/appbar.dart';
import 'package:gibud/controllers/phone_auth_controller.dart';
import 'package:gibud/utils/constants/image_strings.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpPage extends StatefulWidget {
  final bool isSignup;

  const OtpPage({super.key, required this.isSignup});

  @override
  _OtpPageState createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> with CodeAutoFill {
  final PhoneAuthController controller = Get.find<PhoneAuthController>();
  final otpControllers = List.generate(6, (index) => TextEditingController());

  @override
  void initState() {
    super.initState();
    listenForCode();
  }

  @override
  void codeUpdated() {
    if (code != null && code!.length == 6) {
      for (int i = 0; i < code!.length; i++) {
        otpControllers[i].text = code![i];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildOtpImage(),
            const SizedBox(height: 20),
            _buildOtpInputs(context),
            const SizedBox(height: 20),
            _buildSubmitButton(context),
            const SizedBox(height: 10),
            _buildResendOtpButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return PrimaryHeaderContainer(
      color: Colors.redAccent,
      child: Column(
        children: [
          CustomAppBar(
            title: Text(
              widget.isSignup ? "Verify your OTP" : "Welcome Back!",
              style: GoogleFonts.poppins(
                color: Colors.grey.shade200,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _buildOtpImage() {
    return Image.asset(
      ImageStrings.otpPageImage,
      height: 250,
      fit: BoxFit.contain,
    );
  }

  Widget _buildOtpInputs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (index) => _buildOtpBox(context, index)),
      ),
    );
  }

  Widget _buildOtpBox(BuildContext context, int index) {
    return SizedBox(
      width: 45,
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: const TextSelectionThemeData(
            selectionHandleColor: Colors.redAccent, // 👈 Change this to your desired color
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric( horizontal: 1),
          child: TextFormField(
            cursorColor: Colors.black,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            controller: otpControllers[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              counterText: "",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue),
              ),
            ),
            maxLength: 1,
            onChanged: (value) {
              if (value.length == 1 && index < otpControllers.length - 1) {
                FocusScope.of(context).nextFocus();
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).previousFocus();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: CustomButton(
        initialColor: Colors.redAccent,
        pressedColor: Colors.redAccent.shade100,
        buttonText: 'Submit',
        onTap: () async {
          String enteredOtp =
          otpControllers.map((controller) => controller.text).join();
          if (enteredOtp.length != 6) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please enter a valid 6-digit OTP")),
            );
            return;
          }
          await controller.verifyOtp(context, enteredOtp);
        },
      ),
    );
  }

  Widget _buildResendOtpButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextButton(
        onPressed: () {
          controller.sendOtpSms(context as String, controller.phoneNumber.text.trim());
        },
        child: Text(
          "Resend OTP",
          style: GoogleFonts.poppins(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    SmsAutoFill().unregisterListener();
    super.dispose();
  }
}
