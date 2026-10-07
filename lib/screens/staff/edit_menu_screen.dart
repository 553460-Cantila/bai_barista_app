import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';
import 'edit_recipe_screen.dart';

class EditMenuScreen extends StatefulWidget {
  const EditMenuScreen({super.key});
  @override
  State<EditMenuScreen> createState() => _EditMenuScreenState();
}

class _EditMenuScreenState extends State<EditMenuScreen> {
  final _fs = FirestoreService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Edit Menu')),
      body: StreamBuilder<List<Drink>>(
        stream: _fs.allDrinks(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final drinks = snap.data!;

          if (drinks.isEmpty) {
  
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_cafe_outlined, size: 48, color: Colors.black38),
                    const SizedBox(height: 10),
                    const Text('No drinks on the menu yet.', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text(
                      'Add your first drink to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditRecipeScreen(
                            drink: Drink(id: '', name: '', prices: const [0, 0, 0], available: true),
                          ),
                        ),
                      ),
                      child: const Text('Add a drink'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Manage drinks, prices, and recipes.'),
              const SizedBox(height: 14),
              ...drinks.map((d) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: BaiColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Row(
                          children: [
                            Text(
                              'Base: ₱${d.prices.length > 1 ? d.prices[1] : d.prices.first} · ',
                              style: TextStyle(
                                color: d.available ? Colors.black54 : const Color(0xFFC1554A),
                                fontSize: 13,
                              ),
                            ),
                            Icon(
                              d.available ? Icons.check_circle : Icons.cancel,
                              size: 14,
                              color: d.available ? const Color(0xFF3D8A5F) : const Color(0xFFC1554A),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              d.available ? 'Available' : 'Unavailable',
                              style: TextStyle(
                                color: d.available ? Colors.black54 : const Color(0xFFC1554A),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(
                                context, MaterialPageRoute(builder: (_) => EditRecipeScreen(drink: d))),
                            child: const Text('Edit Recipe'),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BaiColors.butter,
                  foregroundColor: BaiColors.ink,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditRecipeScreen(
                      drink: Drink(id: '', name: '', prices: const [0, 0, 0], available: true),
                    ),
                  ),
                ),
                child: const Text('+ Add new drink'),
              ),
            ],
          );
        },
      ),
    );
  }
}