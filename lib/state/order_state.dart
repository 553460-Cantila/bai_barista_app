import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class OrderState extends ChangeNotifier {
  Drink? drink;
  int sizeIndex = 1; // 0=Small 1=Medium 2=Large
  final Set<String> addOnIds = {};
  final String paymentMethod = 'gcash'; // GCash is the only method — no cash option
  File? proofImage;

  static const sizeNames = ['Small', 'Medium', 'Large'];

  int get basePrice => drink?.prices[sizeIndex] ?? 0;

  int get total =>
      basePrice + addOnIds.fold<int>(0, (t, id) => t + kAddOns.firstWhere((a) => a.id == id).price);

  List<AddOn> get selectedAddOns =>
      addOnIds.map((id) => kAddOns.firstWhere((a) => a.id == id)).toList();

  void pickDrink(Drink d) {
    drink = d;
    sizeIndex = 1;
    addOnIds.clear();
    notifyListeners();
  }

  void pickSize(int i) {
    sizeIndex = i;
    notifyListeners();
  }

  void toggleAddOn(String id) {
    if (addOnIds.contains(id)) {
      addOnIds.remove(id);
    } else {
      addOnIds.add(id);
    }
    notifyListeners();
  }

  void setProofImage(File file) {
    proofImage = file;
    notifyListeners();
  }

  bool get canPlaceOrder => proofImage != null;

  void reset() {
    drink = null;
    sizeIndex = 1;
    addOnIds.clear();
    proofImage = null;
    notifyListeners();
  }
}