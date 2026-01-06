class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    if (value.length > 50) {
      return 'Password must be less than 50 characters';
    }
    
    return null;
  }

  // Strong password validation
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    
    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digit characters
    final cleanedValue = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanedValue.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    if (cleanedValue.length > 15) {
      return 'Phone number must be less than 15 digits';
    }
    
    return null;
  }

  // Indian phone number validation
  static String? validateIndianPhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digit characters
    final cleanedValue = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanedValue.length != 10) {
      return 'Indian phone number must be exactly 10 digits';
    }
    
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleanedValue)) {
      return 'Please enter a valid Indian phone number';
    }
    
    return null;
  }

  // OTP validation
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    
    if (value.length != 6) {
      return 'OTP must be exactly 6 digits';
    }
    
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    
    return null;
  }

  // Amount validation
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    
    if (amount > 999999999) {
      return 'Amount is too large';
    }
    
    return null;
  }

  // Positive number validation
  static String? validatePositiveNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Number is required';
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (number < 0) {
      return 'Number must be positive';
    }
    
    return null;
  }

  // Integer validation
  static String? validateInteger(String? value) {
    if (value == null || value.isEmpty) {
      return 'Number is required';
    }
    
    final number = int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid integer';
    }
    
    return null;
  }

  // Positive integer validation
  static String? validatePositiveInteger(String? value) {
    if (value == null || value.isEmpty) {
      return 'Number is required';
    }
    
    final number = int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid integer';
    }
    
    if (number < 0) {
      return 'Number must be positive';
    }
    
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    return null;
  }

  // Minimum length validation
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }
    
    return null;
  }

  // Maximum length validation
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    
    return null;
  }

  // Length range validation
  static String? validateLength(String? value, int minLength, int maxLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }
    
    if (value.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    
    return null;
  }

  // URL validation
  static String? validateURL(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  // Date validation
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  // Future date validation
  static String? validateFutureDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    
    try {
      final date = DateTime.parse(value);
      if (date.isBefore(DateTime.now())) {
        return 'Date must be in the future';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  // Past date validation
  static String? validatePastDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    
    try {
      final date = DateTime.parse(value);
      if (date.isAfter(DateTime.now())) {
        return 'Date must be in the past';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  // Apartment number validation
  static String? validateApartmentNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Apartment number is required';
    }
    
    if (value.length > 10) {
      return 'Apartment number must be less than 10 characters';
    }
    
    return null;
  }

  // Building name validation
  static String? validateBuildingName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Building name is required';
    }
    
    if (value.length < 2) {
      return 'Building name must be at least 2 characters';
    }
    
    if (value.length > 50) {
      return 'Building name must be less than 50 characters';
    }
    
    return null;
  }

  // Description validation
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    
    if (value.length < 10) {
      return 'Description must be at least 10 characters';
    }
    
    if (value.length > 500) {
      return 'Description must be less than 500 characters';
    }
    
    return null;
  }

  // Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    
    if (value.length < 10) {
      return 'Address must be at least 10 characters';
    }
    
    if (value.length > 200) {
      return 'Address must be less than 200 characters';
    }
    
    return null;
  }

  // Pincode validation (Indian)
  static String? validatePincode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Pincode is required';
    }
    
    if (value.length != 6) {
      return 'Pincode must be exactly 6 digits';
    }
    
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Pincode must contain only numbers';
    }
    
    return null;
  }

  // Aadhar number validation
  static String? validateAadharNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Aadhar number is required';
    }
    
    if (value.length != 12) {
      return 'Aadhar number must be exactly 12 digits';
    }
    
    if (!RegExp(r'^\d{12}$').hasMatch(value)) {
      return 'Aadhar number must contain only numbers';
    }
    
    return null;
  }

  // PAN number validation
  static String? validatePANNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'PAN number is required';
    }
    
    if (value.length != 10) {
      return 'PAN number must be exactly 10 characters';
    }
    
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value)) {
      return 'Please enter a valid PAN number';
    }
    
    return null;
  }
}
