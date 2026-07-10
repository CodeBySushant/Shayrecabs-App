/// Form validators — mirror the backend rules exactly so errors are caught
/// client-side first (password >= 6, phone >= 10 digits, valid email).
class Validators {
  Validators._();

  static String? name(String? v) =>
      (v == null || v.trim().isEmpty) ? "Name is required" : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return "Email is required";
    final re = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    return re.hasMatch(v.trim()) ? null : "Enter a valid email address";
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return "Password is required";
    if (v.length < 6) return "Password must be at least 6 characters";
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return "Phone number is required";
    final digits = v.replaceAll(RegExp(r"\D"), "");
    return digits.length >= 10 ? null : "Enter a valid phone number";
  }

  static String? otp(String? v) {
    if (v == null || v.trim().isEmpty) return "Code is required";
    return v.trim().length == 6 ? null : "Enter the 6-digit code";
  }

  static String? required(String? v, [String label = "This field"]) =>
      (v == null || v.trim().isEmpty) ? "$label is required" : null;
}
