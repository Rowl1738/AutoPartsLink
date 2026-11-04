import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore timestamps come back as [Timestamp], or null while a
/// FieldValue.serverTimestamp() write is still pending locally.
DateTime toDateTime(dynamic value) => toDateTimeOrNull(value) ?? DateTime.now();

DateTime? toDateTimeOrNull(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

double? toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

double toDouble(dynamic value) => toDoubleOrNull(value) ?? 0;

int toInt(dynamic value) => value is num ? value.toInt() : int.tryParse("$value") ?? 0;

/// Firestore document IDs are long random strings; this derives a short,
/// stable, human-friendly reference (e.g. "Order #K3F9QZ") for display.
String shortRef(String id) {
  var hash = 0x811c9dc5; // FNV-1a, 32-bit — deterministic across app runs
  for (final unit in id.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(36).toUpperCase().padLeft(6, "0");
}
