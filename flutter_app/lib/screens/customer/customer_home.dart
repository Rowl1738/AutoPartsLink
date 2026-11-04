import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/nav_tile.dart';
import '../../widgets/section_label.dart';
import '../common/orders_list_screen.dart';
import '../common/requests_list_screen.dart';
import 'find_suppliers_screen.dart';

class CustomerHome extends StatelessWidget {
  const CustomerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final subtitle = user?.customerProfile?.companyName.isNotEmpty == true
        ? user!.customerProfile!.companyName
        : "Customer account";

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          DashboardHeader(greetingName: user?.username ?? "", subtitle: subtitle, icon: Icons.person_outline),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel("Procurement"),
                NavTile(
                  icon: Icons.list_alt_outlined,
                  title: "My Requests",
                  subtitle: "Create requests and view received quotations",
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const RequestsListScreen(title: "My Requests", showCreateButton: true),
                  )),
                ),
                const SizedBox(height: 8),
                const SectionLabel("Suppliers"),
                NavTile(
                  icon: Icons.storefront_outlined,
                  title: "Find Suppliers",
                  subtitle: "Search and discover suppliers",
                  accent: AppColors.secondary,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FindSuppliersScreen())),
                ),
                const SizedBox(height: 8),
                const SectionLabel("Orders"),
                NavTile(
                  icon: Icons.local_shipping_outlined,
                  title: "Active Orders",
                  subtitle: "Track order status",
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => OrdersListScreen(
                      title: "Active Orders",
                      filter: (o) => o.status != OrderStatus.completed && o.status != OrderStatus.cancelled,
                    ),
                  )),
                ),
                NavTile(
                  icon: Icons.history,
                  title: "Order History",
                  subtitle: "Past orders and receipts",
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => OrdersListScreen(
                      title: "Order History",
                      filter: (o) => o.status == OrderStatus.completed || o.status == OrderStatus.cancelled,
                    ),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
