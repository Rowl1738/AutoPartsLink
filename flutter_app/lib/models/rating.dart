import '../core/utils/firestore_parsing.dart';

class Review {
  final String title;
  final String body;

  Review({this.title = "", this.body = ""});

  factory Review.fromMap(Map<String, dynamic> data) => Review(
        title: data["title"] ?? "",
        body: data["body"] ?? "",
      );

  Map<String, dynamic> toMap() => {"title": title, "body": body};
}

class Rating {
  /// Same as [orderId] — ratings/{orderId} allows one rating per order.
  final String id;
  final String orderId;
  final String customerId;
  final String customerName;
  final String supplierId;
  final int score;
  final Review? review;
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.supplierId,
    required this.score,
    this.review,
    required this.createdAt,
  });

  factory Rating.fromMap(String id, Map<String, dynamic> data) => Rating(
        id: id,
        orderId: data["orderId"] ?? id,
        customerId: data["customerId"] ?? "",
        customerName: data["customerName"] ?? "",
        supplierId: data["supplierId"] ?? "",
        score: toInt(data["score"]),
        review: data["review"] is Map ? Review.fromMap(Map<String, dynamic>.from(data["review"])) : null,
        createdAt: toDateTime(data["createdAt"]),
      );
}
