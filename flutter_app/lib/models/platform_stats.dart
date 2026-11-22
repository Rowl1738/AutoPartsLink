import 'order.dart';
import 'procurement_request.dart';
import 'quotation.dart';
import 'user.dart';

/// One calendar month's activity, used by the admin trend chart.
class MonthlyActivity {
  final DateTime month; // first day of the month
  final int requests;
  final int orders;
  final double orderValue;

  const MonthlyActivity({required this.month, this.requests = 0, this.orders = 0, this.orderValue = 0});
}

/// A named amount, e.g. one status and its count, or one supplier and its sales.
class LabeledValue {
  final String label;
  final double value;
  const LabeledValue(this.label, this.value);
}

/// Platform-wide aggregates for the admin Reports screen. Pure and
/// Firebase-free so it can be unit tested with plain model objects.
class PlatformStats {
  final int customers;
  final int suppliers;
  final int approvedSuppliers;
  final int pendingSuppliers;
  final int deactivatedUsers;
  final int totalRequests;
  final int openRequests;
  final int totalQuotations;
  final int acceptedQuotations;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;

  /// Sum of all non-cancelled orders.
  final double orderValue;
  final List<MonthlyActivity> monthly;
  final List<LabeledValue> ordersByStatus;
  final List<LabeledValue> requestsByStatus;
  final List<LabeledValue> topSuppliers;

  const PlatformStats({
    required this.customers,
    required this.suppliers,
    required this.approvedSuppliers,
    required this.pendingSuppliers,
    required this.deactivatedUsers,
    required this.totalRequests,
    required this.openRequests,
    required this.totalQuotations,
    required this.acceptedQuotations,
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.orderValue,
    required this.monthly,
    required this.ordersByStatus,
    required this.requestsByStatus,
    required this.topSuppliers,
  });

  /// Share of quotations that became orders, 0–1 (0 when there are none).
  double get acceptanceRate => totalQuotations == 0 ? 0 : acceptedQuotations / totalQuotations;

  /// Average value of a non-cancelled order (0 when there are none).
  double get averageOrderValue {
    final n = totalOrders - cancelledOrders;
    return n == 0 ? 0 : orderValue / n;
  }

  factory PlatformStats.compute({
    required List<AppUser> users,
    required List<ProcurementRequest> requests,
    required List<Quotation> quotations,
    required List<Order> orders,
    DateTime? now,
    int months = 6,
    int topSupplierCount = 5,
  }) {
    final suppliers = users.where((u) => u.role == UserRole.supplier).toList();
    final liveOrders = orders.where((o) => o.status != OrderStatus.cancelled).toList();

    // Monthly buckets, oldest first, ending with the current month.
    final today = now ?? DateTime.now();
    final starts = List.generate(months, (i) => DateTime(today.year, today.month - (months - 1 - i)));
    int bucketOf(DateTime d) {
      final start = DateTime(d.year, d.month);
      return starts.indexWhere((s) => s == start);
    }

    final reqCounts = List.filled(months, 0);
    final orderCounts = List.filled(months, 0);
    final orderValues = List.filled(months, 0.0);
    for (final r in requests) {
      final i = bucketOf(r.createdAt);
      if (i >= 0) reqCounts[i]++;
    }
    for (final o in liveOrders) {
      final i = bucketOf(o.createdAt);
      if (i >= 0) {
        orderCounts[i]++;
        orderValues[i] += o.total;
      }
    }

    // Statuses keep their natural (workflow) order rather than being ranked.
    final ordersByStatus = [...orderStatusFlow, OrderStatus.cancelled]
        .map((s) => LabeledValue(orderStatusLabel(s), orders.where((o) => o.status == s).length.toDouble()))
        .toList();
    final requestsByStatus = RequestStatus.values
        .map((s) => LabeledValue(requestStatusLabel(s), requests.where((r) => r.status == s).length.toDouble()))
        .where((v) => v.value > 0 || v.label != requestStatusLabel(RequestStatus.submitted))
        .toList();

    final bySupplier = <String, double>{};
    for (final o in liveOrders) {
      final name = o.supplierName.isEmpty ? "Unknown supplier" : o.supplierName;
      bySupplier[name] = (bySupplier[name] ?? 0) + o.total;
    }
    final topSuppliers = bySupplier.entries.map((e) => LabeledValue(e.key, e.value)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return PlatformStats(
      customers: users.where((u) => u.role == UserRole.customer).length,
      suppliers: suppliers.length,
      approvedSuppliers: suppliers.where((u) => u.isApproved).length,
      pendingSuppliers: suppliers.where((u) => !u.isApproved).length,
      deactivatedUsers: users.where((u) => !u.isActive).length,
      totalRequests: requests.length,
      openRequests: requests
          .where((r) => r.status == RequestStatus.open || r.status == RequestStatus.quotationsReceived)
          .length,
      totalQuotations: quotations.length,
      acceptedQuotations: quotations.where((q) => q.status == QuotationStatus.accepted).length,
      totalOrders: orders.length,
      completedOrders: orders.where((o) => o.status == OrderStatus.completed).length,
      cancelledOrders: orders.length - liveOrders.length,
      orderValue: liveOrders.fold(0.0, (sum, o) => sum + o.total),
      monthly: List.generate(
        months,
        (i) => MonthlyActivity(month: starts[i], requests: reqCounts[i], orders: orderCounts[i], orderValue: orderValues[i]),
      ),
      ordersByStatus: ordersByStatus,
      requestsByStatus: requestsByStatus,
      topSuppliers: topSuppliers.take(topSupplierCount).toList(),
    );
  }
}
