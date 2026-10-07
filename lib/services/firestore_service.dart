import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../utils/recipe_parser.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ---------------- Drinks / Menu ----------------
  Stream<List<Drink>> allDrinks() => _db
      .collection('drinks')
      .snapshots()
      .map((s) => _byName(s.docs.map((d) => Drink.fromMap(d.id, d.data())).toList()));

  /// What the customer Menu screen shows — only drinks staff marked available.
  Stream<List<Drink>> availableDrinks() => _db
      .collection('drinks')
      .where('available', isEqualTo: true)
      .snapshots()
      .map((s) => _byName(s.docs.map((d) => Drink.fromMap(d.id, d.data())).toList()));

  Future<void> saveDrink(Drink drink) async {
    if (drink.id.isEmpty) {
      await _db.collection('drinks').add(drink.toMap());
    } else {
      await _db.collection('drinks').doc(drink.id).set(drink.toMap());
    }
  }

  Future<void> deleteDrink(String id) => _db.collection('drinks').doc(id).delete();

  // ---------------- Inventory ----------------
  Stream<List<InventoryItem>> inventory() => _db
      .collection('inventory')
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map((d) => InventoryItem.fromMap(d.id, d.data())).toList());

  Future<void> saveItem(InventoryItem item) async {
    if (item.id.isEmpty) {
      await _db.collection('inventory').add(item.toMap());
    } else {
      await _db.collection('inventory').doc(item.id).set(item.toMap());
    }
  }

  Future<void> addStock(String itemId, int amount) =>
      _db.collection('inventory').doc(itemId).update({'currentStock': FieldValue.increment(amount)});

  Future<void> deleteItem(String itemId) => _db.collection('inventory').doc(itemId).delete();

  // ---------------- Orders ----------------
  /// Customer: write a new order, returns the new order's id.
  Future<String> placeOrder(OrderDoc order) async {
    final ref = await _db.collection('orders').add(order.toMap());
    return ref.id;
  }

  /// Admin: every order placed on or after [since], newest first.
  /// Used by the commission screens. A range filter on a single field needs no
  /// composite index; sorting is done on the device like the other order streams.
  Stream<List<OrderDoc>> ordersSince(DateTime since) => _db
      .collection('orders')
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
      .snapshots()
      .map((s) => _byCreated(s.docs).map((d) => OrderDoc.fromMap(d.id, d.data())).toList());

  /// Customer: See Order screen — just this person's orders, newest first.
  Stream<List<OrderDoc>> myOrders(String customerId) => _db
      .collection('orders')
      .where('customerId', isEqualTo: customerId)
      .snapshots()
      .map((s) => _byCreated(s.docs).map((d) => OrderDoc.fromMap(d.id, d.data())).toList());

  /// Staff: Live Kitchen — every active order across all customers.
  Stream<List<OrderDoc>> activeOrders() => _db
      .collection('orders')
      .where('status', whereIn: ['new', 'preparing', 'ready'])
      .snapshots()
      .map((s) => _byCreated(s.docs, descending: false).map((d) => OrderDoc.fromMap(d.id, d.data())).toList());

  /// Moves an order to [nextStatus]. When it moves to 'preparing', the stock for
  /// that order (recipe + add-ons + one cup) is deducted from inventory — once
  /// only, inside a transaction. Returns warnings to show the barista, e.g.
  /// an ingredient that is missing from inventory or ran out.
  Future<List<String>> advanceOrderStatus(String orderId, String nextStatus) async {
    final orderRef = _db.collection('orders').doc(orderId);
    if (nextStatus != 'preparing') {
      await orderRef.update({
        'status': nextStatus,
        // Remember when the order was completed so reports can use that date.
        if (nextStatus == 'done') 'completedAt': FieldValue.serverTimestamp(),
      });
      return const [];
    }
    return _startPreparing(orderRef);
  }

  /// Accepts an order: deducts its stock and sets the status to 'preparing'.
  Future<List<String>> _startPreparing(DocumentReference<Map<String, dynamic>> orderRef) async {
    final warnings = <String>[];
    final orderData = (await orderRef.get()).data();
    if (orderData == null) return warnings;
    if (orderData['stockDeducted'] == true) {
      await orderRef.update({'status': 'preparing'});
      return warnings;
    }

    final drinkName = (orderData['drinkName'] ?? '').toString();
    final size = (orderData['size'] ?? 'Medium').toString();
    final addOns = List<String>.from(orderData['addOns'] ?? const []);

    final drinkSnap = await _db.collection('drinks').where('name', isEqualTo: drinkName).limit(1).get();
    if (drinkSnap.docs.isEmpty) {
      await orderRef.update({'status': 'preparing'});
      return ['"$drinkName" is no longer on the menu — stock was not deducted.'];
    }
    final drink = Drink.fromMap(drinkSnap.docs.first.id, drinkSnap.docs.first.data());

    final invSnap = await _db.collection('inventory').get();
    final byName = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    QueryDocumentSnapshot<Map<String, dynamic>>? cup;
    for (final d in invSnap.docs) {
      final m = d.data();
      byName[normalizeName((m['name'] ?? '').toString())] = d;
      if (m['category'] == 'cup' && (m['name'] ?? '').toString().toLowerCase().contains(size.toLowerCase())) {
        cup = d;
      }
    }

    // How much of each inventory item this order uses (in the item's own unit).
    final needs = <String, int>{}; // inventory doc id -> amount
    final names = <String, String>{}; // inventory doc id -> display name
    void need(String ingredient, double amount, String unit, double scale) {
      final item = byName[normalizeName(ingredient)];
      if (item == null) {
        warnings.add('"$ingredient" is not in inventory — not deducted.');
        return;
      }
      final inv = item.data();
      final converted = convertToInventoryUnit(amount * scale, unit, (inv['unit'] ?? '').toString());
      if (converted == null) {
        warnings.add('"$ingredient": unit "$unit" does not match "${inv['unit']}" — not deducted.');
        return;
      }
      var qty = converted.round();
      if (qty == 0 && converted > 0) qty = 1;
      if (qty == 0) return;
      needs[item.id] = (needs[item.id] ?? 0) + qty;
      names[item.id] = (inv['name'] ?? ingredient).toString();
    }

    final scale = kSizeScale[size] ?? 1.0;
    for (final r in drink.recipe) {
      final p = parseRecipeLine(r.name, r.amount);
      if (p != null) need(p.name, p.amount, p.unit, scale);
    }
    for (final addOn in addOns) {
      for (final e in drink.addOnEffects.where((e) => e.addOnName.toLowerCase() == addOn.toLowerCase())) {
        final p = parseEffect(e.effect);
        if (p != null) need(p.name, p.amount, p.unit, 1.0);
      }
    }
    if (cup != null) {
      needs[cup.id] = (needs[cup.id] ?? 0) + 1;
      names[cup.id] = (cup.data()['name'] ?? 'Cups').toString();
    } else {
      warnings.add('No "$size" cup item in inventory — cup not deducted.');
    }

    await _db.runTransaction((tx) async {
      final fresh = await tx.get(orderRef);
      if (fresh.data()?['stockDeducted'] == true) {
        tx.update(orderRef, {'status': 'preparing'}); // another device already did it
        return;
      }
      final refs = {for (final id in needs.keys) id: _db.collection('inventory').doc(id)};
      final snaps = {for (final e in refs.entries) e.key: await tx.get(e.value)};

      final used = <Map<String, dynamic>>[];
      for (final e in needs.entries) {
        final cur = (snaps[e.key]?.data()?['currentStock'] as num?)?.toInt() ?? 0;
        final next = cur - e.value < 0 ? 0 : cur - e.value;
        if (cur < e.value) warnings.add('${names[e.key]} ran out of stock.');
        tx.update(refs[e.key]!, {'currentStock': next});
        used.add({'item': names[e.key], 'used': cur - next});
      }
      tx.update(orderRef, {'status': 'preparing', 'stockDeducted': true, 'stockUsed': used});
    });

    return warnings;
  }

  /// Staff/admin: every completed ('done') order, newest first. One equality
  /// filter, so no composite index; date ranges are applied on the device.
  Stream<List<OrderDoc>> completedOrders() => _db
      .collection('orders')
      .where('status', isEqualTo: 'done')
      .snapshots()
      .map((s) => _byCreated(s.docs).map((d) => OrderDoc.fromMap(d.id, d.data())).toList());

  // ---------------- Commission remittances ----------------
  /// Staff: record a (simulated) remittance of [orders]' commission to B.A.I.
  /// Creates the remittance record and flags each order as remitted, which
  /// resets the commission due to zero.
  Future<void> remitCommission(List<OrderDoc> orders) async {
    if (orders.isEmpty) return;
    final amount = (orders.fold<double>(0, (s, o) => s + o.commission) * 100).round() / 100;
    final dates = orders.map((o) => o.completedOrCreated).whereType<DateTime>().toList()..sort();
    final remitRef = _db.collection('remittances').doc();

    const chunk = 400; // Firestore batches are limited to 500 writes
    for (var i = 0; i < orders.length; i += chunk) {
      final batch = _db.batch();
      if (i == 0) {
        batch.set(remitRef, {
          'cafeId': kCafeId,
          'amount': amount,
          'orderCount': orders.length,
          'periodStart': dates.isEmpty ? null : Timestamp.fromDate(dates.first),
          'periodEnd': dates.isEmpty ? null : Timestamp.fromDate(dates.last),
          'dateRemitted': FieldValue.serverTimestamp(),
        });
      }
      for (final o in orders.skip(i).take(chunk)) {
        batch.update(_db.collection('orders').doc(o.id), {
          'remitted': true,
          'remittanceId': remitRef.id,
        });
      }
      await batch.commit();
    }
  }

  /// Staff + admin: remittance history, newest first.
  Stream<List<Remittance>> remittances() => _db
      .collection('remittances')
      .snapshots()
      .map((s) => _byCreated(s.docs, field: 'dateRemitted').map((d) => Remittance.fromMap(d.id, d.data())).toList());

  /// Staff: Manage Payment — every order, used for today's totals.
  Stream<List<OrderDoc>> allOrders() => _db
      .collection('orders')
      .snapshots()
      .map((s) => _byCreated(s.docs).map((d) => OrderDoc.fromMap(d.id, d.data())).toList());

  // ---------------- Payment QR ----------------
  Stream<String?> paymentQrUrl() => _db
      .collection('settings')
      .doc('paymentQr')
      .snapshots()
      .map((d) => d.data()?['url']);

  Future<void> setPaymentQr(String url) =>
      _db.collection('settings').doc('paymentQr').set({'url': url});

  // ---------------- Vendor (B.A.I.) GCash QR — for subscription renewal ----------------
  // Separate from the cafe's own customer-facing QR above.
  Stream<String?> vendorQrUrl() => _db
      .collection('settings')
      .doc('vendorQr')
      .snapshots()
      .map((d) => d.data()?['url']);

  Future<void> setVendorQr(String url) =>
      _db.collection('settings').doc('vendorQr').set({'url': url});

  // ---------------- Subscription status ----------------
  Stream<SubscriptionStatus> subscriptionStatus() => _db
      .collection('settings')
      .doc('subscription')
      .snapshots()
      .map((d) => SubscriptionStatus.fromMap(d.data()));

  /// Admin: manual override — immediately activates, resets the billing cycle.
  Future<void> markAsPaid() async {
    final now = DateTime.now();
    final next = now.add(const Duration(days: 30));
    await _db.collection('settings').doc('subscription').set({
      'cafeName': 'Brew Haven',
      'plan': 'Pro — ₱500/month',
      'monthlyFee': 500,
      'isActive': true,
      'lastPaymentDate': Timestamp.fromDate(now),
      'nextBillingDate': Timestamp.fromDate(next),
    }, SetOptions(merge: true));

    await _db.collection('subscriptionPayments').add({
      'amount': 500,
      'status': 'paid',
      'source': 'manual',
      'imageUrl': null,
      'notes': null,
      'createdAt': FieldValue.serverTimestamp(),
      'decidedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin: immediately locks the app for customers and staff.
  Future<void> deactivateSubscription() =>
      _db.collection('settings').doc('subscription').set({'isActive': false}, SetOptions(merge: true));

  // ---------------- Subscription receipts / payment history ----------------
  /// Cafe side: submit a renewal receipt. Starts 'pending' — does NOT
  /// activate the subscription until an admin approves it.
  Future<void> submitSubscriptionReceipt(String imageUrl, String? notes) =>
      _db.collection('subscriptionPayments').add({
        'amount': 500,
        'status': 'pending',
        'source': 'receipt',
        'imageUrl': imageUrl,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'decidedAt': null,
      });

  /// Cafe side: is there a receipt awaiting admin review right now?
  Stream<SubscriptionPayment?> latestPendingReceipt() => _db
      .collection('subscriptionPayments')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) {
        if (s.docs.isEmpty) return null;
        final d = _byCreated(s.docs).first;
        return SubscriptionPayment.fromMap(d.id, d.data());
      });

  /// Admin: all receipts waiting for a decision.
  Stream<List<SubscriptionPayment>> pendingReceipts() => _db
      .collection('subscriptionPayments')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) => _byCreated(s.docs).map((d) => SubscriptionPayment.fromMap(d.id, d.data())).toList());

  /// Admin: approve a receipt — activates the subscription and logs the payment.
  Future<void> approveReceipt(String paymentId) async {
    final now = DateTime.now();
    final next = now.add(const Duration(days: 30));
    final batch = _db.batch();
    batch.update(_db.collection('subscriptionPayments').doc(paymentId), {
      'status': 'paid',
      'decidedAt': Timestamp.fromDate(now),
    });
    batch.set(_db.collection('settings').doc('subscription'), {
      'isActive': true,
      'lastPaymentDate': Timestamp.fromDate(now),
      'nextBillingDate': Timestamp.fromDate(next),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  /// Admin: decline a receipt — subscription stays inactive.
  Future<void> declineReceipt(String paymentId) => _db.collection('subscriptionPayments').doc(paymentId).update({
        'status': 'declined',
        'decidedAt': FieldValue.serverTimestamp(),
      });

  /// Admin: full subscription payment history (all statuses).
  Stream<List<SubscriptionPayment>> subscriptionPaymentHistory() => _db
      .collection('subscriptionPayments')
      .snapshots()
      .map((s) => _byCreated(s.docs).map((d) => SubscriptionPayment.fromMap(d.id, d.data())).toList());

  // ---------------- Starter data ----------------
  /// Populates the real 6-drink menu (with recipes + add-on effects) and
  /// the matching inventory items. Uses fixed doc IDs and .set(), so it's
  /// safe to run more than once — it overwrites rather than duplicates.
  Future<void> seedStarterData() async {
    final batch = _db.batch();

    const addOnEffects = [
      {'addOnName': 'Extra shot', 'effect': 'coffee_beans +10 g'},
      {'addOnName': 'Oat milk', 'effect': 'oat_milk +200 ml'},
      {'addOnName': 'Vanilla', 'effect': 'vanilla_syrup +15 ml'},
      {'addOnName': 'Caramel', 'effect': 'caramel_syrup +20 ml'},
      {'addOnName': 'Whipped cream', 'effect': 'whipped_cream +30 g'},
      {'addOnName': 'Boba pearls', 'effect': 'boba_pearls +50 g'},
    ];

    final drinks = <String, Map<String, dynamic>>{
      'drink_caramel_macchiato': {
        'name': 'Caramel Macchiato',
        'prices': [120, 145, 170],
        'available': true,
        'imageUrl': null,
        'recipe': [
          {'name': 'Coffee beans', 'amount': '18 g'},
          {'name': 'Milk', 'amount': '200 ml'},
          {'name': 'Caramel syrup', 'amount': '20 ml'},
        ],
        'addOnEffects': addOnEffects,
      },
      'drink_spanish_latte': {
        'name': 'Spanish Latte',
        'prices': [95, 110, 130],
        'available': true,
        'imageUrl': null,
        'recipe': [
          {'name': 'Coffee beans', 'amount': '16 g'},
          {'name': 'Milk', 'amount': '210 ml'},
          {'name': 'Condensed milk', 'amount': '15 ml'},
        ],
        'addOnEffects': addOnEffects,
      },
      'drink_strawberry_latte': {
        'name': 'Strawberry Latte',
        'prices': [110, 130, 155],
        'available': true,
        'imageUrl': null,
        'recipe': [
          {'name': 'Milk', 'amount': '200 ml'},
          {'name': 'Strawberry syrup', 'amount': '30 ml'},
        ],
        'addOnEffects': addOnEffects,
      },
      'drink_matcha_latte': {
        'name': 'Matcha Latte',
        'prices': [105, 125, 150],
        'available': true,
        'imageUrl': null,
        'recipe': [
          {'name': 'Matcha powder', 'amount': '10 g'},
          {'name': 'Milk', 'amount': '210 ml'},
        ],
        'addOnEffects': addOnEffects,
      },
      'drink_dark_choco': {
        'name': 'Dark Choco',
        'prices': [100, 115, 140],
        'available': true,
        'imageUrl': null,
        'recipe': [
          {'name': 'Choco syrup', 'amount': '35 ml'},
          {'name': 'Milk', 'amount': '200 ml'},
        ],
        'addOnEffects': addOnEffects,
      },
      'drink_cookies_and_cream': {
        'name': 'Cookies and Cream',
        'prices': [105, 120, 145],
        'available': true,
        'imageUrl': null,
        'recipe': [
          {'name': 'Cookies crumbs', 'amount': '25 g'},
          {'name': 'Milk', 'amount': '200 ml'},
          {'name': 'Vanilla syrup', 'amount': '10 ml'},
        ],
        'addOnEffects': addOnEffects,
      },
    };

    for (final entry in drinks.entries) {
      batch.set(_db.collection('drinks').doc(entry.key), entry.value);
    }

    // unit, category, currentStock, lowThreshold, criticalThreshold
    final inventory = <String, Map<String, dynamic>>{
      'inv_coffee_beans': {'name': 'Coffee beans', 'unit': 'g', 'category': 'ing', 'currentStock': 2000, 'lowThreshold': 500, 'criticalThreshold': 150},
      'inv_milk': {'name': 'Milk', 'unit': 'ml', 'category': 'ing', 'currentStock': 5000, 'lowThreshold': 1500, 'criticalThreshold': 500},
      'inv_caramel_syrup': {'name': 'Caramel syrup', 'unit': 'ml', 'category': 'ing', 'currentStock': 600, 'lowThreshold': 200, 'criticalThreshold': 80},
      'inv_condensed_milk': {'name': 'Condensed milk', 'unit': 'ml', 'category': 'ing', 'currentStock': 500, 'lowThreshold': 150, 'criticalThreshold': 50},
      'inv_strawberry_syrup': {'name': 'Strawberry syrup', 'unit': 'ml', 'category': 'ing', 'currentStock': 500, 'lowThreshold': 150, 'criticalThreshold': 50},
      'inv_matcha_powder': {'name': 'Matcha powder', 'unit': 'g', 'category': 'ing', 'currentStock': 300, 'lowThreshold': 100, 'criticalThreshold': 30},
      'inv_choco_syrup': {'name': 'Choco syrup', 'unit': 'ml', 'category': 'ing', 'currentStock': 600, 'lowThreshold': 200, 'criticalThreshold': 80},
      'inv_cookies_crumbs': {'name': 'Cookies crumbs', 'unit': 'g', 'category': 'ing', 'currentStock': 400, 'lowThreshold': 120, 'criticalThreshold': 40},
      'inv_vanilla_syrup': {'name': 'Vanilla syrup', 'unit': 'ml', 'category': 'ing', 'currentStock': 400, 'lowThreshold': 150, 'criticalThreshold': 60},
      'inv_oat_milk': {'name': 'Oat milk', 'unit': 'ml', 'category': 'ing', 'currentStock': 3000, 'lowThreshold': 1000, 'criticalThreshold': 400},
      'inv_boba_pearls': {'name': 'Boba pearls', 'unit': 'g', 'category': 'ing', 'currentStock': 600, 'lowThreshold': 250, 'criticalThreshold': 100},
      'inv_whipped_cream': {'name': 'Whipped cream', 'unit': 'g', 'category': 'ing', 'currentStock': 500, 'lowThreshold': 150, 'criticalThreshold': 50},
      'inv_small_cups': {'name': 'Small cups', 'unit': 'pcs', 'category': 'cup', 'currentStock': 100, 'lowThreshold': 30, 'criticalThreshold': 10},
      'inv_medium_cups': {'name': 'Medium cups', 'unit': 'pcs', 'category': 'cup', 'currentStock': 100, 'lowThreshold': 30, 'criticalThreshold': 10},
      'inv_large_cups': {'name': 'Large cups', 'unit': 'pcs', 'category': 'cup', 'currentStock': 80, 'lowThreshold': 25, 'criticalThreshold': 10},
    };

    for (final entry in inventory.entries) {
      batch.set(_db.collection('inventory').doc(entry.key), entry.value);
    }

    await batch.commit();
  }
}

/// Sorts documents by their createdAt timestamp on the device instead of in
/// the Firestore query. A query that combines where() with orderBy() needs a
/// composite index (without one, the stream errors and screens spin forever),
/// and orderBy also silently drops documents that have no createdAt.
/// Documents with no date are kept and placed last.
List<QueryDocumentSnapshot<Map<String, dynamic>>> _byCreated(
  Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
  bool descending = true,
  String field = 'createdAt',
}) {
  DateTime? ts(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
      (d.data()[field] as Timestamp?)?.toDate();
  final list = docs.toList();
  list.sort((a, b) {
    final da = ts(a), db = ts(b);
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return descending ? db.compareTo(da) : da.compareTo(db);
  });
  return list;
}

/// Sorts drinks A-Z on the device. A query that filters on `available` and
/// orders by `name` needs a composite Firestore index; without it the menu
/// stream errors and the Menu screen shows "Could not load the menu".
List<Drink> _byName(List<Drink> drinks) =>
    drinks..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));