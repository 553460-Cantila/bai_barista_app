import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../widgets/home_action_grid.dart';
import 'profile_screen.dart';
import 'menu_screen.dart';
import 'see_order_screen.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      body: StreamBuilder<SubscriptionStatus>(
        stream: fs.subscriptionStatus(),
        builder: (context, subSnap) {
          final isActive = subSnap.data?.isActive ?? true; // assume active while loading, to avoid a flash of "unavailable"

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/wooden_table_bg.png', fit: BoxFit.cover),
              SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            child: Image.asset('assets/images/cup_mascot.gif', width: 22),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.person_outline, color: Colors.white),
                          tooltip: 'Profile',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          ),
                        ),
                      ],
                    ),
                    if (!isActive)
                      Expanded(child: _UnavailableView())
                    else ...[
                      const SizedBox(height: 4),
                      const Text('Good morning!', textAlign: TextAlign.center, style: baiHeading),
                      const SizedBox(height: 4),
                      const Text(
                        'What are we brewing today?',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: HomeActionGrid(cells: [
                            const GridCell.decor('assets/images/cup_mascot.gif'),
                            const GridCell.decor('assets/images/cookie_decor.gif'),
                            GridCell.button(
                              icon: Icons.local_cafe_outlined,
                              label: 'Order',
                              color: BaiColors.butter,
                              onTap: () => Navigator.push(
                                  context, MaterialPageRoute(builder: (_) => const MenuScreen())),
                            ),
                            GridCell.button(
                              icon: Icons.receipt_long_outlined,
                              label: 'See order',
                              color: BaiColors.mint,
                              onTap: () => Navigator.push(
                                  context, MaterialPageRoute(builder: (_) => const SeeOrderScreen())),
                            ),
                            const GridCell.decor('assets/images/cookie_decor.gif'),
                            const GridCell.decor('assets/images/cup_mascot.gif'),
                          ]),
                        ),
                      ),
                    ],
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

class _UnavailableView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined, size: 44, color: Colors.black38),
            SizedBox(height: 10),
            Text('Temporarily unavailable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            SizedBox(height: 6),
            Text(
              "We're not taking orders right now. Please check back soon.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}