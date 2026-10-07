import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class AddStockScreen extends StatefulWidget {
  final InventoryItem item;
  const AddStockScreen({super.key, required this.item});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _fs = FirestoreService();
  final _qty = TextEditingController();
  int _preview = 0;

  @override
  void initState() {
    super.initState();
    _preview = widget.item.currentStock;
    _qty.addListener(() {
      setState(() => _preview = widget.item.currentStock + (int.tryParse(_qty.text) ?? 0));
    });
  }

  Future<void> _confirm() async {
    final amount = int.tryParse(_qty.text) ?? 0;
    await _fs.addStock(widget.item.id, amount);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.item.unit;
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Add stock')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.item.name, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text('Current stock', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: BaiColors.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child: Text('${widget.item.currentStock} $unit',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Add quantity', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qty,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '0'),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(color: BaiColors.butter, borderRadius: BorderRadius.circular(12)),
                  child: Text(unit, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: BaiColors.mint, borderRadius: BorderRadius.circular(16)),
              child: Center(
                child: Text('New total: $_preview $unit',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BaiColors.mint,
                foregroundColor: BaiColors.ink,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              onPressed: _confirm,
              child: const Text('Confirm addition'),
            ),
          ],
        ),
      ),
    );
  }
}
