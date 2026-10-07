import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class EditItemScreen extends StatefulWidget {
  final InventoryItem? item; // null = creating a new item
  const EditItemScreen({super.key, required this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _fs = FirestoreService();
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _unit = TextEditingController(text: widget.item?.unit ?? '');
  late final _current = TextEditingController(text: widget.item?.currentStock.toString() ?? '');
  late final _low = TextEditingController(text: widget.item?.lowThreshold.toString() ?? '');
  late final _crit = TextEditingController(text: widget.item?.criticalThreshold.toString() ?? '');
  late String _category = widget.item?.category ?? 'ing';
  bool _loading = false;

  Future<void> _save() async {
    setState(() => _loading = true);
    final item = InventoryItem(
      id: widget.item?.id ?? '',
      name: _name.text.trim(),
      unit: _unit.text.trim().isEmpty ? 'unit' : _unit.text.trim(),
      category: _category,
      currentStock: int.tryParse(_current.text) ?? 0,
      lowThreshold: int.tryParse(_low.text) ?? 0,
      criticalThreshold: int.tryParse(_crit.text) ?? 0,
    );
    await _fs.saveItem(item);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (widget.item == null) return;
    await _fs.deleteItem(widget.item!.id);
    if (mounted) Navigator.pop(context);
  }

  Widget _field(String label, TextEditingController c, {String? unit, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(child: TextField(controller: c, keyboardType: type)),
              if (unit != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(color: BaiColors.butter, borderRadius: BorderRadius.circular(12)),
                  child: Text(unit, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unit = _unit.text.isEmpty ? 'unit' : _unit.text;
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Edit item')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field('Name', _name),
          _field('Unit', _unit),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Ingredient')),
                  selected: _category == 'ing',
                  selectedColor: BaiColors.lavender,
                  onSelected: (_) => setState(() => _category = 'ing'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Cup')),
                  selected: _category == 'cup',
                  selectedColor: BaiColors.lavender,
                  onSelected: (_) => setState(() => _category = 'cup'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _field('Current stock', _current, unit: unit, type: TextInputType.number),
          _field('Low-stock threshold', _low, unit: unit, type: TextInputType.number),
          _field('Critical threshold', _crit, unit: unit, type: TextInputType.number),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BaiColors.mint,
              foregroundColor: BaiColors.ink,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
            onPressed: _loading ? null : _save,
            child: const Text('Save changes'),
          ),
          if (widget.item != null) ...[
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BaiColors.red,
                foregroundColor: BaiColors.ink,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              onPressed: _delete,
              child: const Text('Delete item'),
            ),
          ],
        ],
      ),
    );
  }
}
