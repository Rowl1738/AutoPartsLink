import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/nav_tile.dart';
import '../../widgets/section_label.dart';
import '../common/orders_list_screen.dart';
import '../common/quotations_list_screen.dart';
import '../common/requests_list_screen.dart';
import 'business_profile_screen.dart';
import 'my_ratings_screen.dart';

class SupplierHome extends StatelessWidget {
  const SupplierHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final pendingApproval = user != null && !user.isApproved;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          DashboardHeader(
            greetingName: user?.username ?? "",
            subtitle: pendingApproval ? "Pending approval" : "Supplier account",
            icon: Icons.storefront_outlined,
          ),
          if (pendingApproval) const _PendingApprovalNotice() else const _SupplierDashboardBody(),
        ],
      ),
    );
  }
}

class _PendingApprovalNotice extends StatelessWidget {
  const _PendingApprovalNotice();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(28, 40, 28, 24),
      child: Column(
        children: [
          Icon(Icons.hourglass_top_outlined, size: 56, color: AppColors.warning),
          SizedBox(height: 16),
          Text("Pending admin approval", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text(
            "Your supplier account needs to be approved before you can browse requests and submit quotations. "
            "This usually only takes a short while.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SupplierDashboardBody extends StatelessWidget {
  const _SupplierDashboardBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel("Requests & Quotations"),
          NavTile(
            icon: Icons.inbox_outlined,
            title: "Incoming Requests",
            subtitle: "Requests you can quote on",
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const RequestsListScreen(title: "Incoming Requests"),
            )),
          ),
          NavTile(
            icon: Icons.request_quote_outlined,
            title: "My Quotations",
            subtitle: "Submitted and accepted quotes",
            accent: AppColors.secondary,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuotationsListScreen())),
          ),
          const SizedBox(height: 8),
          const SectionLabel("Orders"),
          NavTile(
            icon: Icons.local_shipping_outlined,
            title: "Orders Received",
            subtitle: "Update order status",
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => OrdersListScreen(title: "Orders Received", filter: (o) => o.status != OrderStatus.completed),
            )),
          ),
          NavTile(
            icon: Icons.check_circle_outline,
            title: "Completed Orders",
            subtitle: "Fulfilled order history",
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => OrdersListScreen(title: "Completed Orders", filter: (o) => o.status == OrderStatus.completed),
            )),
          ),
          const SizedBox(height: 8),
          const SectionLabel("Business"),
          NavTile(
            icon: Icons.star_outline,
            title: "Ratings & Reviews",
            subtitle: "See what customers say",
            accent: AppColors.secondary,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyRatingsScreen())),
          ),
          NavTile(
            icon: Icons.storefront_outlined,
            title: "Business Profile",
            subtitle: "Business name, location, hours",
            accent: AppColors.secondary,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BusinessProfileScreen())),
          ),
        ],
      ),
    );
  }
}
