import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';
import '../../utils/date_text.dart';

class SeeOrderScreen extends StatelessWidget {
  const SeeOrderScreen({super.key});

  static const _label = {'new': 'New', 'preparing': 'Preparing', 'ready': 'Ready for pickup', 'done': 'Picked up'};
  static const _color = {
    'new': Color(0xFFCFE3FF),
    'preparing': BaiColors.butter,
    'ready': BaiColors.mint,
    'done': Colors.white,
  };

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Your orders')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live status from the barista.'),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder<List<OrderDoc>>(
                stream: fs.myOrders(uid),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('Could not load.\n${snap.error}', textAlign: TextAlign.center));
                  }
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final orders = snap.data!;
                  if (orders.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.coffee_outlined, size: 48, color: Colors.black38),
                          SizedBox(height: 8),
                          Text('No orders yet. Go brew one!'),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, i) {
                      final o = orders[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: BaiColors.card,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Order #${o.id.substring(0, 5).toUpperCase()}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _color[o.status] ?? Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(_label[o.status] ?? o.status,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${o.size} ${o.drinkName}${o.addOns.isEmpty ? '' : ' · ${o.addOns.length} add-on${o.addOns.length == 1 ? '' : 's'}'}'),
                            Text('₱${o.total} · ${o.paymentMethod == 'cash' ? 'Cash' : 'GCash'}',
                                style: const TextStyle(color: Colors.black54, fontSize: 13)),
                            Text(formatDateTime(o.createdAt),
                                style: const TextStyle(color: Colors.black45, fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}