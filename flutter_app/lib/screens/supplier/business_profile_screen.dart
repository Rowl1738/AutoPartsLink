import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supplier_provider.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});
  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _businessName = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _operatingHours = TextEditingController();
  final _website = TextEditingController();
  final _registrationNumber = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _businessName.dispose();
    _description.dispose();
    _address.dispose();
    _operatingHours.dispose();
    _website.dispose();
    _registrationNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final profile = user?.supplierProfile;
    // Populate controllers once, on first build with real data.
    if (!_prefilled && profile != null) {
      _prefilled = true;
      _businessName.text = profile.businessName;
      _description.text = profile.description;
      _address.text = profile.address;
      _operatingHours.text = profile.operatingHours;
      _website.text = profile.website;
      _registrationNumber.text = profile.businessRegistrationNumber;
    }

    final supplierProvider = context.watch<SupplierProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Business Profile")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          TextField(controller: _businessName, decoration: const InputDecoration(labelText: "Business name")),
          const SizedBox(height: 14),
          TextField(controller: _description, maxLines: 3, decoration: const InputDecoration(labelText: "Business description", alignLabelWithHint: true)),
          const SizedBox(height: 14),
          TextField(controller: _address, decoration: const InputDecoration(labelText: "Address", prefixIcon: Icon(Icons.location_on_outlined))),
          const SizedBox(height: 14),
          TextField(controller: _operatingHours, decoration: const InputDecoration(labelText: "Operating hours (e.g. Mon-Fri 8am-5pm)", prefixIcon: Icon(Icons.access_time))),
          const SizedBox(height: 14),
          TextField(controller: _website, decoration: const InputDecoration(labelText: "Website (optional)", prefixIcon: Icon(Icons.language_outlined))),
          const SizedBox(height: 14),
          TextField(controller: _registrationNumber, decoration: const InputDecoration(labelText: "Business registration number (optional)")),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final ok = await supplierProvider.updateMyProfile({
                "businessName": _businessName.text.trim(),
                "description": _description.text.trim(),
                "address": _address.text.trim(),
                "operatingHours": _operatingHours.text.trim(),
                "website": _website.text.trim(),
                "businessRegistrationNumber": _registrationNumber.text.trim(),
              });
              if (!context.mounted) return;
              if (ok) {
                await context.read<AuthProvider>().tryAutoLogin();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Business profile updated.")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(supplierProvider.error ?? "Update failed.")));
              }
            },
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }
}
