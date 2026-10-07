import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../state/order_state.dart';
import '../../theme.dart';
import 'review_screen.dart';

class AddOnsScreen extends StatelessWidget {
  const AddOnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderState>();
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Add-ons')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(alignment: Alignment.centerLeft, child: Text('Choose as many as you like.')),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: kAddOns.length,
              itemBuilder: (context, i) {
                final a = kAddOns[i];
                final selected = order.addOnIds.contains(a.id);
                return GestureDetector(
                  onTap: () => context.read<OrderState>().toggleAddOn(a.id),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected ? BaiColors.lavender : BaiColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(a.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                          decoration: BoxDecoration(color: BaiColors.butter, borderRadius: BorderRadius.circular(10)),
                          child: Text('+₱${a.price}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Projected total', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('₱${order.total}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BaiColors.butter,
                    foregroundColor: BaiColors.ink,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  ),
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewScreen())),
                  child: const Text('Confirm order'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}