import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/firestore_collections.dart';
import '../core/utils/app_error.dart';
import '../models/user.dart';
import 'rating_service.dart';

/// Firebase Auth (credentials) + users/{uid} and suppliers/{uid} (profile).
/// Knows nothing about app state — that's AuthRepository/AuthProvider's job.
class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection(FirestoreCollections.users);
  CollectionReference<Map<String, dynamic>> get _suppliers => _db.collection(FirestoreCollections.suppliers);

  Future<AppUser> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = await fetchProfile(credential.user!.uid);
    if (!user.isActive) {
      await _auth.signOut();
      throw const AppException("This account has been deactivated. Contact an administrator.");
    }
    return user;
  }

  Future<AppUser> register({
    required String username,
    required String email,
    required String password,
    required UserRole role,
    String phone = "",
    String address = "",
    String companyName = "",
    String businessName = "",
  }) async {
    if (role == UserRole.admin) throw const AppException("Cannot self-register as Admin.");

    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;
    try {
      final batch = _db.batch();
      batch.set(_users.doc(uid), {
        "username": username,
        "email": email,
        "role": roleToString(role),
        "phone": phone,
        "address": address,
        // Suppliers start unapproved so an Admin must vet them before they can quote.
        "isApproved": role != UserRole.supplier,
        "isActive": true,
        "createdAt": FieldValue.serverTimestamp(),
        if (role == UserRole.customer) "customerProfile": CustomerProfile(companyName: companyName).toMap(),
      });
      if (role == UserRole.supplier) {
        batch.set(_suppliers.doc(uid), {
          "username": username,
          "phone": phone,
          "businessName": businessName,
          "businessRegistrationNumber": "",
          "description": "",
          "website": "",
          "address": address,
          "latitude": null,
          "longitude": null,
          "operatingHours": "",
          "isApproved": false,
          "isVerified": false,
          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      await credential.user!.updateDisplayName(username);
    } catch (_) {
      // Don't leave behind an Auth account with no profile document.
      await credential.user?.delete();
      rethrow;
    }
    return fetchProfile(uid);
  }

  /// Resolves once Firebase has restored any persisted session on launch.
  Future<String?> restoredSessionUid() async => (await _auth.authStateChanges().first)?.uid;

  Future<AppUser> fetchProfile([String? uid]) async {
    uid ??= _auth.currentUser?.uid;
    if (uid == null) throw const AppException("You're not signed in.");

    final doc = await _users.doc(uid).get();
    final data = doc.data();
    if (data == null) throw const AppException("Your account profile could not be found.");

    SupplierProfile? supplierProfile;
    if (roleFromString(data["role"] ?? "") == UserRole.supplier) {
      final supplierDoc = await _suppliers.doc(uid).get();
      if (supplierDoc.exists) {
        supplierProfile = SupplierProfile.fromMap(
          supplierDoc.data()!,
          averageRating: await RatingService().averageFor(uid),
        );
      }
    }
    return AppUser.fromMap(uid, data, supplierProfile: supplierProfile);
  }

  /// Updates the signed-in user's own contact details / customer profile.
  /// role, isApproved and isActive are deliberately not accepted here (and
  /// firestore.rules rejects them) so users can't grant themselves access.
  Future<AppUser> updateProfile({String? phone, String? address, CustomerProfile? customerProfile}) async {
    final uid = _auth.currentUser!.uid;
    final user = await fetchProfile(uid);
    final batch = _db.batch();
    batch.update(_users.doc(uid), {
      if (phone != null) "phone": phone,
      if (address != null) "address": address,
      if (customerProfile != null && user.role == UserRole.customer) "customerProfile": customerProfile.toMap(),
    });
    if (phone != null && user.role == UserRole.supplier) {
      batch.update(_suppliers.doc(uid), {"phone": phone, "updatedAt": FieldValue.serverTimestamp()});
    }
    await batch.commit();
    return fetchProfile(uid);
  }

  Future<void> logout() => _auth.signOut();
}
