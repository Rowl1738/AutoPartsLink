import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/procurement_request.dart';
import '../../models/quotation.dart';
import '../../providers/quotation_provider.dart';

class SubmitQuotationScreen extends StatefulWidget {
  final ProcurementRequest request;
  const SubmitQuotationScreen({super.key, required this.request});

  @override
  State<SubmitQuotationScreen> createState() => _SubmitQuotationScreenState();
}

class _ItemPriceRow {
  final ProcurementRequestItem requestItem;
  final priceController = TextEditingController();
  final notesController = TextEditingController();
  bool available = true;

  _ItemPriceRow(this.requestItem);

  void dispose() {
    priceController.dispose();
    notesController.dispose();
  }
}

class _SubmitQuotationScreenState extends State<SubmitQuotationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fulfilmentDays = TextEditingController();
  final _notes = TextEditingController();
  late final List<_ItemPriceRow> _rows = widget.request.items.map((i) => _ItemPriceRow(i)).toList();

  @override
  void dispose() {
    _fulfilmentDays.dispose();
    _notes.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  double get _total => _rows.fold(0, (sum, row) {
        final price = double.tryParse(row.priceController.text) ?? 0;
        return sum + price * row.requestItem.quantity;
      });

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final items = _rows
        .map((row) => QuotationItem(
              requestItemId: row.requestItem.id!,
              unitPrice: double.tryParse(row.priceController.text) ?? 0,
              quantity: row.requestItem.quantity,
              isAvailable: row.available,
              notes: row.notesController.text.trim(),
            ))
        .toList();

    final provider = context.read<QuotationProvider>();
    final ok = await provider.submitQuotation(
      requestId: widget.request.id,
      expectedFulfilmentDays: int.tryParse(_fulfilmentDays.text.trim()),
      notes: _notes.text.trim(),
      items: items,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quotation submitted.")));
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotationProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text("Submit Quotation")),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              "${widget.request.vehicleMake} ${widget.request.vehicleModel} (${widget.request.vehicleYear})",
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ..._rows.map(_buildItemRow),
            const SizedBox(height: 8),
            TextFormField(
              controller: _fulfilmentDays,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Expected fulfilment time (days)"),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Additional notes (optional)", alignLabelWithHint: true),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total quote", style: TextStyle(fontWeight: FontWeight.w600)),
                Text("K${_total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: provider.loading ? null : _submit,
              child: provider.loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Submit Quotation"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(_ItemPriceRow row) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text("${row.requestItem.partName} (x${row.requestItem.quantity})", style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Switch(
                  value: row.available,
                  onChanged: (v) => setState(() => row.available = v),
                ),
              ],
            ),
            Text(row.available ? "Available" : "Not available", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: row.priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: "Unit price (K)"),
              validator: (v) {
                final price = double.tryParse(v ?? "");
                if (price == null || price < 0) return "Enter a valid price";
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: row.notesController,
              decoration: const InputDecoration(labelText: "Notes (optional)"),
            ),
          ],
        ),
      ),
    );
  }
}
