import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/procurement_request.dart';
import '../../providers/procurement_provider.dart';
import '../../widgets/status_chip.dart';
import '../customer/create_request_screen.dart';
import 'request_detail_screen.dart';

/// Shown as "My Requests" (customer), "Incoming Requests" (supplier — the
/// service already scopes to OPEN + ones they've quoted), or
/// "All Requests" (admin, read-only monitoring) — same list, same call,
/// ProcurementService does the role-scoping so this screen doesn't have to.
class RequestsListScreen extends StatefulWidget {
  final String title;
  final bool showCreateButton;

  const RequestsListScreen({super.key, required this.title, this.showCreateButton = false});

  @override
  State<RequestsListScreen> createState() => _RequestsListScreenState();
}

class _RequestsListScreenState extends State<RequestsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ProcurementProvider>().loadRequests());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProcurementProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: widget.showCreateButton
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
                );
                if (created == true && context.mounted) context.read<ProcurementProvider>().loadRequests();
              },
              icon: const Icon(Icons.add),
              label: const Text("New Request"),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => context.read<ProcurementProvider>().loadRequests(),
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(ProcurementProvider provider) {
    if (provider.loading && provider.requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.requests.isEmpty) {
      return _ErrorState(message: provider.error!, onRetry: () => provider.loadRequests());
    }
    if (provider.requests.isEmpty) {
      return const _EmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      itemCount: provider.requests.length,
      itemBuilder: (context, index) => _RequestCard(request: provider.requests[index]),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ProcurementRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final statusApi = requestStatusToApiString(request.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: request.id)),
        ),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${request.vehicleMake} ${request.vehicleModel} (${request.vehicleYear})",
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    StatusChip(label: requestStatusLabel(request.status), color: requestStatusColor(statusApi)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  request.items.map((i) => i.partName).join(", "),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: _urgencyColor(request.urgency)),
                    const SizedBox(width: 5),
                    Text(urgencyLabel(request.urgency), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const Spacer(),
                    Text(DateFormat.yMMMd().format(request.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _urgencyColor(RequestUrgency u) {
    switch (u) {
      case RequestUrgency.urgent:
        return AppColors.error;
      case RequestUrgency.high:
        return AppColors.warning;
      case RequestUrgency.normal:
        return AppColors.primary;
      case RequestUrgency.low:
        return AppColors.textSecondary;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text("Nothing here yet", style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text("New procurement requests will show up here.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text("Retry")),
          ],
        ),
      ),
    );
  }
}
