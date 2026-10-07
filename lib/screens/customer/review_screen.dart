import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/order_state.dart';
import '../../theme.dart';
import 'payment_screen.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderState>();
    final drink = order.drink;
    // The order is cleared once it is placed; screens still under the new one must not crash.
    if (drink == null) return const SizedBox.shrink();
    final hasPhoto = drink.imageUrl != null && drink.imageUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Review your order')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Make sure everything looks right before you pay.'),
          const SizedBox(height: 14),

          // Drink photo / fallback icon + name + size
          Container(
            decoration: BoxDecoration(
              color: BaiColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white, width: 4),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: hasPhoto
                      ? Image.network(drink.imageUrl!, fit: BoxFit.cover)
                      : Container(
                          color: Colors.white,
                          child: Center(
                            child: Image.asset('assets/images/cup_mascot.gif', width: 70),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Text(drink.name,
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                        decoration: BoxDecoration(
                            color: BaiColors.lavender, borderRadius: BorderRadius.circular(14)),
                        child: Text(OrderState.sizeNames[order.sizeIndex],
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text('Order summary', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: BaiColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Column(
              children: [
                _row('${drink.name} (${OrderState.sizeNames[order.sizeIndex]})', '₱${order.basePrice}'),
                if (order.selectedAddOns.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('No add-ons selected', style: TextStyle(color: Colors.black54, fontSize: 13)),
                    ),
                  )
                else
                  for (final a in order.selectedAddOns) _row(a.name, '+₱${a.price}'),
                const Divider(),
                _row('Predicted total', '₱${order.total}', bold: true),
              ],
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BaiColors.butter,
              foregroundColor: BaiColors.ink,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen())),
            child: const Text('Proceed to payment'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pop(context), // back to Add-ons to change the order
            child: const Text('Edit order'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
            ),
            Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      );
}