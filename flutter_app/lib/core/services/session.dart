import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user.dart';
import '../utils/app_error.dart';

/// The signed-in user's profile, kept by AuthRepository so the data
/// services can scope their Firestore queries by role without each one
/// re-reading users/{uid}.
class Session {
  static AppUser? currentUser;

  static AppUser get user {
    final user = currentUser;
    if (user == null || FirebaseAuth.instance.currentUser == null) {
      throw const AppException("Your session has expired. Please log in again.");
    }
    return user;
  }

  static String get uid => user.id;
}
