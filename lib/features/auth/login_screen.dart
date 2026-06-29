import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    await auth.login(_usernameCtrl.text, _passwordCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left panel — branding
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF080C16), Color(0xFF0D1829)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -80,
                    left: -80,
                    child: _circle(320, AppColors.accent.withOpacity(0.06)),
                  ),
                  Positioned(
                    bottom: -100,
                    right: -60,
                    child: _circle(280, AppColors.accentDark.withOpacity(0.08)),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.accent,
                                  AppColors.accentDark
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.storefront_rounded,
                                color: Colors.black, size: 32),
                          ),
                          const SizedBox(height: 32),
                          Text('Lagos Store',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1)),
                          const SizedBox(height: 12),
                          Text(
                            'Inventory Management\nSystem — v1.0',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                                height: 1.5),
                          ),
                          const SizedBox(height: 48),
                          _featurePill(Icons.inventory_2_rounded,
                              'Track stock in Packs & Pieces'),
                          const SizedBox(height: 12),
                          _featurePill(Icons.point_of_sale_rounded,
                              'Wholesale & Retail Sales'),
                          const SizedBox(height: 12),
                          _featurePill(Icons.bar_chart_rounded,
                              'Reports & Excel Export'),
                          const SizedBox(height: 12),
                          _featurePill(Icons.wifi_off_rounded,
                              '100% Offline — No internet needed'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right panel — login form
          Container(
            width: 460,
            color: AppColors.surface,
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5)),
                          const SizedBox(height: 8),
                          Text('Sign in to your account',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14)),
                          const SizedBox(height: 36),

                          AppTextField(
                            controller: _usernameCtrl,
                            label: 'Username',
                            hint: 'Enter your username',
                            autofocus: true,
                            prefixIcon: const Icon(Icons.person_outline),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Username required'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          AppTextField(
                            controller: _passwordCtrl,
                            label: 'Password',
                            hint: 'Enter your password',
                            obscureText: _obscure,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Password required'
                                : null,
                          ),
                          const SizedBox(height: 8),

                          if (auth.error != null) ...[
                            SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.errorBg,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: AppColors.error.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: AppColors.error, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(auth.error!,
                                        style: const TextStyle(
                                            color: AppColors.error,
                                            fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _login,
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black))
                                  : const Text('Sign In'),
                            ),
                          ),

                          SizedBox(height: 36),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(10),
                              border: AppColors.isDark ? Border.all(color: AppColors.border) : null,
                              boxShadow: AppColors.cardShadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Default credentials',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                                SizedBox(height: 8),
                                _CredRow('Admin', 'admin', 'admin123'),
                                SizedBox(height: 4),
                                _CredRow('Staff', 'staff', 'staff123'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _featurePill(IconData icon, String text) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accentGlow,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: AppColors.accent),
          ),
          SizedBox(width: 12),
          Text(text,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      );
}

class _CredRow extends StatelessWidget {
  final String role;
  final String username;
  final String password;

  const _CredRow(this.role, this.username, this.password);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$role: ',
            style: TextStyle(
                color: AppColors.textMuted, fontSize: 12)),
        Text('$username / $password',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontFamily: 'monospace')),
      ],
    );
  }
}
