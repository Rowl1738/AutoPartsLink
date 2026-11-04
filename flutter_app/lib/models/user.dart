import '../core/utils/firestore_parsing.dart';

enum UserRole { admin, supplier, customer }

UserRole roleFromString(String s) {
  switch (s.toUpperCase()) {
    case "ADMIN":
      return UserRole.admin;
    case "SUPPLIER":
      return UserRole.supplier;
    default:
      return UserRole.customer;
  }
}

String roleToString(UserRole r) {
  switch (r) {
    case UserRole.admin:
      return "ADMIN";
    case UserRole.supplier:
      return "SUPPLIER";
    case UserRole.customer:
      return "CUSTOMER";
  }
}

class CustomerProfile {
  final String companyName;
  final String billingAddress;

  CustomerProfile({this.companyName = "", this.billingAddress = ""});

  factory CustomerProfile.fromMap(Map<String, dynamic> data) => CustomerProfile(
        companyName: data["companyName"] ?? "",
        billingAddress: data["billingAddress"] ?? "",
      );

  Map<String, dynamic> toMap() => {"companyName": companyName, "billingAddress": billingAddress};
}

/// The signed-in supplier's own business profile — stored in suppliers/{uid}
/// (the same document customers read as a SupplierListing).
class SupplierProfile {
  final String businessName;
  final String businessRegistrationNumber;
  final String description;
  final String website;
  final String address;
  final double? latitude;
  final double? longitude;
  final String operatingHours;
  final bool isVerified;
  final double? averageRating;

  SupplierProfile({
    this.businessName = "",
    this.businessRegistrationNumber = "",
    this.description = "",
    this.website = "",
    this.address = "",
    this.latitude,
    this.longitude,
    this.operatingHours = "",
    this.isVerified = false,
    this.averageRating,
  });

  factory SupplierProfile.fromMap(Map<String, dynamic> data, {double? averageRating}) => SupplierProfile(
        businessName: data["businessName"] ?? "",
        businessRegistrationNumber: data["businessRegistrationNumber"] ?? "",
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

class AppUser {
  /// Firebase Auth UID — also the users/{uid} (and suppliers/{uid}) document ID.
  final String id;
  final String username;
  final String email;
  final UserRole role;
  final String phone;
  final String address;
  final bool isApproved;
  final bool isActive;
  final DateTime? dateJoined;
  final CustomerProfile? customerProfile;
  final SupplierProfile? supplierProfile;

  AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.phone = "",
    this.address = "",
    this.isApproved = true,
    this.isActive = true,
    this.dateJoined,
    this.customerProfile,
    this.supplierProfile,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data, {SupplierProfile? supplierProfile}) {
    return AppUser(
      id: id,
      username: data["username"] ?? "",
      email: data["email"] ?? "",
      role: roleFromString(data["role"] ?? "CUSTOMER"),
      phone: data["phone"] ?? "",
      address: data["address"] ?? "",
      isApproved: data["isApproved"] ?? true,
      isActive: data["isActive"] ?? true,
      dateJoined: toDateTimeOrNull(data["createdAt"]),
      customerProfile: data["customerProfile"] is Map
          ? CustomerProfile.fromMap(Map<String, dynamic>.from(data["customerProfile"]))
          : null,
      supplierProfile: supplierProfile,
    );
  }

  AppUser copyWith({bool? isApproved, bool? isActive}) => AppUser(
        id: id,
        username: username,
        email: email,
        role: role,
        phone: phone,
        address: address,
        isApproved: isApproved ?? this.isApproved,
        isActive: isActive ?? this.isActive,
        dateJoined: dateJoined,
        customerProfile: customerProfile,
        supplierProfile: supplierProfile,
      );
}
