import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../widgets/home_action_grid.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';
import '../change_password_screen.dart';
import 'kitchen_screen.dart';
import 'inventory_screen.dart';
import 'payments_screen.dart';
import 'edit_menu_screen.dart';
import 'subscription_screen.dart';
import 'sales_summary_screen.dart';
import 'due_payments_screen.dart';

class StaffHomeScreen extends StatelessWidget {
  const StaffHomeScreen({super.key});

  Future<void> _logOut(BuildContext context) async {
    await AuthService().signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (r) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      body: StreamBuilder<SubscriptionStatus>(
        stream: fs.subscriptionStatus(),
        builder: (context, subSnap) {
          final isActive = subSnap.data?.isActive ?? true; // assume active while loading

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/wooden_table_bg.png', fit: BoxFit.cover),
              SafeArea(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.lock_outline, color: Colors.white),
                        tooltip: 'Change password',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                        ),
                      ),
                    ),
                    if (!isActive)
                      Expanded(child: _ExpiredView(onLogOut: () => _logOut(context)))
                    else ...[
                      const SizedBox(height: 4),
                      const Text('Welcome, Barista!', textAlign: TextAlign.center, style: baiHeading),
                      const SizedBox(height: 4),
                      const Text("What's brewing today?", style: TextStyle(color: Colors.white, fontSize: 15)),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: HomeActionGrid(cells: [
                            const GridCell.decor('assets/images/cup_mascot.gif'),
                            const GridCell.decor('assets/images/cookie_decor.gif'),
                            GridCell.button(
                              icon: Icons.assignment_outlined,
                              label: 'View orders',
                              color: BaiColors.butter,
                              onTap: () => Navigator.push(
                                  context, MaterialPageRoute(builder: (_) => const KitchenScreen())),
                            ),
                            GridCell.button(
                              icon: Icons.inventory_2_outlined,
                              label: 'View inventory',
                              color: BaiColors.mint,
                              onTap: () => Navigator.push(
                                  context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
                            ),
                            GridCell.button(
                              icon: Icons.payments_outlined,
                              label: 'Manage payment',
                              color: BaiColors.pink,
                              onTap: () => Navigator.push(
                                  context, MaterialPageRoute(builder: (_) => const PaymentsScreen())),
                            ),
                            GridCell.button(
                              icon: Icons.edit_note_outlined,
                              label: 'Edit menu',
                              color: BaiColors.lavender,
                              onTap: () => Navigator.push(
                                  context, MaterialPageRoute(builder: (_) => const EditMenuScreen())),
                            ),
                            GridCell.button(
                              icon: Icons.bar_chart_outlined,
                              label: 'Sales summary',
                              color: BaiColors.mint,
                              onTap: () => Navigator.push(
                                  context, MaterialPageRoute(builder: (_) => const SalesSummaryScreen())),
                            ),
                            GridCell.button(
                              icon: Icons.account_balance_wallet_outlined,
                              label: 'Due payments',
                              color: BaiColors.butter,
                              onTap: () => Navigator.push(
                                  context, MaterialPageRoute(builder: (_) => const DuePaymentsScreen())),
                            ),
                            const GridCell.decor('assets/images/cup_mascot.gif'),
                            const GridCell.decor('assets/images/cookie_decor.gif'),
                          ]),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: TextButton.icon(
                          icon: const Icon(Icons.workspace_premium_outlined, size: 16, color: Colors.white),
                          label: const Text('Subscription', style: TextStyle(color: Colors.white)),
                          onPressed: () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: TextButton(
                        onPressed: () => _logOut(context),
                        child: const Text('Log out', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExpiredView extends StatelessWidget {
  final VoidCallback onLogOut;
  const _ExpiredView({required this.onLogOut});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_clock_outlined, size: 44, color: Color(0xFFC1554A)),
            const SizedBox(height: 10),
            const Text('Subscription Expired', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 6),
            const Text(
              'Please renew to continue receiving orders.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BaiColors.mint,
                foregroundColor: BaiColors.ink,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
              child: const Text('Renew Subscription'),
            ),
          ],
        ),
      ),
    );
  }
}