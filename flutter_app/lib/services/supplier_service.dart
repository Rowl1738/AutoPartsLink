import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_collections.dart';
import '../core/services/session.dart';
import '../core/utils/app_error.dart';
import '../models/rating.dart';
import '../models/supplier_listing.dart';
import 'rating_service.dart';

class SupplierService {
  final _db = FirebaseFirestore.instance;
  final _ratingService = RatingService();

  CollectionReference<Map<String, dynamic>> get _suppliers => _db.collection(FirestoreCollections.suppliers);

  /// Approved suppliers, optionally filtered by business name / address.
  /// Firestore has no substring search, so the filter runs client-side —
  /// fine at this project's scale.
  Future<List<SupplierListing>> listSuppliers({String? search}) async {
    final snapshot = await _suppliers.where("isApproved", isEqualTo: true).get();
    final term = search?.trim().toLowerCase() ?? "";
    final docs = snapshot.docs.where((d) {
      if (term.isEmpty) return true;
      final data = d.data();
      return "${data["businessName"] ?? ""}".toLowerCase().contains(term) ||
          "${data["address"] ?? ""}".toLowerCase().contains(term);
    }).toList();

    final averages = await Future.wait(docs.map((d) => _ratingService.averageFor(d.id)));
    return [
      for (var i = 0; i < docs.length; i++) SupplierListing.fromMap(docs[i].id, docs[i].data(), averageRating: averages[i]),
    ];
  }

  Future<SupplierListing> getSupplier(String id) async {
    final doc = await _suppliers.doc(id).get();
    if (!doc.exists) throw const AppException("Supplier not found.");
    return SupplierListing.fromMap(doc.id, doc.data()!, averageRating: await _ratingService.averageFor(id));
  }

  Future<List<Rating>> getSupplierRatings(String id) => _ratingService.listRatingsForSupplier(id);

  static const _editableFields = {
    "businessName", "businessRegistrationNumber", "description", "website",
    "address", "latitude", "longitude", "operatingHours",
  };

  Future<void> updateMyProfile(Map<String, dynamic> data) async {
    final user = Session.user;
    if (!user.isApproved) throw const AppException("Your supplier account is awaiting admin approval.");
    await _suppliers.doc(user.id).update({
      for (final entry in data.entries)
        if (_editableFields.contains(entry.key)) entry.key: entry.value,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }
}
