import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_collections.dart';
import '../core/services/session.dart';
import '../core/utils/app_error.dart';
import '../models/rating.dart';

class RatingService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ratings => _db.collection(FirestoreCollections.ratings);

  Future<List<Rating>> listRatingsForSupplier(String supplierId) async {
    final snapshot = await _ratings.where("supplierId", isEqualTo: supplierId).get();
    return snapshot.docs.map((d) => Rating.fromMap(d.id, d.data())).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Ratings the signed-in supplier has received.
  Future<List<Rating>> listMyRatings() => listRatingsForSupplier(Session.uid);

  /// Server-side AVG over the supplier's ratings; null when there are none.
  /// Needs the (supplierId, score) index in firestore.indexes.json. The average
  /// is display-only, so a failed lookup returns null rather than breaking
  /// login, registration or the supplier directory.
  Future<double?> averageFor(String supplierId) async {
    try {
      final snapshot = await _ratings.where("supplierId", isEqualTo: supplierId).aggregate(average("score")).get();
      return snapshot.getAverage("score");
    } on FirebaseException {
      return null;
    }
  }

  Future<Rating> rateOrder({required String orderId, required int score, String? reviewTitle, String? reviewBody}) async {
    if (score < 1 || score > 5) throw const AppException("Score must be between 1 and 5.");
    final me = Session.user;
    final ratingRef = _ratings.doc(orderId);
    final hasReview = (reviewTitle?.isNotEmpty ?? false) || (reviewBody?.isNotEmpty ?? false);

    await _db.runTransaction((tx) async {
      final orderSnap = await tx.get(_db.collection(FirestoreCollections.orders).doc(orderId));
      final order = orderSnap.data();
      if (order == null || order["customerId"] != me.id) {
        throw const AppException("You may only rate your own orders.");
      }
      if (order["status"] != "COMPLETED") throw const AppException("Only completed orders can be rated.");
      // No pre-read of ratings/{orderId}: rules forbid overwriting it, which
      // is what enforces "one rating per order".
      tx.set(ratingRef, {
        "orderId": orderId,
        "customerId": me.id,
        "customerName": me.username,
        "supplierId": order["supplierId"],
        "score": score,
        "review": hasReview ? Review(title: reviewTitle ?? "", body: reviewBody ?? "").toMap() : null,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }).catchError((Object e) {
      if (e is FirebaseException && e.code == "permission-denied") {
        throw const AppException("This order has already been rated.");
      }
      throw e;
    });

    final created = await ratingRef.get();
    return Rating.fromMap(created.id, created.data()!);
  }
}
