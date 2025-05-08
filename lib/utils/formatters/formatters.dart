import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class InputValidators {

  static String? validateEmptyText(String? fieldName, String? value) {
    if(value == null || value.isEmpty) {
      return '$fieldName is required!';
    }
    return null;
  }
  // Email validator
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Regex to match a valid email with any domain
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    return null;
  }


  static String? validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your first name';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'First name can only contain letters';
    }

    return null;
  }


  static String? validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your first name';
    }
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
      return 'First name can only contain letters';
    }
    return null;
  }

  static String? validatePassword(String? value) {
      if (value == null || value.isEmpty) {
        return 'Please enter your password';
      }
      if (value.length < 6) {
        return 'Password must be at least 6 characters long';
      }
      return null;
    }

  // Validator for Birthdate using intl package (dd/mm/yyyy)
  static String? validateBirthdate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Birthdate is required';
    }
    try {
      // Parse the input date with the expected format dd/MM/yyyy
      DateFormat dateFormat = DateFormat('dd/MM/yyyy');
      dateFormat.parseStrict(value);
    } catch (e) {
      return 'Enter a valid date in dd/MM/yyyy format';
    }
    return null;
  }

  // DateInputFormatter to enforce dd/MM/yyyy format
  static TextInputFormatter dateInputFormatter() {
    return DateInputFormatter();
  }
}

// Date Input Formatter Class for birthdate (dd/MM/yyyy)
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.length > 8) {
      text = text.substring(0, 8);
    }

    String formattedText = '';
    if (text.length >= 2) {
      formattedText += text.substring(0, 2) + '/';
    }
    if (text.length >= 4) {
      formattedText += text.substring(2, 4) + '/';
    }
    if (text.length > 4) {
      formattedText += text.substring(4);
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}


String? phoneNumberValidator(String? value) {
  // Check if the value is empty
  if (value == null || value.isEmpty) {
    return 'Please enter your phone number';
  }

  // Regular expression for validating a 10-digit phone number
  final RegExp phoneRegExp = RegExp(r'^[0-9]{10}$');

  // Check if the phone number matches the regular expression
  if (!phoneRegExp.hasMatch(value)) {
    return 'Please enter a valid 10-digit phone number';
  }

  return null; // Return null if the phone number is valid
}

String? ageValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your age';
  }

  final int? age = int.tryParse(value);

  if (age == null || age <= 0) {
    return 'Please enter a valid age';
  } else if (age < 15 || age > 100) {
    return 'Please enter an age between 15 and 100';
  }

  return null; // Return null if age is valid
}



String? weightValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your weight';
  }

  final double? weight = double.tryParse(value);

  if (weight == null || weight <= 0) {
    return 'Please enter a valid weight';
  } else if (weight < 25 || weight > 300) {
    return 'Weight must be between 25kg and 300kg';
  }

  return null; // Return null if weight is valid
}


String? heightValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your height';
  }

  final double? height = double.tryParse(value);

  if (height == null || height <= 0) {
    return 'Please enter a valid height';
  } else if (height < 50 || height > 250) {
    return 'Height must be between 50cm and 250cm';
  }

  return null; // Return null if height is valid
}
