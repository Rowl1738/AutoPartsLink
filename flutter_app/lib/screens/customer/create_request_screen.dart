import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../models/procurement_request.dart';
import '../../providers/procurement_provider.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});
  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _ItemFormRow {
  final partName = TextEditingController();
  final partNumber = TextEditingController();
  final quantity = TextEditingController(text: "1");
  final description = TextEditingController();

  void dispose() {
    partName.dispose();
    partNumber.dispose();
    quantity.dispose();
    description.dispose();
  }
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleMake = TextEditingController();
  final _vehicleModel = TextEditingController();
  final _vehicleYear = TextEditingController();
  final _description = TextEditingController();
  final _preferredLocation = TextEditingController();
  RequestUrgency _urgency = RequestUrgency.normal;
  final List<_ItemFormRow> _items = [_ItemFormRow()];

  @override
  void dispose() {
    _vehicleMake.dispose();
    _vehicleModel.dispose();
    _vehicleYear.dispose();
    _description.dispose();
    _preferredLocation.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final items = _items
        .map((row) => ProcurementRequestItem(
              partName: row.partName.text.trim(),
              partNumber: row.partNumber.text.trim(),
              quantity: int.tryParse(row.quantity.text.trim()) ?? 1,
              description: row.description.text.trim(),
            ))
        .toList();

    final provider = context.read<ProcurementProvider>();
    final ok = await provider.createRequest(
      vehicleMake: _vehicleMake.text.trim(),
      vehicleModel: _vehicleModel.text.trim(),
      vehicleYear: int.tryParse(_vehicleYear.text.trim()) ?? DateTime.now().year,
      description: _description.text.trim(),
      urgency: urgencyToString(_urgency),
      preferredLocation: _preferredLocation.text.trim(),
      items: items,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Procurement request submitted.")));
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProcurementProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text("New Procurement Request")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const Text("Vehicle details", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _vehicleMake,
                    decoration: const InputDecoration(labelText: "Make"),
                    validator: (v) => Validators.required(v, field: "Make"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _vehicleModel,
                    decoration: const InputDecoration(labelText: "Model"),
                    validator: (v) => Validators.required(v, field: "Model"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _vehicleYear,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Year"),
              validator: (v) {
                final year = int.tryParse(v ?? "");
                if (year == null || year < 1970 || year > DateTime.now().year + 1) return "Enter a valid year";
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text("Request details", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description (optional)", alignLabelWithHint: true),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<RequestUrgency>(
              initialValue: _urgency,
              decoration: const InputDecoration(labelText: "Urgency"),
              items: RequestUrgency.values
                  .map((u) => DropdownMenuItem(value: u, child: Text(urgencyLabel(u))))
                  .toList(),
              onChanged: (v) => setState(() => _urgency = v ?? RequestUrgency.normal),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _preferredLocation,
              decoration: const InputDecoration(labelText: "Preferred location (optional)", prefixIcon: Icon(Icons.location_on_outlined)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Spare parts needed", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                TextButton.icon(
                  onPressed: () => setState(() => _items.add(_ItemFormRow())),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add part"),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...List.generate(_items.length, (index) => _buildItemCard(index)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: provider.loading ? null : _submit,
              child: provider.loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Submit Request"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(int index) {
    final row = _items[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Part ${index + 1}", style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                if (_items.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _items.removeAt(index)),
                  ),
              ],
            ),
            TextFormField(
              controller: row.partName,
              decoration: const InputDecoration(labelText: "Part name"),
              validator: (v) => Validators.required(v, field: "Part name"),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: row.partNumber,
                    decoration: const InputDecoration(labelText: "Part number (optional)"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: row.quantity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Qty"),
                    validator: (v) {
                      final qty = int.tryParse(v ?? "");
                      if (qty == null || qty < 1) return "Invalid";
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: row.description,
              decoration: const InputDecoration(labelText: "Notes (optional)"),
            ),
          ],
        ),
      ),
    );
  }
}
