import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../widgets/status_chip.dart';
import 'order_detail_screen.dart';

/// "Active Orders" / "Order History" (customer), "Orders Received" (supplier),
/// "All Orders" (admin) — one screen, OrderService role-scopes the query.
class OrdersListScreen extends StatefulWidget {
  final String title;
  final bool Function(Order)? filter;

  const OrdersListScreen({super.key, required this.title, this.filter});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OrderProvider>().loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final orders = widget.filter == null ? provider.orders : provider.orders.where(widget.filter!).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: () => context.read<OrderProvider>().loadOrders(),
        child: provider.loading && provider.orders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : orders.isEmpty
                ? ListView(children: const [
                    Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.local_shipping_outlined, size: 56, color: AppColors.textSecondary),
                            SizedBox(height: 12),
                            Text("No orders here yet", style: TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: orders.length,
                    itemBuilder: (context, index) => _OrderCard(order: orders[index]),
                  ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id))),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text("Order #${order.reference}", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                    StatusChip(label: orderStatusLabel(order.status), color: orderStatusColor(orderStatusToApiString(order.status))),
                  ],
                ),
                const SizedBox(height: 6),
                Text("${order.customerName} · ${order.supplierName}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(DateFormat.yMMMd().format(order.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const Spacer(),
                    Text("K${order.total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
