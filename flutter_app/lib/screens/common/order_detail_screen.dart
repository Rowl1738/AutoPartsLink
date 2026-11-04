import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/status_chip.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _loading = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final order = await context.read<OrderProvider>().getOrder(widget.orderId);
    if (!mounted) return;
    setState(() {
      _order = order;
      _loading = false;
    });
  }

  Future<void> _advanceStatus(OrderStatus next) async {
    setState(() => _updating = true);
    final updated = await context.read<OrderProvider>().updateStatus(widget.orderId, status: orderStatusToApiString(next));
    if (!mounted) return;
    setState(() {
      _updating = false;
      if (updated != null) _order = updated;
    });
    if (updated == null) {
      final error = context.read<OrderProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? "Couldn't update the order.")));
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel this order?"),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("No")),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Yes, cancel")),
        ],
      ),
    );
    if (confirmed == true) _advanceStatus(OrderStatus.cancelled);
  }

  Future<void> _rate() async {
    final rated = await showDialog<bool>(context: context, builder: (_) => _RateOrderDialog(orderId: widget.orderId));
    if (rated == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text("Order Details")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text("Order not found."))
              : RefreshIndicator(onRefresh: _load, child: _buildBody(_order!, user)),
    );
  }

  Widget _buildBody(Order order, AppUser? user) {
    final isSupplier = user?.role == UserRole.supplier && user!.id == order.supplierId;
    final isCustomer = user?.role == UserRole.customer && user!.id == order.customerId;
    final nextStatus = _nextInFlow(order.status);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            Expanded(child: Text("Order #${order.reference}", style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700))),
            StatusChip(label: orderStatusLabel(order.status), color: orderStatusColor(orderStatusToApiString(order.status))),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "${order.customerName} · ${order.supplierName} · ${DateFormat.yMMMd().format(order.createdAt)}",
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
        ),
        const SizedBox(height: 8),
        Chip(
          avatar: Icon(order.fulfilmentMethod == FulfilmentMethod.delivery ? Icons.local_shipping_outlined : Icons.storefront_outlined, size: 16),
          label: Text(order.fulfilmentMethod == FulfilmentMethod.delivery
              ? (order.deliveryAddress.isEmpty ? "Delivery" : "Delivery to ${order.deliveryAddress}")
              : "Collection"),
        ),
        const SizedBox(height: 20),
        const Text("Items", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 8),
        ...order.items.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(item.partName),
                subtitle: Text("x${item.quantity} @ K${item.unitPrice.toStringAsFixed(2)}"),
                trailing: Text("K${item.subtotal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            )),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total", style: TextStyle(fontWeight: FontWeight.w700)),
              Text("K${order.total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text("Status timeline", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        ...order.statusHistory.map((h) => _TimelineTile(entry: h)),
        if (isSupplier && nextStatus != null && order.status != OrderStatus.cancelled) ...[
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _updating ? null : () => _advanceStatus(nextStatus),
            child: _updating
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text("Mark as ${orderStatusLabel(nextStatus)}"),
          ),
          if (order.status != OrderStatus.completed) ...[
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _updating ? null : _cancelOrder, child: const Text("Cancel Order")),
          ],
        ],
        if (isCustomer && order.status == OrderStatus.completed) ...[
          const SizedBox(height: 20),
          ElevatedButton.icon(onPressed: _rate, icon: const Icon(Icons.star_outline), label: const Text("Rate this Order")),
        ],
      ],
    );
  }

  OrderStatus? _nextInFlow(OrderStatus current) {
    final index = orderStatusFlow.indexOf(current);
    if (index == -1 || index == orderStatusFlow.length - 1) return null;
    return orderStatusFlow[index + 1];
  }
}

class _TimelineTile extends StatelessWidget {
  final OrderStatusHistoryEntry entry;
  const _TimelineTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10, height: 10, margin: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(orderStatusLabel(orderStatusFromString(entry.toStatus)), style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  "${DateFormat.yMMMd().add_jm().format(entry.changedAt)}${entry.changedByName != null ? ' · ${entry.changedByName}' : ''}",
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (entry.note.isNotEmpty) Text(entry.note, style: const TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RateOrderDialog extends StatefulWidget {
  final String orderId;
  const _RateOrderDialog({required this.orderId});

  @override
  State<_RateOrderDialog> createState() => _RateOrderDialogState();
}

class _RateOrderDialogState extends State<_RateOrderDialog> {
  int _score = 5;
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Rate this order"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RatingStarsInput(value: _score, onChanged: (v) => setState(() => _score = v)),
            const SizedBox(height: 12),
            TextField(controller: _title, decoration: const InputDecoration(labelText: "Review title (optional)")),
            const SizedBox(height: 10),
            TextField(controller: _body, maxLines: 3, decoration: const InputDecoration(labelText: "Comments (optional)")),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
        FilledButton(
          onPressed: _submitting
              ? null
              : () async {
                  setState(() => _submitting = true);
                  final navigator = Navigator.of(context);
                  final ok = await context.read<OrderProvider>().rateOrder(
                        orderId: widget.orderId, score: _score,
                        reviewTitle: _title.text.trim(), reviewBody: _body.text.trim(),
                      );
                  if (!mounted) return;
                  if (ok) {
                    navigator.pop(true);
                  } else {
                    setState(() => _submitting = false);
                  }
                },
          child: _submitting
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Submit"),
        ),
      ],
    );
  }
}
