import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/user_model.dart';

class SidebarNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final UserModel user;

  const SidebarNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final items = _navItems(user.isAdmin);

    return Container(
      width: 240,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          // Logo / App name
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.accentDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      color: Colors.black, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lagos Store',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      Text('Inventory System',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              children: items.map((item) {
                final idx = items.indexOf(item);
                final isSelected = selectedIndex == idx;
                return _NavTile(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => onItemSelected(idx),
                );
              }).toList(),
            ),
          ),

          // User info + logout
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border:
                  Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.accent.withOpacity(0.15),
                  child: Text(
                    user.username[0].toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.username,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      Text(user.role.toUpperCase(),
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 10)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      context.read<AuthProvider>().logout(),
                  icon: const Icon(Icons.logout_rounded,
                      size: 18, color: AppColors.textSecondary),
                  tooltip: 'Logout',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_NavItem> _navItems(bool isAdmin) {
    return [
      _NavItem('Dashboard', Icons.dashboard_rounded, false),
      if (isAdmin) _NavItem('Products', Icons.inventory_2_rounded, false),
      if (isAdmin) _NavItem('Suppliers', Icons.local_shipping_rounded, false),
      if (isAdmin) _NavItem('Purchases', Icons.shopping_cart_rounded, false),
      _NavItem('Sales', Icons.point_of_sale_rounded, false),
      _NavItem('Inventory', Icons.warehouse_rounded, false),
      if (isAdmin) _NavItem('Reports', Icons.bar_chart_rounded, false),
      if (isAdmin) _NavItem('Settings', Icons.settings_rounded, false),
    ];
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final bool adminOnly;
  _NavItem(this.label, this.icon, this.adminOnly);
}

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTile(
      {required this.item, required this.isSelected, required this.onTap});

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected ? AppColors.accent : AppColors.textSecondary;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.sidebarSelected
                : _hovered
                    ? AppColors.sidebarHover
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: widget.isSelected
                ? Border.all(color: AppColors.border, width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(widget.item.icon, size: 18, color: color),
              const SizedBox(width: 12),
              Text(
                widget.item.label,
                style: TextStyle(
                  color: widget.isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
              if (widget.isSelected) ...[
                const Spacer(),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
