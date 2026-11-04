import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/supplier_listing.dart';
import '../../providers/supplier_provider.dart';
import '../../widgets/rating_stars.dart';
import 'supplier_detail_screen.dart';

class FindSuppliersScreen extends StatefulWidget {
  const FindSuppliersScreen({super.key});

  @override
  State<FindSuppliersScreen> createState() => _FindSuppliersScreenState();
}

class _FindSuppliersScreenState extends State<FindSuppliersScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SupplierProvider>().loadSuppliers());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupplierProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text("Find Suppliers")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: "Search by business name or location",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          context.read<SupplierProvider>().loadSuppliers();
                          setState(() {});
                        },
                      ),
              ),
              onSubmitted: (v) => context.read<SupplierProvider>().loadSuppliers(search: v),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.suppliers.isEmpty
                    ? const Center(child: Text("No suppliers found.", style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: provider.suppliers.length,
                        itemBuilder: (context, index) => _SupplierCard(supplier: provider.suppliers[index]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final SupplierListing supplier;
  const _SupplierCard({required this.supplier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SupplierDetailScreen(supplierId: supplier.id))),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: const Icon(Icons.storefront, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              supplier.businessName.isNotEmpty ? supplier.businessName : supplier.username,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (supplier.isVerified) const Icon(Icons.verified, size: 16, color: AppColors.success),
                        ],
                      ),
                      if (supplier.address.isNotEmpty)
                        Text(supplier.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      RatingStars(rating: supplier.averageRating),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
