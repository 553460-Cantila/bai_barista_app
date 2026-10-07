import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../theme.dart';

class EditRecipeScreen extends StatefulWidget {
  final Drink drink; // drink.id == '' means creating a new drink
  const EditRecipeScreen({super.key, required this.drink});

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  final _fs = FirestoreService();
  final _cloudinary = CloudinaryService();
  late final _name = TextEditingController(text: widget.drink.name);
  late final _small = TextEditingController(text: widget.drink.prices.isNotEmpty ? '${widget.drink.prices[0]}' : '');
  late final _medium = TextEditingController(text: widget.drink.prices.length > 1 ? '${widget.drink.prices[1]}' : '');
  late final _large = TextEditingController(text: widget.drink.prices.length > 2 ? '${widget.drink.prices[2]}' : '');
  late bool _available = widget.drink.available;
  late List<RecipeIngredient> _recipe = widget.drink.recipe.map((r) => RecipeIngredient(r.name, r.amount)).toList();
  late List<AddOnEffect> _addOns = widget.drink.addOnEffects.map((a) => AddOnEffect(a.addOnName, a.effect)).toList();

  String? _existingImageUrl = ''; // set in initState from widget.drink.imageUrl
  File? _newImage; // picked but not yet uploaded
  bool _saving = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _existingImageUrl = widget.drink.imageUrl;
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _newImage = File(picked.path));
  }

  void _removePhoto() {
    setState(() {
      _newImage = null;
      _existingImageUrl = null;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    String? finalImageUrl = _existingImageUrl;
    if (_newImage != null) {
      setState(() => _uploadingPhoto = true);
      final url = await _cloudinary.upload(_newImage!);
      setState(() => _uploadingPhoto = false);
      if (url == null) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Photo upload failed — saved without it.')));
        }
      } else {
        finalImageUrl = url;
      }
    }

    final drink = Drink(
      id: widget.drink.id,
      name: _name.text.trim(),
      prices: [
        int.tryParse(_small.text) ?? 0,
        int.tryParse(_medium.text) ?? 0,
        int.tryParse(_large.text) ?? 0,
      ],
      available: _available,
      imageUrl: finalImageUrl,
      recipe: _recipe,
      addOnEffects: _addOns,
    );
    await _fs.saveDrink(drink);
    if (mounted) Navigator.pop(context);
  }

  Widget _photoSection() {
    final hasExisting = _newImage == null && (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Product photo', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Shown to customers on the Menu screen — cup sizes still use the cute icon.',
            style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickPhoto,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: BaiColors.lavender, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: _newImage != null
                ? Image.file(_newImage!, fit: BoxFit.cover)
                : hasExisting
                    ? Image.network(_existingImageUrl!, fit: BoxFit.cover)
                    : const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 32, color: Colors.black45),
                            SizedBox(height: 6),
                            Text('Tap to upload a photo', style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
          ),
        ),
        if (_uploadingPhoto)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Uploading photo…', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ),
        if (_newImage != null || hasExisting)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _removePhoto,
              child: const Text('Remove photo', style: TextStyle(color: Color(0xFFC1554A))),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _priceField(String label, TextEditingController c) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          TextField(
            controller: c,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(prefixText: '₱'),
          ),
        ],
      ),
    );
  }

  Widget _editableRow(String left, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: BaiColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: Row(
        children: [
          Expanded(child: Text(left)),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Color(0xFFC1554A)),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _addIngredient() async {
    final nameCtl = TextEditingController();
    final amountCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add ingredient'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtl, decoration: const InputDecoration(hintText: 'Ingredient name')),
          TextField(controller: amountCtl, decoration: const InputDecoration(hintText: 'Amount (e.g. 18 g)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && nameCtl.text.trim().isNotEmpty) {
      setState(() => _recipe.add(RecipeIngredient(nameCtl.text.trim(), amountCtl.text.trim())));
    }
  }

  Future<void> _addAddOnEffect() async {
    final nameCtl = TextEditingController();
    final effectCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add add-on effect'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtl, decoration: const InputDecoration(hintText: 'Add-on name (e.g. Extra shot)')),
          TextField(controller: effectCtl, decoration: const InputDecoration(hintText: 'Effect (e.g. coffee_beans +10 g)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && nameCtl.text.trim().isNotEmpty) {
      setState(() => _addOns.add(AddOnEffect(nameCtl.text.trim(), effectCtl.text.trim())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.drink.id.isEmpty;
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isNew ? 'Add drink' : 'Edit recipe'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _photoSection(),
          TextField(controller: _name, decoration: const InputDecoration(hintText: 'Drink name')),
          const SizedBox(height: 12),
          Row(children: [
            _priceField('Small', _small),
            const SizedBox(width: 8),
            _priceField('Medium', _medium),
            const SizedBox(width: 8),
            _priceField('Large', _large),
          ]),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Available on menu'),
            value: _available,
            activeColor: BaiColors.mint,
            onChanged: (v) => setState(() => _available = v),
          ),
          const SizedBox(height: 8),
          const Text('Base recipe', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._recipe.asMap().entries.map((e) => _editableRow(
                '${e.value.name} — ${e.value.amount}',
                () => setState(() => _recipe.removeAt(e.key)),
              )),
          TextButton(onPressed: _addIngredient, child: const Text('+ Add ingredient')),
          const SizedBox(height: 10),
          const Text('Cup requirements', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final c in const [['Small', 'cup_small'], ['Medium', 'cup_medium'], ['Large', 'cup_large']])
            Container(
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(color: BaiColors.card, borderRadius: BorderRadius.circular(14)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(c[0]),
                Text(c[1]),
              ]),
            ),
          const SizedBox(height: 10),
          const Text('Add-on effects', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._addOns.asMap().entries.map((e) => _editableRow(
                '${e.value.addOnName} → ${e.value.effect}',
                () => setState(() => _addOns.removeAt(e.key)),
              )),
          TextButton(onPressed: _addAddOnEffect, child: const Text('+ Add add-on effect')),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BaiColors.mint,
              foregroundColor: BaiColors.ink,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(isNew ? 'Add drink' : 'Save recipe'),
          ),
        ],
      ),
    );
  }
}