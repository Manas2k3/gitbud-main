import 'package:flutter/material.dart';

class User {
  String email;
  String name;
  String phone;
  int age;
  double weight;
  double height;
  String gender;
  bool gutTestPaymentStatus;
  DateTime createdAt;

  // Constructor
  User({
    required this.email,
    required this.name,
    required this.phone,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.gutTestPaymentStatus,
    required this.createdAt,
  });

  // Method to display user details
  void displayUserInfo() {
    print('Name: $name');
    print('Email: $email');
    print('Phone: $phone');
    print('Age: $age');
    print('Weight: $weight kg');
    print('Height: $height m');
    print('Gender: $gender');
    print('Gut Test Payment Status: ${gutTestPaymentStatus ? "Paid" : "Not Paid"}');
    print('Created At: $createdAt');
  }
}
