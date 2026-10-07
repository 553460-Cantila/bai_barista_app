import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';
import '../../utils/date_text.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});
  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  final _fs = FirestoreService();
  String _filter = 'all'; // all | new | preparing | ready

  static const _label = {'new': 'New', 'preparing': 'Preparing', 'ready': 'Ready'};
  static const _color = {
    'new': Color(0xFFCFE3FF),
    'preparing': BaiColors.butter,
    'ready': BaiColors.mint,
  };
  static const _nextStatus = {'new': 'preparing', 'preparing': 'ready', 'ready': 'done'};
  static const _nextLabel = {'new': 'Accept order', 'preparing': 'Mark ready', 'ready': 'Picked up'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Live kitchen')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('All incoming orders — updated in real time.'),
            const SizedBox(height: 12),
            Row(
              children: ['all', 'new', 'preparing', 'ready'].map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f == 'all' ? 'All' : _label[f]!),
                    selected: selected,
                    selectedColor: BaiColors.lavender,
                    backgroundColor: Colors.white,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<OrderDoc>>(
                stream: _fs.activeOrders(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('Could not load.\n${snap.error}', textAlign: TextAlign.center));
                  }
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final orders = snap.data!
                      .where((o) => _filter == 'all' || o.status == _filter)
                      .toList();
                  if (orders.isEmpty) {
                    return const Center(child: Text('No orders in this filter.'));
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
                                    color: _color[o.status],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(_label[o.status] ?? o.status,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${o.size} ${o.drinkName}${o.addOns.isEmpty ? '' : ' + ${o.addOns.join(', ')}'}'),
                            Text('₱${o.total} · GCash',
                                style: const TextStyle(color: Colors.black54, fontSize: 13)),
                            Text(formatDateTime(o.createdAt),
                                style: const TextStyle(color: Colors.black45, fontSize: 12)),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _color[o.status],
                                  foregroundColor: BaiColors.ink,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: () async {
                                  final warnings = await _fs.advanceOrderStatus(o.id, _nextStatus[o.status]!);
                                  if (warnings.isNotEmpty && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      duration: const Duration(seconds: 6),
                                      content: Text('Stock note: ${warnings.join(' ')}'),
                                    ));
                                  }
                                },
                                child: Text(_nextLabel[o.status]!),
                              ),
                            ),
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