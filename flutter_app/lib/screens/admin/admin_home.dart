import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/nav_tile.dart';
import '../../widgets/section_label.dart';
import '../common/orders_list_screen.dart';
import '../common/quotations_list_screen.dart';
import '../common/requests_list_screen.dart';
import 'manage_users_screen.dart';
import 'reports_screen.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          DashboardHeader(
            greetingName: user?.username ?? "",
            subtitle: "Administrator",
            icon: Icons.admin_panel_settings_outlined,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel("User Management"),
                NavTile(
                  icon: Icons.people_outline,
                  title: "Manage Customers",
                  subtitle: "View and manage customer accounts",
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ManageUsersScreen(initialRole: "CUSTOMER"),
                  )),
                ),
                NavTile(
                  icon: Icons.storefront_outlined,
                  title: "Manage Suppliers",
                  subtitle: "Approve, verify and suspend suppliers",
                  accent: AppColors.secondary,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ManageUsersScreen(initialRole: "SUPPLIER"),
                  )),
                ),
                const SizedBox(height: 8),
                const SectionLabel("Monitoring"),
                NavTile(
                  icon: Icons.assignment_outlined,
                  title: "Procurement Requests",
                  subtitle: "All requests across the platform",
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const RequestsListScreen(title: "All Procurement Requests"),
                  )),
                ),
                NavTile(
                  icon: Icons.request_quote_outlined,
                  title: "Quotations",
                  subtitle: "All submitted quotations",
                  accent: AppColors.secondary,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuotationsListScreen())),
                ),
                NavTile(
                  icon: Icons.local_shipping_outlined,
                  title: "Orders",
                  subtitle: "All orders and their status",
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const OrdersListScreen(title: "All Orders"),
                  )),
                ),
                const SizedBox(height: 8),
                const SectionLabel("Insights"),
                NavTile(
                  icon: Icons.bar_chart_outlined,
                  title: "Reports & Statistics",
                  subtitle: "Platform activity at a glance",
                  accent: AppColors.secondary,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
