import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/common/components/custom_button.dart';
import 'package:gibud/common/components/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:gibud/common/widgets/appbar/appbar.dart';
import 'package:gibud/controllers/userDetailsController.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../utils/constants/country-codes.dart';
import '../../../utils/formatters/formatters.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  String selectedCountryCode = "+91";
  final controller = Get.put(Userdetailscontroller());
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            PrimaryHeaderContainer(
              color: Colors.redAccent,
              child: Column(
                children: [
                  CustomAppBar(
                    title: Text(
                      'Enter the Details Below',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),

            Form(
              key: controller.userDetailFormKey,
              child: Column(
                children: [
                  // First Name and Last Name Fields
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: const TextSelectionThemeData(
                                selectionHandleColor: Colors.redAccent, // 👈 Change this to your desired color
                              ),
                            ),
                            child: TextFormField(
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              cursorColor: Colors.black,
                              controller: controller.firstName,
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                labelStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade800,
                                ),
                                enabledBorder: _outlineInputBorder(),
                                focusedBorder: _outlineInputBorder(),
                                border: _outlineInputBorder(),
                              ),
                              keyboardType: TextInputType.name,
                              validator: (value) => InputValidators.validateFirstName(value),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16), // Spacing between the fields
                        Expanded(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: const TextSelectionThemeData(
                                selectionHandleColor: Colors.redAccent, // 👈 Change this to your desired color
                              ),
                            ),
                            child: TextFormField(
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              cursorColor: Colors.black,
                              controller: controller.lastName,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                labelStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade800,
                                ),
                                enabledBorder: _outlineInputBorder(),
                                focusedBorder: _outlineInputBorder(),
                                border: _outlineInputBorder(),
                              ),
                              keyboardType: TextInputType.name,
                              validator: (value) => InputValidators.validateLastName(value),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Age Field
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        textSelectionTheme: const TextSelectionThemeData(
                          selectionHandleColor: Colors.redAccent, // 👈 Change this to your desired color
                        ),
                      ),
                      child: TextFormField(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        cursorColor: Colors.black,
                        controller: controller.age,
                        decoration: InputDecoration(
                          labelText: 'Age',
                          labelStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade800,
                          ),
                          enabledBorder: _outlineInputBorder(),
                          focusedBorder: _outlineInputBorder(),
                          border: _outlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: ageValidator,
                      ),
                    ),
                  ),

                  // Height and Weight Fields
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: const TextSelectionThemeData(
                                selectionHandleColor: Colors.redAccent, // 👈 Change this to your desired color
                              ),
                            ),
                            child: TextFormField(
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              cursorColor: Colors.black,
                              controller: controller.height,
                              decoration: InputDecoration(
                                labelText: 'Height (cm)',
                                labelStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade800,
                                ),
                                enabledBorder: _outlineInputBorder(),
                                focusedBorder: _outlineInputBorder(),
                                border: _outlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: heightValidator,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16), // Spacing between the fields
                        Expanded(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: const TextSelectionThemeData(
                                selectionHandleColor: Colors.redAccent, // 👈 Change this to your desired color
                              ),
                            ),
                            child: TextFormField(
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              cursorColor: Colors.black,
                              controller: controller.weight,
                              decoration: InputDecoration(
                                labelText: 'Weight (kg)',
                                labelStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade800,
                                ),
                                enabledBorder: _outlineInputBorder(),
                                focusedBorder: _outlineInputBorder(),
                                border: _outlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: weightValidator,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  ///Role Section
                  _buildRoleSelection(),

                  /// Gender Dropdown
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DropdownButtonFormField<String>(
                      value: controller.gender.value.isNotEmpty ? controller.gender.value : null,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade800,
                        ),
                        enabledBorder: _outlineInputBorder(),
                        focusedBorder: _outlineInputBorder(),
                        border: _outlineInputBorder(),
                      ),
                      items: ['Male', 'Female', 'Other']
                          .map((value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: GoogleFonts.poppins()),
                      ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.gender.value = value;  // Directly update the RxString
                        }
                      },
                    ),
                  ),

                  SizedBox(height: 5,),

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
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: const TextSelectionThemeData(
                                selectionHandleColor: Colors.redAccent, // 👈 Change this to your desired color
                              ),
                            ),
                            child: TextFormField(
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              cursorColor: Colors.black,
                              controller: controller.phoneNumber,
                              decoration: InputDecoration(
                                floatingLabelStyle: TextStyle(color: Colors.black),
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
                              onChanged: (value) {
                                // Update the phone number in the controller
                                controller.combinedPhoneNumber = '$selectedCountryCode$value';
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 5,),
                  ///email field
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        textSelectionTheme: const TextSelectionThemeData(
                          selectionHandleColor: Colors.redAccent, // 👈 Change this to your desired color
                        ),
                      ),
                      child: TextFormField(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        cursorColor  : Colors.black,
                        controller: controller.email,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade800,
                          ),
                          enabledBorder: _outlineInputBorder(),
                          focusedBorder: _outlineInputBorder(),
                          border: _outlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => InputValidators.validateEmail(value),
                      ),
                    ),
                  ),


                  /// Password Field
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        textSelectionTheme: const TextSelectionThemeData(
                          selectionHandleColor: Colors.redAccent, // 👈 Change this to your desired color
                        ),
                      ),
                      child: TextFormField(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: controller.password,
                        cursorColor: Colors.black,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          floatingLabelStyle: TextStyle(color: Colors.black),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.black)
                          ),
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility : Icons.visibility_off,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            CustomButton(
              initialColor: Colors.redAccent, pressedColor: Colors.redAccent.shade100,
              buttonText: 'Submit Details',
              onTap: () {
                controller.sendDetails(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Text(
            'Specify Your Role:',
            style: GoogleFonts.poppins(
              fontSize: 14,
            ),
          ),
        ),
        Obx(
              () => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(
                        'User',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                        ),
                      ),
                      leading: Radio<String>(
                        activeColor: Colors.redAccent,
                        value: 'user',
                        groupValue: controller.selectedRole.value,
                        onChanged: (value) {
                          controller.selectedRole.value = value!;
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16), // Add spacing between the two containers
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(
                        'Dietician',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                        ),
                      ),
                      leading: Radio<String>(
                        activeColor: Colors.redAccent,
                        value: 'dietician',
                        groupValue: controller.selectedRole.value,
                        onChanged: (value) {
                          controller.selectedRole.value = value!;
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _outlineInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.black),
    );
  }
}
