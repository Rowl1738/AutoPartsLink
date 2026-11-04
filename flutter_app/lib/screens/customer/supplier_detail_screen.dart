import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rating.dart';
import '../../models/supplier_listing.dart';
import '../../repositories/supplier_repository.dart';
import '../../widgets/rating_stars.dart';

class SupplierDetailScreen extends StatefulWidget {
  final String supplierId;
  const SupplierDetailScreen({super.key, required this.supplierId});

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  final _repository = SupplierRepository();
  SupplierListing? _supplier;
  List<Rating> _ratings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _repository.getSupplier(widget.supplierId),
      _repository.getSupplierRatings(widget.supplierId),
    ]);
    if (!mounted) return;
    setState(() {
      _supplier = results[0] as SupplierListing;
      _ratings = results[1] as List<Rating>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Supplier Profile")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _supplier == null
              ? const Center(child: Text("Supplier not found."))
              : _buildBody(_supplier!),
    );
  }

  Widget _buildBody(SupplierListing supplier) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: const Icon(Icons.storefront, size: 30, color: AppColors.primary),
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
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (supplier.isVerified) const Icon(Icons.verified, size: 18, color: AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RatingStars(rating: supplier.averageRating, size: 18),
                ],
              ),
            ),
          ],
        ),
        if (supplier.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(supplier.description),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (supplier.address.isNotEmpty) _infoRow(Icons.location_on_outlined, supplier.address),
                if (supplier.operatingHours.isNotEmpty) _infoRow(Icons.access_time, supplier.operatingHours),
                if (supplier.phone.isNotEmpty) _infoRow(Icons.phone_outlined, supplier.phone),
                if (supplier.website.isNotEmpty) _infoRow(Icons.language_outlined, supplier.website),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text("Ratings & Reviews (${_ratings.length})", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        if (_ratings.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text("No reviews yet.", style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          ..._ratings.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(r.customerName, style: const TextStyle(fontWeight: FontWeight.w600))),
                          RatingStars(rating: r.score.toDouble(), size: 14),
                        ],
                      ),
                      if (r.review?.title.isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        Text(r.review!.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                      if (r.review?.body.isNotEmpty == true) Text(r.review!.body, style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(DateFormat.yMMMd().format(r.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
        ],
      ),
    );
  }
}
