import '../core/utils/firestore_parsing.dart';

/// A supplier directory entry, read from suppliers/{uid}.
/// Distinct from the nested SupplierProfile on AppUser (that's "my own
/// profile"; this is "someone else's public listing").
class SupplierListing {
  final String id;
  final String username;
  final String phone;
  final String businessName;
  final String description;
  final String website;
  final String address;
  final double? latitude;
  final double? longitude;
  final String operatingHours;
  final bool isVerified;
  final double? averageRating;

  SupplierListing({
    required this.id,
    required this.username,
    this.phone = "",
    this.businessName = "",
    this.description = "",
    this.website = "",
    this.address = "",
    this.latitude,
    this.longitude,
    this.operatingHours = "",
    this.isVerified = false,
    this.averageRating,
  });

  factory SupplierListing.fromMap(String id, Map<String, dynamic> data, {double? averageRating}) => SupplierListing(
        id: id,
        username: data["username"] ?? "",
        phone: data["phone"] ?? "",
        businessName: data["businessName"] ?? "",
        description: data["description"] ?? "",
        website: data["website"] ?? "",
        address: data["address"] ?? "",
        latitude: toDoubleOrNull(data["latitude"]),
        longitude: toDoubleOrNull(data["longitude"]),
        operatingHours: data["operatingHours"] ?? "",
        isVerified: data["isVerified"] ?? false,
        averageRating: averageRating,
      );
}
