import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_collections.dart';
import '../models/user.dart';
import 'notification_service.dart';

class AdminService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection(FirestoreCollections.users);

  Future<List<AppUser>> listUsers({String? role}) async {
    Query<Map<String, dynamic>> query = _users;
    if (role != null) query = query.where("role", isEqualTo: role.toUpperCase());
    final snapshot = await query.get();
    final users = snapshot.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();
    users.sort((a, b) => (b.dateJoined ?? DateTime(0)).compareTo(a.dateJoined ?? DateTime(0)));
    return users;
  }

  Future<void> approveSupplier(String userId) async {
    final batch = _db.batch();
    batch.update(_users.doc(userId), {"isApproved": true});
    // Mirrored onto the public listing so the supplier appears in the directory.
    batch.update(_db.collection(FirestoreCollections.suppliers).doc(userId), {
      "isApproved": true,
      "updatedAt": FieldValue.serverTimestamp(),
    });
    batch.set(NotificationService.newRef(), NotificationService.payload(
      recipientId: userId,
      event: NotificationEvent.supplierApproved,
      message: "Your supplier account has been approved. You can now browse requests and submit quotations.",
    ));
    await batch.commit();
  }

  /// Deactivated users are signed out on their next login attempt and blocked
  /// from writes by firestore.rules (disabling the Firebase Auth account itself
  /// needs the Admin SDK, which the client app can't use).
  Future<void> setActive(String userId, bool isActive) => _users.doc(userId).update({"isActive": isActive});
}
