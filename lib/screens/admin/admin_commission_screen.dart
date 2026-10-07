import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

/// Time windows for the commission list.
enum CommissionRange {
  thisWeek('This week'),
  thisMonth('This month'),
  last90Days('Past 90 days');

  final String label;
  const CommissionRange(this.label);

  /// Start of the window. Week starts Monday, month starts on the 1st,
  /// "past 90 days" is rolling back from now.
  DateTime start() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case CommissionRange.thisWeek:
        return today.subtract(Duration(days: now.weekday - 1));
      case CommissionRange.thisMonth:
        return DateTime(now.year, now.month, 1);
      case CommissionRange.last90Days:
        return today.subtract(const Duration(days: 90));
    }
  }
}

class AdminCommissionScreen extends StatefulWidget {
  const AdminCommissionScreen({super.key});
  @override
  State<AdminCommissionScreen> createState() => _AdminCommissionScreenState();
}

class _AdminCommissionScreenState extends State<AdminCommissionScreen> {
  final _fs = FirestoreService();
  static final _money = NumberFormat('#,##0.00');

  CommissionRange _range = CommissionRange.thisMonth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Commissions'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: CommissionRange.values.map((r) {
                  return ChoiceChip(
                    label: Text(r.label),
                    selected: _range == r,
                    selectedColor: BaiColors.lavender,
                    backgroundColor: Colors.white,
                    onSelected: (_) => setState(() => _range = r),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<OrderDoc>>(
              stream: _fs.ordersSince(_range.start()),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Could not load commissions: ${snap.error}', textAlign: TextAlign.center),
                    ),
                  );
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                final orders = snap.data!;
                final totalCommission = orders.fold<double>(0, (sum, o) => sum + o.commission);
                final totalSales = orders.fold<int>(0, (sum, o) => sum + o.total);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: BaiColors.butter,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Commission · ${_range.label}',
                              style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 2),
                          Text('₱${_money.format(totalCommission)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
                          const SizedBox(height: 6),
                          Text(
                            '${orders.length} orders · ₱${_money.format(totalSales)} in sales · '
                            '${(kCommissionRate * 100).toStringAsFixed(0)}% rate',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (orders.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: Text('No orders in this period.')),
                      )
                    else
                      ...orders.map((o) => _CommissionTile(order: o)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CommissionTile extends StatelessWidget {
  final OrderDoc order;
  const _CommissionTile({required this.order});

  static final _dateFmt = DateFormat('MMM d, y · h:mm a');

  @override
  Widget build(BuildContext context) {
    final d = order.createdAt;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: BaiColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${order.drinkName} (${order.size})',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  d != null ? _dateFmt.format(d) : 'Just now',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text('Order total ₱${order.total}',
                    style: const TextStyle(fontSize: 11, color: Colors.black38)),
              ],
            ),
          ),
          Text('+₱${NumberFormat('#,##0.00').format(order.commission)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D8A5F))),
        ],
      ),
    );
  }
}