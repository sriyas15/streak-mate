import '../constants/app_constants.dart';

/// validators.dart
/// Mirrors backend userSchema validation so users get instant feedback
/// before hitting the network.
class Validators {
  Validators._();

  static String? name(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Name is required';
    if (trimmed.length < 2) return 'Name must be at least 2 characters';
    if (trimmed.length > 50) return 'Name must be under 50 characters';
    return null;
  }

  static String? username(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return 'Username is required';
    if (trimmed.length < AppConstants.usernameMinLength) {
      return 'Username must be at least ${AppConstants.usernameMinLength} characters';
    }
    if (trimmed.length > AppConstants.usernameMaxLength) {
      return 'Username must be under ${AppConstants.usernameMaxLength} characters';
    }
    if (!AppConstants.usernamePattern.hasMatch(trimmed)) {
      return 'Only lowercase letters, numbers and underscores';
    }
    return null;
  }

  static String? email(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Email is required';
    if (!AppConstants.emailPattern.hasMatch(trimmed)) return 'Enter a valid email';
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Password is required';
    if (value.length < AppConstants.passwordMinLength) {
      return 'Password must be at least ${AppConstants.passwordMinLength} characters';
    }
    return null;
  }

  static String? confirmPassword(String value, String original) {
    if (value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }
}