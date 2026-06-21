import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/page_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadUsers();
    });
  }

  Future<void> _backupDatabase(BuildContext context) async {
    try {
      final dbPath = await DatabaseHelper().getDatabasePath();
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Database Backup',
        fileName:
            'lagos_store_backup_${DateTime.now().millisecondsSinceEpoch}.db',
        type: FileType.any,
      );
      if (savePath != null) {
        await File(dbPath).copy(savePath);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database backed up successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final currentUser = context.read<AuthProvider>().currentUser!;
    final users = dash.users;

    return Column(
      children: [
        const PageHeader(
          title: 'Settings',
          subtitle: 'Manage users and system data',
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── User Management ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User Management',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text('Add, edit, or remove system users',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showUserForm(context),
                      icon: const Icon(Icons.person_add_outlined, size: 16),
                      label: const Text('Add User'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: dash.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.accent),
                            ),
                          )
                        : Table(
                            columnWidths: const {
                              0: FixedColumnWidth(50),
                              1: FlexColumnWidth(2),
                              2: FlexColumnWidth(1.5),
                              3: FlexColumnWidth(1.5),
                              4: FixedColumnWidth(120),
                            },
                            children: [
                              _header(),
                              ...users.asMap().entries.map((e) =>
                                  _userRow(context, e.value, e.key,
                                      currentUser)),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 40),

                // ── Database Backup ──
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.infoBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.backup_rounded,
                            color: AppColors.info, size: 24),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Database Backup',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text(
                              'Copy the SQLite database file to a safe location. '
                              'Recommended: backup weekly or before major changes.',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: () => _backupDatabase(context),
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Backup Now'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── App Info ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Application Info',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      _infoRow('App Name', 'Lagos Store Inventory System'),
                      _infoRow('Version', 'v1.0.0'),
                      _infoRow('Database', 'SQLite (local, offline)'),
                      _infoRow('Current User',
                          '${currentUser.username} (${currentUser.role})'),
                      _infoRow('Date', formatDate(DateTime.now())),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  TableRow _header() => TableRow(
        decoration: const BoxDecoration(color: AppColors.surface),
        children: ['#', 'Username', 'Role', 'Created', 'Actions']
            .map((c) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Text(c,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4)),
                ))
            .toList(),
      );

  TableRow _userRow(BuildContext context, UserModel user, int index,
      UserModel currentUser) {
    final bg = index.isEven ? AppColors.card : AppColors.cardHover;
    final isSelf = user.id == currentUser.id;
    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
        _cell('${index + 1}', muted: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: user.isAdmin
                    ? AppColors.accent.withOpacity(0.15)
                    : AppColors.infoBg,
                child: Text(
                  user.username[0].toUpperCase(),
                  style: TextStyle(
                      color:
                          user.isAdmin ? AppColors.accent : AppColors.info,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.username,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  if (isSelf)
                    const Text('(you)',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: user.isAdmin ? AppColors.accentGlow : AppColors.infoBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              user.role.toUpperCase(),
              style: TextStyle(
                  color:
                      user.isAdmin ? AppColors.accent : AppColors.info,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
        _cell(formatDate(user.createdAt)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _iconBtn(Icons.edit_outlined, AppColors.info,
                  () => _showUserForm(context, user: user)),
              const SizedBox(width: 6),
              _iconBtn(
                Icons.delete_outline,
                isSelf ? AppColors.textMuted : AppColors.error,
                isSelf
                    ? null
                    : () => _confirmDelete(context, user),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(String text, {bool muted = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(text,
            style: TextStyle(
                color: muted ? AppColors.textMuted : AppColors.textPrimary,
                fontSize: 13)),
      );

  Widget _iconBtn(IconData icon, Color color, VoidCallback? onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 15, color: color),
        ),
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ),
            Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );

  void _showUserForm(BuildContext context, {UserModel? user}) {
    showDialog(
      context: context,
      builder: (_) => _UserFormDialog(user: user),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, UserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Delete user "${user.username}"? They will no longer be able to log in.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<DashboardProvider>().deleteUser(user.id!);
    }
  }
}

// ─────────────────── User Form Dialog ───────────────────

class _UserFormDialog extends StatefulWidget {
  final UserModel? user;
  const _UserFormDialog({this.user});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _username;
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _role = 'staff';
  bool _saving = false;
  bool _obscure = true;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    _username =
        TextEditingController(text: widget.user?.username ?? '');
    _role = widget.user?.role ?? 'staff';
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final dash = context.read<DashboardProvider>();
      if (_isEdit) {
        await dash.updateUser(
          widget.user!.id!,
          username: _username.text.trim(),
          rawPassword:
              _password.text.isNotEmpty ? _password.text : null,
          role: _role,
        );
      } else {
        await dash.createUser(
          _username.text.trim(),
          _password.text,
          _role,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    _isEdit ? 'Edit User' : 'Add New User',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 24),

                AppTextField(
                  controller: _username,
                  label: 'Username *',
                  autofocus: true,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                AppDropdown<String>(
                  value: _role,
                  label: 'Role *',
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                  ],
                  onChanged: (v) => setState(() => _role = v!),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _password,
                  label: _isEdit
                      ? 'New Password (leave blank to keep)'
                      : 'Password *',
                  obscureText: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) {
                    if (!_isEdit && (v == null || v.isEmpty)) {
                      return 'Password is required';
                    }
                    if (v != null && v.isNotEmpty && v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _confirm,
                  label: 'Confirm Password',
                  obscureText: _obscure,
                  validator: (v) {
                    if (_password.text.isNotEmpty && v != _password.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : Text(_isEdit ? 'Save Changes' : 'Create User'),
                    ),
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
