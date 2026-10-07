import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/pastel_button.dart';
import '../change_password_screen.dart';
import '../login_screen.dart';
import 'edit_profile_screen.dart';
import 'see_order_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to place an order.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (ok != true) return;
    await AuthService().signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (r) => false,
      );
    }
  }

  void _about(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About B.A.I.'),
        content: const Text('Barista Assistant Integration\nVersion 1.0.0'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Profile')),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: auth.profileStream(),
        builder: (context, snap) {
          final data = snap.data ?? {};
          final user = auth.currentUser;
          final name = (data['name'] as String?)?.trim().isNotEmpty == true
              ? data['name'] as String
              : (user?.displayName ?? 'Customer');
          final email = (data['email'] as String?) ?? user?.email ?? '';
          // Older accounts only have a single `name`; split it as a fallback.
          final parts = name.trim().split(RegExp(r'\s+'));
          final firstName = (data['firstName'] as String?) ?? (parts.isNotEmpty ? parts.first : '');
          final lastName =
              (data['lastName'] as String?) ?? (parts.length > 1 ? parts.sublist(1).join(' ') : '');
          final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: BaiColors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: BaiColors.butter,
                        child: Text(
                          initial,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: BaiColors.ink),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: BaiColors.ink),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(email, style: const TextStyle(color: Colors.black54)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                const _SectionLabel('Account'),
                _MenuTile(
                  icon: Icons.person_outline,
                  label: 'Edit profile',
                  color: BaiColors.butter,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditProfileScreen(
                        firstName: firstName, lastName: lastName, email: email)),
                  ),
                ),
                _MenuTile(
                  icon: Icons.lock_outline,
                  label: 'Change password',
                  color: BaiColors.mint,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  ),
                ),

                const SizedBox(height: 14),
                const _SectionLabel('Activity'),
                _MenuTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'My orders',
                  color: BaiColors.lavender,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SeeOrderScreen()),
                  ),
                ),

                const SizedBox(height: 14),
                const _SectionLabel('App'),
                _MenuTile(
                  icon: Icons.info_outline,
                  label: 'About B.A.I.',
                  color: Colors.white,
                  onTap: () => _about(context),
                ),

                const SizedBox(height: 22),
                PastelButton(
                  label: 'Log out',
                  icon: Icons.logout,
                  color: BaiColors.red,
                  shadowColor: BaiColors.pinkShadow,
                  onTap: () => _logOut(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.black45),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: BaiColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: BaiColors.ink, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: BaiColors.ink)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black38),
      ),
    );
  }
}