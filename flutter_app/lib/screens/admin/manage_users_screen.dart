import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user.dart';
import '../../providers/admin_provider.dart';

class ManageUsersScreen extends StatefulWidget {
  /// Which tab to open on — "CUSTOMER" or "SUPPLIER".
  final String initialRole;
  const ManageUsersScreen({super.key, this.initialRole = "CUSTOMER"});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2, vsync: this, initialIndex: widget.initialRole == "SUPPLIER" ? 1 : 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AdminProvider>().loadUsers());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Users"),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: "Customers"), Tab(text: "Suppliers")]),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminProvider>().loadUsers(),
        child: Consumer<AdminProvider>(
          builder: (context, provider, _) {
            if (provider.loading && provider.users.isEmpty) return const Center(child: CircularProgressIndicator());
            return TabBarView(
              controller: _tabController,
              children: [
                _UserList(users: provider.customers, isSupplierTab: false),
                _UserList(users: provider.suppliers, isSupplierTab: true),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<AppUser> users;
  final bool isSupplierTab;
  const _UserList({required this.users, required this.isSupplierTab});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return ListView(children: [
        Padding(
          padding: const EdgeInsets.all(48),
          child: Center(
            child: Text("No ${isSupplierTab ? 'suppliers' : 'customers'} yet.", style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ),
      ]);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: users.length,
      itemBuilder: (context, index) => _UserCard(user: users[index]),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final needsApproval = user.role == UserRole.supplier && !user.isApproved;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : "?", style: const TextStyle(color: AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.username, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(user.email, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (!user.isActive)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.block, size: 16, color: AppColors.error),
                  ),
                Switch(
                  value: user.isActive,
                  onChanged: (v) => context.read<AdminProvider>().setActive(user.id, v),
                ),
              ],
            ),
            if (needsApproval) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.read<AdminProvider>().approveSupplier(user.id),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text("Approve Supplier"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
