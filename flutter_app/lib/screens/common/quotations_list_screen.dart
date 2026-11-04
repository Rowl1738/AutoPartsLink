import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/firestore_parsing.dart';
import '../../models/quotation.dart';
import '../../providers/quotation_provider.dart';
import '../../widgets/status_chip.dart';
import 'request_detail_screen.dart';

/// "My Quotations" (supplier) / "All Quotations" (admin) — QuotationService
/// already scopes the query to the caller's role.
class QuotationsListScreen extends StatefulWidget {
  const QuotationsListScreen({super.key});

  @override
  State<QuotationsListScreen> createState() => _QuotationsListScreenState();
}

class _QuotationsListScreenState extends State<QuotationsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<QuotationProvider>().loadQuotations());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotationProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text("My Quotations")),
      body: RefreshIndicator(
        onRefresh: () => context.read<QuotationProvider>().loadQuotations(),
        child: provider.loading && provider.quotations.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : provider.quotations.isEmpty
                ? ListView(children: const [
                    Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.request_quote_outlined, size: 56, color: AppColors.textSecondary),
                            SizedBox(height: 12),
                            Text("No quotations submitted yet", style: TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: provider.quotations.length,
                    itemBuilder: (context, index) => _QuotationRow(quotation: provider.quotations[index]),
                  ),
      ),
    );
  }
}

class _QuotationRow extends StatelessWidget {
  final Quotation quotation;
  const _QuotationRow({required this.quotation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: quotation.requestId)),
        ),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text("Request #${shortRef(quotation.requestId)}", style: const TextStyle(fontWeight: FontWeight.w700))),
                    StatusChip(label: quotationStatusLabel(quotation.status), color: quotationStatusColor(quotation.status.name.toUpperCase())),
                  ],
                ),
                const SizedBox(height: 6),
                Text(quotation.items.map((i) => i.partName).join(", "),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(DateFormat.yMMMd().format(quotation.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const Spacer(),
                    Text("K${quotation.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w700)),
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
