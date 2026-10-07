import 'package:cloud_firestore/cloud_firestore.dart';

/// B.A.I.'s cut of every customer order (5%). Changing this only affects
/// NEW orders — each order stores the commission it was placed with.
const double kCommissionRate = 0.05;

/// Commission owed to B.A.I. for an order total, rounded to centavos.
double commissionFor(int total) => (total * kCommissionRate * 100).round() / 100;

/// Cafe subscription fee (pesos per month) and the id used on remittance records.
const int kMonthlyFee = 500;
const String kCafeId = 'brew_haven';

class RecipeIngredient {
  String name;
  String amount;
  RecipeIngredient(this.name, this.amount);

  factory RecipeIngredient.fromMap(Map<String, dynamic> m) =>
      RecipeIngredient(m['name'] ?? '', m['amount'] ?? '');
  Map<String, dynamic> toMap() => {'name': name, 'amount': amount};
}

class AddOnEffect {
  String addOnName;
  String effect;
  AddOnEffect(this.addOnName, this.effect);

  factory AddOnEffect.fromMap(Map<String, dynamic> m) =>
      AddOnEffect(m['addOnName'] ?? '', m['effect'] ?? '');
  Map<String, dynamic> toMap() => {'addOnName': addOnName, 'effect': effect};
}

class Drink {
  final String id;
  String name;
  List<int> prices; // [small, medium, large]
  bool available;
  String? imageUrl; // staff-uploaded product photo — shown on the Menu screen only
  List<RecipeIngredient> recipe;
  List<AddOnEffect> addOnEffects;

  Drink({
    required this.id,
    required this.name,
    required this.prices,
    required this.available,
    this.imageUrl,
    this.recipe = const [],
    this.addOnEffects = const [],
  });

  factory Drink.fromMap(String id, Map<String, dynamic> m) => Drink(
        id: id,
        name: m['name'] ?? '',
        prices: ((m['prices'] as List?) ?? [0, 0, 0]).map((e) => (e as num).toInt()).toList(),
        available: m['available'] ?? true,
        imageUrl: m['imageUrl'],
        recipe: ((m['recipe'] as List?) ?? [])
            .map((e) => RecipeIngredient.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        addOnEffects: ((m['addOnEffects'] as List?) ?? [])
            .map((e) => AddOnEffect.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'prices': prices,
        'available': available,
        'imageUrl': imageUrl,
        'recipe': recipe.map((r) => r.toMap()).toList(),
        'addOnEffects': addOnEffects.map((a) => a.toMap()).toList(),
      };
}

class InventoryItem {
  final String id;
  String name, unit, category;
  int currentStock, lowThreshold, criticalThreshold;

  InventoryItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.category,
    required this.currentStock,
    required this.lowThreshold,
    required this.criticalThreshold,
  });

  bool get isLow => currentStock <= lowThreshold;

  factory InventoryItem.fromMap(String id, Map<String, dynamic> m) => InventoryItem(
        id: id,
        name: m['name'] ?? '',
        unit: m['unit'] ?? '',
        category: m['category'] ?? 'ing',
        currentStock: m['currentStock'] ?? 0,
        lowThreshold: m['lowThreshold'] ?? 0,
        criticalThreshold: m['criticalThreshold'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'unit': unit,
        'category': category,
        'currentStock': currentStock,
        'lowThreshold': lowThreshold,
        'criticalThreshold': criticalThreshold,
      };
}

class OrderDoc {
  final String id;
  final String customerId, drinkName, size, paymentMethod, status;
  final List<String> addOns;
  final int total;
  final double commission; // B.A.I.'s 5% cut, stored with the order
  final String? proofUrl;
  final DateTime? createdAt;
  final DateTime? completedAt; // set when the order is marked picked up ('done')
  final bool remitted; // true once its commission has been remitted to B.A.I.

  OrderDoc({
    required this.id,
    required this.customerId,
    required this.drinkName,
    required this.size,
    required this.addOns,
    required this.total,
    required this.paymentMethod,
    required this.status,
    double? commission,
    this.proofUrl,
    this.createdAt,
    this.completedAt,
    this.remitted = false,
  }) : commission = commission ?? commissionFor(total);

  /// When the order was completed; orders finished before completion dates
  /// were saved fall back to the date they were placed.
  DateTime? get completedOrCreated => completedAt ?? createdAt;

  factory OrderDoc.fromMap(String id, Map<String, dynamic> m) => OrderDoc(
        id: id,
        customerId: m['customerId'] ?? '',
        drinkName: m['drinkName'] ?? '',
        size: m['size'] ?? '',
        addOns: List<String>.from(m['addOns'] ?? []),
        total: m['total'] ?? 0,
        // Orders placed before commissions existed have no stored value — derive it.
        commission: (m['commission'] as num?)?.toDouble() ?? commissionFor((m['total'] ?? 0) as int),
        paymentMethod: m['paymentMethod'] ?? '',
        status: m['status'] ?? 'new',
        proofUrl: m['proofUrl'],
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
        completedAt: (m['completedAt'] as Timestamp?)?.toDate(),
        remitted: m['remitted'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'drinkName': drinkName,
        'size': size,
        'addOns': addOns,
        'total': total,
        'commission': commission,
        'commissionRate': kCommissionRate,
        'paymentMethod': paymentMethod,
        'status': status,
        'proofUrl': proofUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class AddOn {
  final String id, name;
  final int price;
  const AddOn(this.id, this.name, this.price);
}

const kAddOns = [
  AddOn('shot', 'Extra shot', 25),
  AddOn('oat', 'Oat milk', 30),
  AddOn('van', 'Vanilla', 20),
  AddOn('car', 'Caramel', 20),
  AddOn('whip', 'Whipped cream', 15),
  AddOn('pearl', 'Boba pearls', 25),
];

/// Cafe subscription (settings/subscription). A missing document means the
/// subscription is not active yet, so the app stays locked until an admin
/// marks it as paid.
class SubscriptionStatus {
  final String cafeName, plan;
  final int monthlyFee;
  final bool isActive;
  final DateTime? lastPaymentDate, nextBillingDate;

  const SubscriptionStatus({
    this.cafeName = '',
    this.plan = '',
    this.monthlyFee = 0,
    this.isActive = false,
    this.lastPaymentDate,
    this.nextBillingDate,
  });

  factory SubscriptionStatus.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const SubscriptionStatus();
    return SubscriptionStatus(
      cafeName: m['cafeName'] ?? '',
      plan: m['plan'] ?? '',
      monthlyFee: (m['monthlyFee'] ?? 0) as int,
      isActive: m['isActive'] ?? false,
      lastPaymentDate: (m['lastPaymentDate'] as Timestamp?)?.toDate(),
      nextBillingDate: (m['nextBillingDate'] as Timestamp?)?.toDate(),
    );
  }
}

/// One subscription payment record (subscriptionPayments/{id}).
/// status: pending / paid / declined. source: manual / receipt.
class SubscriptionPayment {
  final String id, status, source;
  final int amount;
  final String? imageUrl, notes;
  final DateTime? createdAt, decidedAt;

  const SubscriptionPayment({
    required this.id,
    required this.amount,
    required this.status,
    required this.source,
    this.imageUrl,
    this.notes,
    this.createdAt,
    this.decidedAt,
  });

  factory SubscriptionPayment.fromMap(String id, Map<String, dynamic> m) => SubscriptionPayment(
        id: id,
        amount: (m['amount'] ?? 0) as int,
        status: m['status'] ?? 'pending',
        source: m['source'] ?? 'manual',
        imageUrl: m['imageUrl'],
        notes: m['notes'],
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
        decidedAt: (m['decidedAt'] as Timestamp?)?.toDate(),
      );
}

/// One commission remittance from the cafe to B.A.I. (remittances/{id}).
/// Created when the cafe taps "Mark as remitted"; counts as B.A.I.'s
/// commission earnings on [dateRemitted].
class Remittance {
  final String id, cafeId;
  final double amount;
  final int orderCount;
  final DateTime? dateRemitted, periodStart, periodEnd;

  const Remittance({
    required this.id,
    required this.cafeId,
    required this.amount,
    this.orderCount = 0,
    this.dateRemitted,
    this.periodStart,
    this.periodEnd,
  });

  factory Remittance.fromMap(String id, Map<String, dynamic> m) => Remittance(
        id: id,
        cafeId: m['cafeId'] ?? '',
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        orderCount: (m['orderCount'] as num?)?.toInt() ?? 0,
        dateRemitted: (m['dateRemitted'] as Timestamp?)?.toDate(),
        periodStart: (m['periodStart'] as Timestamp?)?.toDate(),
        periodEnd: (m['periodEnd'] as Timestamp?)?.toDate(),
      );
}