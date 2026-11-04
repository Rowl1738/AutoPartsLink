import 'package:firebase_auth/firebase_auth.dart';

/// A business-rule failure detected client-side (e.g. "quotation no longer
/// available"), carrying a message that's safe to show the user as-is.
/// Firestore security rules enforce the same rules server-side; this just
/// lets the app explain *why* instead of a generic permission error.
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Flattens AppException / FirebaseAuthException / FirebaseException into one
/// human-readable string for a SnackBar.
String friendlyErrorMessage(Object error, {String fallback = "Something went wrong. Please try again."}) {
  if (error is AppException) return error.message;

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case "invalid-email":
        return "That email address isn't valid.";
      case "user-disabled":
        return "This account has been disabled.";
      case "user-not-found":
      case "wrong-password":
      case "invalid-credential":
        return "Incorrect email or password.";
      case "email-already-in-use":
        return "An account already exists for that email.";
      case "weak-password":
        return "Password is too weak — use at least 6 characters.";
      case "too-many-requests":
        return "Too many attempts. Please wait a moment and try again.";
      case "network-request-failed":
        return "Can't reach the server. Check your connection and try again.";
    }
    return error.message ?? fallback;
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case "permission-denied":
        return "You don't have permission to do that.";
      case "unavailable":
      case "deadline-exceeded":
        return "Can't reach the server. Check your connection and try again.";
      case "not-found":
        return "That record no longer exists.";
    }
    return fallback;
  }

  return fallback;
}
