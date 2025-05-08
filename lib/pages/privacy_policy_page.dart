import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:gibud/pages/signup/signup_page.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  "Privacy Policy",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Policy Content Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  """
1. Introduction

Welcome to GI BUD. We are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our health survey service. By using the App, you consent to the practices described in this policy.

2. Information We Collect

2.1 Personal Information
• Contact Information: Such as your name, email address, and phone number.
• Demographic Information: Such as your age, gender, and location.
• Health Information: Your health status, medical history, and responses to survey questions.

2.2 Usage Data
• Device Information: Your device’s type, operating system, and unique device identifiers.
• Log Data: Your IP address, browser type, access times, and pages viewed.

2.3 Cookies and Tracking Technologies
We may use cookies and similar tracking technologies to track the activity on our App and hold certain information.

3. How We Use Your Information
We use the information we collect for various purposes, including:
• To provide and maintain the App.
• To improve, personalise, and expand our App.
• To understand and analyse how you use our App.
• To develop new products, services, features, and functionality.
• To communicate with you, including sending you updates, security alerts, and support messages.
• To process your transactions and manage your orders.
• To conduct research and analysis, including health-related studies and surveys.
• To comply with legal obligations and protect our legal rights.

4. How We Share Your Information
We may share your information in the following circumstances:
• With Service Providers: We may share your information with third-party service providers who perform services on our behalf, such as data analysis, email delivery, and hosting services.
• For Legal Reasons: We may disclose your information if required to do so by law or in response to valid requests by public authorities (e.g., a court or a government agency).
• With Your Consent: We may share your information with other parties if you provide us with prior consent to do so.

5. Data Security
We implement appropriate technical and organizational measures to protect the security of your personal information. However, please note that no method of transmission over the Internet or method of electronic storage is 100% secure.

6. Your Data Protection Rights
Depending on your location, you may have the following rights regarding your personal information:
• Access: The right to access and receive a copy of your personal information.
• Rectification: The right to request corrections to any inaccurate or incomplete information.
• Erasure: The right to request the deletion of your personal information.
• Restriction: The right to request the restriction of the processing of your personal information.
• Objection: The right to object to our processing of your personal information.
• Data Portability: The right to request the transfer of your personal information to another organization.
To exercise these rights, please write to us at babycuepvtltd@gmail.com

7. Children’s Privacy
Our App is not intended for children under the age of 13. We do not knowingly collect personally identifiable information from children under 13. If you believe we have collected such information, please contact us immediately.

8. Changes to This Privacy Policy
We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the “Last Updated” date at the top. You are advised to review this Privacy Policy periodically for any changes.

9. Contact Us
If you have any questions about this Privacy Policy, please contact us:
Email: info@babycue.in
Address: 108-C KIIT TBI, Campus 11, KIIT University, Patia, Bhubaneswar, Odisha 751024

Thank you for using GI BUD. Your privacy and trust are important to us.
""",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
