import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';
import '../../widgets/pastel_button.dart';
import 'edit_item_screen.dart';
import 'add_stock_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Inventory')),
      body: StreamBuilder<List<InventoryItem>>(
        stream: fs.inventory(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          final low = items.where((i) => i.isLow).toList();
          final ok = items.where((i) => !i.isLow).toList();

          Widget row(InventoryItem i) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: i.isLow ? const Color(0xFFFFF0EE) : BaiColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: i.isLow ? const Color(0xFFFFD9D4) : Colors.white, width: 4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(i.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Row(
                          children: [
                            if (i.isLow) ...[
                              const Icon(Icons.warning_amber_rounded, size: 15, color: Color(0xFFC1554A)),
                              const SizedBox(width: 3),
                            ],
                            Text(
                              '${i.currentStock} ${i.unit}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: i.isLow ? const Color(0xFFC1554A) : BaiColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => EditItemScreen(item: i))),
                            child: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: BaiColors.butter, foregroundColor: BaiColors.ink, elevation: 0),
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => AddStockScreen(item: i))),
                            child: const Text('Stock+'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              const Row(children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFC1554A)),
                SizedBox(width: 5),
                Text('Low stock', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC1554A))),
              ]),
              const SizedBox(height: 8),
              if (low.isEmpty) const Text('Nothing low right now.', style: TextStyle(color: Colors.black54)),
              ...low.map(row),
              const SizedBox(height: 10),
              const Row(children: [
                Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF3D8A5F)),
                SizedBox(width: 5),
                Text('In stock', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D8A5F))),
              ]),
              const SizedBox(height: 8),
              ...ok.map(row),
              const SizedBox(height: 10),
              PastelButton(
                label: '+ Add new item',
                color: BaiColors.butter,
                shadowColor: BaiColors.butterShadow,
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const EditItemScreen(item: null))),
              ),
            ],
          );
        },
      ),
    );
  }
}