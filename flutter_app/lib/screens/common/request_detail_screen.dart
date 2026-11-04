import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order.dart';
import '../../models/procurement_request.dart';
import '../../models/quotation.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/procurement_provider.dart';
import '../../providers/quotation_provider.dart';
import '../../widgets/status_chip.dart';
import '../supplier/submit_quotation_screen.dart';
import 'order_detail_screen.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;
  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  ProcurementRequest? _request;
  bool _loading = true;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final procurementProvider = context.read<ProcurementProvider>();
    final quotationProvider = context.read<QuotationProvider>();
    final request = await procurementProvider.getRequest(widget.requestId);
    if (!mounted) return;
    await quotationProvider.loadQuotations();
    if (!mounted) return;
    setState(() {
      _request = request;
      _loading = false;
    });
  }

  Future<void> _acceptQuotation(Quotation quotation) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _AcceptQuotationDialog(quotation: quotation),
    );
    if (result == null || !mounted) return;
    setState(() => _accepting = true);
    final orderProvider = context.read<OrderProvider>();
    final order = await orderProvider.acceptQuotation(
          quotationId: quotation.id,
          fulfilmentMethod: result["method"]!,
          deliveryAddress: result["address"] ?? "",
        );
    if (!mounted) return;
    setState(() => _accepting = false);
    if (order != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)));
    } else {
      final error = context.read<OrderProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? "Couldn't accept this quotation.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text("Request Details")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _request == null
              ? const Center(child: Text("Request not found."))
              : RefreshIndicator(onRefresh: _load, child: _buildBody(_request!, user)),
    );
  }

  Widget _buildBody(ProcurementRequest request, AppUser? user) {
    final quotations = context.watch<QuotationProvider>().forRequest(request.id);
    final myQuotation = user?.role == UserRole.supplier
        ? quotations.where((q) => q.supplierId == user!.id).cast<Quotation?>().firstWhere((q) => true, orElse: () => null)
        : null;
    final canAcceptQuotations = request.status == RequestStatus.open || request.status == RequestStatus.quotationsReceived;
    final canSupplierQuote = user?.role == UserRole.supplier && myQuotation == null && canAcceptQuotations;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "${request.vehicleMake} ${request.vehicleModel} (${request.vehicleYear})",
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
            ),
            StatusChip(
              label: requestStatusLabel(request.status),
              color: requestStatusColor(requestStatusToApiString(request.status)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text("Requested by ${request.customerName} · ${DateFormat.yMMMd().format(request.createdAt)}",
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        if (request.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(request.description),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            Chip(avatar: const Icon(Icons.priority_high, size: 16), label: Text(urgencyLabel(request.urgency))),
            if (request.preferredLocation.isNotEmpty)
              Chip(avatar: const Icon(Icons.location_on_outlined, size: 16), label: Text(request.preferredLocation)),
          ],
        ),
        const SizedBox(height: 24),
        const Text("Parts needed", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        ...request.items.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(item.partName),
                subtitle: Text([
                  if (item.partNumber.isNotEmpty) "Part #${item.partNumber}",
                  if (item.description.isNotEmpty) item.description,
                ].join(" · ")),
                trailing: Text("x${item.quantity}", style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            )),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Quotations", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            if (canSupplierQuote)
              FilledButton.icon(
                onPressed: () async {
                  final submitted = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => SubmitQuotationScreen(request: request)),
                  );
                  if (submitted == true) _load();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Submit Quotation"),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (quotations.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text("No quotations yet.", style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          ...quotations.map((q) => _QuotationCard(
                quotation: q,
                canAccept: user?.role == UserRole.customer && canAcceptQuotations && q.status == QuotationStatus.submitted,
                accepting: _accepting,
                onAccept: () => _acceptQuotation(q),
              )),
      ],
    );
  }
}

class _QuotationCard extends StatelessWidget {
  final Quotation quotation;
  final bool canAccept;
  final bool accepting;
  final VoidCallback onAccept;

  const _QuotationCard({required this.quotation, required this.canAccept, required this.accepting, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(quotation.supplierName, style: const TextStyle(fontWeight: FontWeight.w700))),
                StatusChip(label: quotationStatusLabel(quotation.status), color: quotationStatusColor(quotation.status.name.toUpperCase())),
              ],
            ),
            const SizedBox(height: 8),
            ...quotation.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Expanded(child: Text("${item.partName} x${item.quantity}", style: const TextStyle(fontSize: 13))),
                      Text("K${item.subtotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
            const Divider(height: 18),
            Row(
              children: [
                if (quotation.expectedFulfilmentDays != null)
                  Expanded(
                    child: Text("${quotation.expectedFulfilmentDays} day(s)", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                  ),
                Text("Total: K${quotation.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            if (quotation.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(quotation.notes, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            ],
            if (canAccept) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: accepting ? null : onAccept,
                  child: accepting
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Accept this Quotation"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AcceptQuotationDialog extends StatefulWidget {
  final Quotation quotation;
  const _AcceptQuotationDialog({required this.quotation});

  @override
  State<_AcceptQuotationDialog> createState() => _AcceptQuotationDialogState();
}

class _AcceptQuotationDialogState extends State<_AcceptQuotationDialog> {
  FulfilmentMethod _method = FulfilmentMethod.delivery;
  final _address = TextEditingController();

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Accept quotation?"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Total: K${widget.quotation.totalAmount.toStringAsFixed(2)} from ${widget.quotation.supplierName}"),
          const SizedBox(height: 16),
          SegmentedButton<FulfilmentMethod>(
            segments: const [
              ButtonSegment(value: FulfilmentMethod.delivery, label: Text("Delivery")),
              ButtonSegment(value: FulfilmentMethod.collection, label: Text("Collection")),
            ],
            selected: {_method},
            onSelectionChanged: (s) => setState(() => _method = s.first),
          ),
          if (_method == FulfilmentMethod.delivery) ...[
            const SizedBox(height: 12),
            TextField(controller: _address, decoration: const InputDecoration(labelText: "Delivery address")),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        FilledButton(
          onPressed: () {
            if (_method == FulfilmentMethod.delivery && _address.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delivery address is required.")));
              return;
            }
            Navigator.pop(context, {
              "method": _method == FulfilmentMethod.delivery ? "DELIVERY" : "COLLECTION",
              "address": _address.text.trim(),
            });
          },
          child: const Text("Confirm"),
        ),
      ],
    );
  }
}
