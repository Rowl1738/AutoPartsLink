/// Shared form-field validators, so every screen's Form fields behave
/// consistently instead of each re-inventing slightly different rules.
class Validators {
  static String? required(String? value, {String field = "This field"}) {
    if (value == null || value.trim().isEmpty) return "$field is required";
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return "Email is required";
    final pattern = RegExp(r"^[\w\.\-+]+@[\w\-]+\.[\w\-\.]+$");
    if (!pattern.hasMatch(value.trim())) return "Enter a valid email address";
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) return "Password is required";
    if (value.length < minLength) return "Password must be at least $minLength characters";
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return "Please confirm your password";
    if (value != original) return "Passwords do not match";
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional field
    final pattern = RegExp(r"^[\d\+\s\-]{7,20}$");
    if (!pattern.hasMatch(value.trim())) return "Enter a valid phone number";
    return null;
  }
}
