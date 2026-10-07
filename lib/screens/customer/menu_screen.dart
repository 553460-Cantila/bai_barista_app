import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../state/order_state.dart';
import '../../theme.dart';
import 'cup_size_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Our menu')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose your drink to start.'),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder<List<Drink>>(
                stream: fs.availableDrinks(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(
                      child: Text('Could not load the menu: ${snap.error}', textAlign: TextAlign.center),
                    );
                  }
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final drinks = snap.data!;
                  if (drinks.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.coffee_outlined, size: 48, color: Colors.black38),
                          SizedBox(height: 8),
                          Text('No drinks available right now.'),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.88,
                    ),
                    itemCount: drinks.length,
                    itemBuilder: (context, i) {
                      final d = drinks[i];
                      final hasPhoto = d.imageUrl != null && d.imageUrl!.isNotEmpty;
                      return GestureDetector(
                        onTap: () {
                          context.read<OrderState>().pickDrink(d);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CupSizeScreen()));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: BaiColors.card,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: hasPhoto
                                    ? Image.network(d.imageUrl!, fit: BoxFit.cover)
                                    : Container(
                                        color: Colors.white,
                                        child: const Center(
                                          child: Icon(Icons.local_cafe_outlined, size: 40, color: Colors.black26),
                                        ),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                child: Column(
                                  children: [
                                    Text(d.name,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: BaiColors.butter, borderRadius: BorderRadius.circular(12)),
                                      child: Text('₱${d.prices.length > 1 ? d.prices[1] : d.prices.first}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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