import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autopartslink/models/order.dart';
import 'package:autopartslink/models/platform_stats.dart';
import 'package:autopartslink/models/procurement_request.dart';
import 'package:autopartslink/models/quotation.dart';
import 'package:autopartslink/models/user.dart';
import 'package:autopartslink/widgets/charts/column_chart.dart';
import 'package:autopartslink/widgets/charts/meter_list.dart';

ProcurementRequest _request(RequestStatus status, DateTime at) => ProcurementRequest(
      id: "r${at.microsecondsSinceEpoch}${status.index}",
      customerId: "c1",
      customerName: "Ama",
      vehicleMake: "Toyota",
      vehicleModel: "Hilux",
      vehicleYear: 2015,
      urgency: RequestUrgency.normal,
      status: status,
      createdAt: at,
    );

Order _order(OrderStatus status, String supplier, double price, DateTime at) => Order(
      id: "o$supplier${at.microsecondsSinceEpoch}${status.index}",
      quotationId: "q",
      requestId: "r",
      customerId: "c1",
      customerName: "Ama",
      supplierId: supplier,
      supplierName: supplier,
      status: status,
      fulfilmentMethod: FulfilmentMethod.delivery,
      items: [OrderItem(requestItemId: "i1", partName: "Filter", quantity: 2, unitPrice: price)],
      createdAt: at,
    );

Quotation _quote(QuotationStatus status) => Quotation(
      id: "q${status.index}${DateTime.now().microsecondsSinceEpoch}",
      requestId: "r",
      customerId: "c1",
      supplierId: "s1",
      supplierName: "Parts Co",
      status: status,
      createdAt: DateTime(2026, 11, 1),
    );

void main() {
  final now = DateTime(2026, 11, 22);

  final stats = PlatformStats.compute(
    now: now,
    users: [
      AppUser(id: "a", username: "admin", email: "a@x", role: UserRole.admin),
      AppUser(id: "c1", username: "ama", email: "c@x", role: UserRole.customer),
      AppUser(id: "c2", username: "kofi", email: "k@x", role: UserRole.customer, isActive: false),
      AppUser(id: "s1", username: "parts", email: "s@x", role: UserRole.supplier),
      AppUser(id: "s2", username: "spares", email: "p@x", role: UserRole.supplier, isApproved: false),
    ],
    requests: [
      _request(RequestStatus.open, DateTime(2026, 11, 3)),
      _request(RequestStatus.quotationsReceived, DateTime(2026, 11, 20)),
      _request(RequestStatus.completed, DateTime(2026, 9, 10)),
      _request(RequestStatus.cancelled, DateTime(2025, 1, 1)), // outside the 6-month window
    ],
    quotations: [_quote(QuotationStatus.accepted), _quote(QuotationStatus.rejected), _quote(QuotationStatus.submitted), _quote(QuotationStatus.accepted)],
    orders: [
      _order(OrderStatus.completed, "Parts Co", 100, DateTime(2026, 11, 5)), // 200
      _order(OrderStatus.processing, "Spares Ltd", 50, DateTime(2026, 10, 2)), // 100
      _order(OrderStatus.cancelled, "Spares Ltd", 999, DateTime(2026, 11, 6)), // excluded from value
    ],
  );

  test("PlatformStats counts users, requests, quotations and orders", () {
    expect(stats.customers, 2);
    expect(stats.suppliers, 2);
    expect(stats.pendingSuppliers, 1);
    expect(stats.deactivatedUsers, 1);
    expect(stats.totalRequests, 4);
    expect(stats.openRequests, 2);
    expect(stats.acceptanceRate, 0.5);
    expect(stats.totalOrders, 3);
    expect(stats.completedOrders, 1);
    expect(stats.cancelledOrders, 1);
    expect(stats.orderValue, 300);
    expect(stats.averageOrderValue, 150);
  });

  test("PlatformStats buckets the last six months, oldest first", () {
    expect(stats.monthly.map((m) => m.month), [
      DateTime(2026, 6), DateTime(2026, 7), DateTime(2026, 8), DateTime(2026, 9), DateTime(2026, 10), DateTime(2026, 11),
    ]);
    expect(stats.monthly.map((m) => m.requests), [0, 0, 0, 1, 0, 2]);
    expect(stats.monthly.map((m) => m.orders), [0, 0, 0, 0, 1, 1]); // cancelled order excluded
    expect(stats.monthly.last.orderValue, 200);
  });

  test("Month buckets cross a year boundary", () {
    final s = PlatformStats.compute(now: DateTime(2027, 2, 1), users: [], requests: [], quotations: [], orders: []);
    expect(s.monthly.first.month, DateTime(2026, 9));
    expect(s.monthly.last.month, DateTime(2027, 2));
  });

  test("Top suppliers are ranked by non-cancelled order value", () {
    expect(stats.topSuppliers.map((e) => e.label), ["Parts Co", "Spares Ltd"]);
    expect(stats.topSuppliers.map((e) => e.value), [200, 100]);
  });

  testWidgets("ColumnChart selects the latest column and switches on tap", (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ColumnChart(labels: const ["Sep", "Oct", "Nov"], values: const [3, 7, 12], format: (v) => "${v.round()}", seriesName: "Requests"),
      ),
    ));
    expect(find.text("12"), findsOneWidget); // selected value label
    await tester.tap(find.bySemanticsLabel("Sep: Requests 3"));
    await tester.pump();
    expect(find.text("3"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("MeterList shows each figure with its share", (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MeterList(items: const [LabeledValue("Completed", 1), LabeledValue("Cancelled", 3)], format: (v) => "${v.round()}", shareOf: 4),
      ),
    ));
    expect(find.text("1 · 25%"), findsOneWidget);
    expect(find.text("3 · 75%"), findsOneWidget);
  });
}
