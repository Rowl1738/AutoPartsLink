import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/platform_stats.dart';
import '../../providers/reports_provider.dart';
import '../../widgets/charts/column_chart.dart';
import '../../widgets/charts/meter_list.dart';
import '../../widgets/charts/stat_tile.dart';
import '../../widgets/section_label.dart';

final _count = NumberFormat.decimalPattern();
final _compact = NumberFormat.compact();
String _money(double v) => "K${NumberFormat("#,##0.00").format(v)}";
String _moneyShort(double v) => "K${NumberFormat("#,##0").format(v)}";
String _countOf(double v) => _count.format(v.round());

enum _Metric { requests, orders, value }

extension on _Metric {
  String get label => switch (this) {
        _Metric.requests => "Requests",
        _Metric.orders => "Orders",
        _Metric.value => "Order value",
      };
}

/// Admin "Reports & Statistics": headline numbers, a monthly activity trend
/// and status / supplier breakdowns across the whole platform.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _Metric _metric = _Metric.requests;
  bool _showTable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ReportsProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportsProvider>();
    final stats = provider.stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports & Statistics"),
        actions: [
          IconButton(
            tooltip: "Refresh",
            icon: const Icon(Icons.refresh),
            onPressed: provider.loading ? null : () => context.read<ReportsProvider>().load(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ReportsProvider>().load(),
        child: stats == null
            ? ListView(
                children: [
                  SizedBox(
                    height: 400,
                    child: Center(
                      child: provider.loading
                          ? const CircularProgressIndicator()
                          : Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(provider.error ?? "No data yet.",
                                  textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                            ),
                    ),
                  ),
                ],
              )
            : _content(stats, provider),
      ),
    );
  }

  Widget _content(PlatformStats s, ReportsProvider provider) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (provider.loading) const LinearProgressIndicator(minHeight: 2),
        if (provider.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(provider.error!, style: const TextStyle(color: AppColors.error)),
          ),
        const SectionLabel("Overview"),
        _pair(
          StatTile(
            icon: Icons.payments_outlined,
            label: "Order value",
            value: _moneyShort(s.orderValue),
            caption: "Avg ${_moneyShort(s.averageOrderValue)} per order",
          ),
          StatTile(
            icon: Icons.local_shipping_outlined,
            label: "Orders",
            value: _countOf(s.totalOrders.toDouble()),
            caption: "${_countOf(s.completedOrders.toDouble())} completed",
            accent: AppColors.secondary,
          ),
        ),
        _pair(
          StatTile(
            icon: Icons.assignment_outlined,
            label: "Requests",
            value: _countOf(s.totalRequests.toDouble()),
            caption: "${_countOf(s.openRequests.toDouble())} taking quotations",
            accent: AppColors.secondary,
          ),
          StatTile(
            icon: Icons.request_quote_outlined,
            label: "Quote acceptance",
            value: "${(s.acceptanceRate * 100).round()}%",
            caption: "${s.acceptedQuotations} of ${s.totalQuotations} quotations",
          ),
        ),
        _pair(
          StatTile(
            icon: Icons.people_outline,
            label: "Customers",
            value: _countOf(s.customers.toDouble()),
            caption: s.deactivatedUsers > 0 ? "${s.deactivatedUsers} deactivated accounts" : "All accounts active",
          ),
          StatTile(
            icon: Icons.storefront_outlined,
            label: "Suppliers",
            value: _countOf(s.suppliers.toDouble()),
            caption: s.pendingSuppliers > 0 ? "${s.pendingSuppliers} awaiting approval" : "All approved",
            accent: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 12),
        const SectionLabel("Activity"),
        _activityCard(s),
        const SizedBox(height: 20),
        const SectionLabel("Orders by status"),
        _card(
          s.totalOrders == 0
              ? _empty("No orders yet.")
              : MeterList(items: s.ordersByStatus, format: _countOf, shareOf: s.totalOrders.toDouble()),
        ),
        const SizedBox(height: 20),
        const SectionLabel("Requests by status"),
        _card(
          s.totalRequests == 0
              ? _empty("No procurement requests yet.")
              : MeterList(items: s.requestsByStatus, format: _countOf, shareOf: s.totalRequests.toDouble()),
        ),
        const SizedBox(height: 20),
        const SectionLabel("Top suppliers by order value"),
        _card(
          s.topSuppliers.isEmpty
              ? _empty("No supplier sales yet.")
              : MeterList(items: s.topSuppliers, format: _money, color: AppColors.secondary),
        ),
      ],
    );
  }

  Widget _activityCard(PlatformStats s) {
    final labels = s.monthly.map((m) => DateFormat.MMM().format(m.month)).toList();
    final values = s.monthly
        .map((m) => switch (_metric) {
              _Metric.requests => m.requests.toDouble(),
              _Metric.orders => m.orders.toDouble(),
              _Metric.value => m.orderValue,
            })
        .toList();
    final isMoney = _metric == _Metric.value;
    final format = isMoney ? _moneyShort : _countOf;
    final total = values.fold<double>(0, (a, b) => a + b);
    final first = DateFormat.yMMM().format(s.monthly.first.month);
    final last = DateFormat.yMMM().format(s.monthly.last.month);

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<_Metric>(
              segments: [for (final m in _Metric.values) ButtonSegment(value: m, label: Text(m.label))],
              selected: {_metric},
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              onSelectionChanged: (v) => setState(() => _metric = v.first),
            ),
          ),
          const SizedBox(height: 16),
          Text("${_metric.label} per month", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 2),
          Text("$first – $last · ${format(total)} in total",
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          if (total == 0)
            SizedBox(height: 120, child: _empty("No activity in the last ${s.monthly.length} months."))
          else
            ColumnChart(
              key: ValueKey(_metric), // reset the selection when the metric changes
              labels: labels,
              values: values,
              format: format,
              axisFormat: (v) => isMoney ? "K${_compact.format(v)}" : _compact.format(v),
              seriesName: _metric.label,
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _showTable = !_showTable),
              icon: Icon(_showTable ? Icons.expand_less : Icons.table_rows_outlined, size: 18),
              label: Text(_showTable ? "Hide table" : "Show as table"),
            ),
          ),
          if (_showTable) _activityTable(s),
        ],
      ),
    );
  }

  Widget _activityTable(PlatformStats s) {
    const head = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary);
    const cell = TextStyle(fontSize: 13, color: AppColors.textPrimary);
    TableRow row(List<String> cells, TextStyle style) => TableRow(children: [
          for (var i = 0; i < cells.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(cells[i], style: style, textAlign: i == 0 ? TextAlign.left : TextAlign.right),
            ),
        ]);

    return Table(
      columnWidths: const {0: FlexColumnWidth(1.2)},
      border: const TableBorder(horizontalInside: BorderSide(color: AppColors.border)),
      children: [
        row(const ["Month", "Requests", "Orders", "Value"], head),
        for (final m in s.monthly)
          row([
            DateFormat.yMMM().format(m.month),
            _countOf(m.requests.toDouble()),
            _countOf(m.orders.toDouble()),
            _moneyShort(m.orderValue),
          ], cell),
      ],
    );
  }

  Widget _pair(Widget a, Widget b) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: a), const SizedBox(width: 10), Expanded(child: b)],
          ),
        ),
      );

  Widget _card(Widget child) => Card(child: Padding(padding: const EdgeInsets.all(16), child: child));

  Widget _empty(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
        ),
      );
}
