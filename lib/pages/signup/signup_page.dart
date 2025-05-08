import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/controllers/phone_auth_controller.dart';
import 'package:gibud/pages/login/login_page.dart';
import 'package:gibud/pages/signup/widgets/email-auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/components/custom_button.dart';
import '../../common/components/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../common/widgets/appbar/appbar.dart';
import '../../utils/constants/country-codes.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool isChecked = false;
  bool _obscureText = true;

  final controller = Get.put(PhoneAuthController());
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String selectedCountryCode = '+91'; // Default to India

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                /// Header Section
                PrimaryHeaderContainer(
                  color: Colors.redAccent,
                  child: Column(
                    children: [
                      CustomAppBar(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Hello!',
                              style: GoogleFonts.poppins(
                                fontSize: 35,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Welcome to GiBud!',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 25),
                    ],
                  ),
                ),

                /// Form Section
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Form(
                    key: controller.phoneAuthFormKey,
                    child: Column(
                      children: [
                        /// Country Code Dropdown with Phone Input
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              /// Country Code Dropdown
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedCountryCode,
                                    icon: Icon(Icons.arrow_drop_down),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedCountryCode = newValue!;
                                      });
                                    },
                                    items: CountryCodes.countryList
                                        .map<DropdownMenuItem<String>>((Map<String, String> country) {
                                      return DropdownMenuItem<String>(
                                        value: country['code'],
                                        child: Row(
                                          children: [
                                            Text(
                                              country['flag']!,
                                              style: TextStyle(fontSize: 20),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              country['shortForm']!,
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              country['code']!,
                                              style: GoogleFonts.poppins(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),

                              SizedBox(width: 10),

                              /// Phone Number Input Field
                              Expanded(
                                child: TextFormField(
                                  cursorColor: Colors.black,
                                  controller: controller.phoneNumber,
                                  decoration: InputDecoration(
                                    floatingLabelStyle:
                                    TextStyle(color: Colors.black),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(color: Colors.black),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(color: Colors.blue),
                                    ),
                                    labelText: 'Phone Number',
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Phone Number is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// Submit Button
                        SizedBox(height: 40),
                        CustomButton(
                          onTap: () async {
                            if (controller.phoneAuthFormKey.currentState?.validate() ?? false) {
                              await controller.handlePhoneAuth(
                                context,
                                controller.phoneNumber.text.trim(),
                                selectedCountryCode,
                              );
                            }
                          },
                          buttonText: 'Continue', initialColor: Colors.redAccent, pressedColor: Colors.redAccent.shade100, 
                        ),

                        SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                        
                        Row(mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Already Have an Account", style: GoogleFonts.poppins(fontSize: 15),),
                            TextButton(onPressed: () => Get.to(LoginPage()), child:Text("Login",style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),))
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
