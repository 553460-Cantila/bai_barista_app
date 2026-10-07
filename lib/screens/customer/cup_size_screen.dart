import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/order_state.dart';
import '../../theme.dart';
import 'addons_screen.dart';

class CupSizeScreen extends StatelessWidget {
  const CupSizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderState>();
    final drink = order.drink;
    // The order is cleared once it is placed; screens still under the new one must not crash.
    if (drink == null) return const SizedBox.shrink();
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text(drink.name)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pick your cup size.'),
            const SizedBox(height: 16),
            Row(
              children: List.generate(3, (i) {
                final selected = order.sizeIndex == i;
                // Same cute mascot at three sizes — this is deliberately the
                // icon, not the drink's real photo (that only shows on Menu).
                const scale = [0.6, 0.78, 0.95];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      context.read<OrderState>().pickSize(i);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddOnsScreen()));
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: selected ? BaiColors.mint : BaiColors.card,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Column(
                        children: [
                          Image.asset('assets/images/cup_mascot.gif', width: 60 * scale[i] + 20),
                          const SizedBox(height: 8),
                          Text(OrderState.sizeNames[i], style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                                color: BaiColors.butter, borderRadius: BorderRadius.circular(12)),
                            child: Text('₱${drink.prices[i]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}