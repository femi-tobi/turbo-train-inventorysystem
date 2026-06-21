import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/page_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final user = context.read<AuthProvider>().currentUser!;
    final now = DateTime.now();

    return Column(
      children: [
        PageHeader(
          title: 'Dashboard',
          subtitle: 'Welcome back, ${user.username}  •  ${formatDate(now)}',
          actions: [
            IconButton(
              onPressed: () => dash.loadStats(),
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.textSecondary),
              tooltip: 'Refresh',
            ),
          ],
        ),
        Expanded(
          child: dash.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Stats Grid ──
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.55,
                        children: [
                          StatCard(
                            label: 'Total Products',
                            value: formatNumber(dash.productCount),
                            icon: Icons.inventory_2_rounded,
                            accentColor: AppColors.info,
                          ),
                          StatCard(
                            label: 'Total Brands',
                            value: formatNumber(dash.brandCount),
                            icon: Icons.label_rounded,
                            accentColor: const Color(0xFF8B5CF6),
                          ),
                          StatCard(
                            label: 'Total Stock',
                            value: '${formatNumber(dash.totalStockPacks)} Packs',
                            icon: Icons.warehouse_rounded,
                            accentColor: AppColors.accent,
                          ),
                          StatCard(
                            label: 'Inventory Value',
                            value: formatNaira(dash.totalInventoryValue),
                            icon: Icons.account_balance_wallet_rounded,
                            accentColor: AppColors.accentLight,
                          ),
                          StatCard(
                            label: "Today's Sales",
                            value: formatNaira(dash.todaySales),
                            icon: Icons.today_rounded,
                            accentColor: const Color(0xFFF59E0B),
                          ),
                          StatCard(
                            label: 'This Month Sales',
                            value: formatNaira(dash.monthSales),
                            icon: Icons.calendar_month_rounded,
                            accentColor: const Color(0xFFEC4899),
                          ),
                          StatCard(
                            label: 'Gross Profit (Month)',
                            value: formatNaira(dash.monthProfit),
                            icon: Icons.trending_up_rounded,
                            accentColor: AppColors.success,
                          ),
                          StatCard(
                            label: 'Low Stock Items',
                            value: formatNumber(dash.lowStockCount),
                            icon: Icons.warning_amber_rounded,
                            accentColor: AppColors.warning,
                            subtitle: '${dash.outOfStockCount} out of stock',
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // ── Recent Sales ──
                      const Text('Recent Transactions',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 14),

                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: dash.recentSales.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(40),
                                child: Center(
                                  child: Text('No transactions yet',
                                      style: TextStyle(
                                          color: AppColors.textMuted)),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Table(
                                  columnWidths: const {
                                    0: FlexColumnWidth(2),
                                    1: FlexColumnWidth(3),
                                    2: FlexColumnWidth(1.5),
                                    3: FlexColumnWidth(2),
                                    4: FlexColumnWidth(2),
                                  },
                                  children: [
                                    TableRow(
                                      decoration: const BoxDecoration(
                                          color: AppColors.surface),
                                      children: ['Date', 'Product', 'Type', 'Amount', 'Profit']
                                          .map((h) => Padding(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12),
                                                child: Text(h,
                                                    style: const TextStyle(
                                                        color: AppColors.textSecondary,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        letterSpacing: 0.5)),
                                              ))
                                          .toList(),
                                    ),
                                    ...dash.recentSales
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final i = entry.key;
                                      final s = entry.value;
                                      final isWholesale =
                                          s['sale_type'] == 'wholesale';
                                      final bg = i.isEven
                                          ? AppColors.card
                                          : AppColors.cardHover;
                                      return TableRow(
                                        decoration:
                                            BoxDecoration(color: bg),
                                        children: [
                                          _cell(formatDate(DateTime.parse(
                                              s['sale_date'] as String))),
                                          _cell(
                                              s['product_name'] as String? ??
                                                  '—'),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isWholesale
                                                    ? AppColors.infoBg
                                                    : AppColors.successBg,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isWholesale
                                                    ? 'Wholesale'
                                                    : 'Retail',
                                                style: TextStyle(
                                                  color: isWholesale
                                                      ? AppColors.info
                                                      : AppColors.success,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          _cell(formatNaira(
                                              (s['total_amount'] as num)
                                                  .toDouble())),
                                          _cell(formatNaira(
                                              (s['gross_profit'] as num)
                                                  .toDouble())),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _cell(String text) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13)),
      );
}
