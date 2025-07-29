class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  // final String? age;
  // final String? gender;
  // final String? weight;
  // final String? height;
  final bool gutTestPaymentStatus;
  final String selectedRole; // Added selectedRole field
  final DateTime createdAt; // Field for timestamp

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    // this.age,
    // this.gender,
    // this.weight,
    // this.height,
    required this.gutTestPaymentStatus,
    required this.selectedRole, // Include selectedRole in constructor
    required this.createdAt,
  });

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      // 'age': age,
      // 'gender': gender,
      // 'weight': weight,
      // 'height': height,
      'gutTestPaymentStatus': gutTestPaymentStatus,
      'selectedRole': selectedRole, // Add selectedRole in toMap
      'createdAt': createdAt.toIso8601String(), // Store as ISO 8601 string
    };
  }

  // Convert Firestore document to UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      // age: map['age'],
      // gender: map['gender'],
      // weight: map['weight'],
      // height: map['height'],
      gutTestPaymentStatus: map['gutTestPaymentStatus'],
      selectedRole: map['selectedRole'], // Add selectedRole in fromMap
      createdAt: DateTime.parse(map['createdAt']), // Parse ISO 8601 string to DateTime
    );
  }
}
