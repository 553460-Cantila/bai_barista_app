import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';
import '../../utils/period_range.dart';

/// Staff: the cafe's financial performance over the last 7 / 30 / 90 days.
/// Only completed ('done' / picked up) orders are counted.
class SalesSummaryScreen extends StatefulWidget {
  const SalesSummaryScreen({super.key});
  @override
  State<SalesSummaryScreen> createState() => _SalesSummaryScreenState();
}

class _Seller {
  final String name;
  int qty = 0;
  int revenue = 0;
  _Seller(this.name);
}

class _SalesSummaryScreenState extends State<SalesSummaryScreen> {
  final _fs = FirestoreService();
  static final _money = NumberFormat('#,##0.00');

  // Kept in a field so changing the filter doesn't re-subscribe to Firestore.
  late final Stream<List<OrderDoc>> _orders = _fs.completedOrders();
  PeriodRange _range = PeriodRange.days30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Sales summary')),
      body: StreamBuilder<List<OrderDoc>>(
        stream: _orders,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Could not load.\n${snap.error}', textAlign: TextAlign.center));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final start = _range.start();
          final all = snap.data!;
          // Period is based on when the order was completed (falls back to the
          // order date for orders completed before completion dates were saved).
          final inRange = all.where((o) {
            final d = o.completedOrCreated;
            return d != null && !d.isBefore(start);
          }).toList();
          final undated = all.where((o) => o.completedOrCreated == null).length;

          final totalSales = inRange.fold<int>(0, (s, o) => s + o.total);
          final totalCommission = inRange.fold<double>(0, (s, o) => s + o.commission);
          final subscriptionCost = kMonthlyFee / 30 * _range.days;
          final netProfit = totalSales - totalCommission - subscriptionCost;

          final sellers = <String, _Seller>{};
          for (final o in inRange) {
            final s = sellers.putIfAbsent(o.drinkName, () => _Seller(o.drinkName));
            s.qty += 1;
            s.revenue += o.total;
          }
          final best = sellers.values.toList()
            ..sort((a, b) {
              final c = b.qty.compareTo(a.qty);
              return c != 0 ? c : b.revenue.compareTo(a.revenue);
            });

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Wrap(
                spacing: 8,
                children: PeriodRange.values.map((r) {
                  return ChoiceChip(
                    label: Text(r.label),
                    selected: _range == r,
                    selectedColor: BaiColors.lavender,
                    backgroundColor: Colors.white,
                    onSelected: (_) => setState(() => _range = r),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Net profit headline
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
                    Text('Net profit · ${_range.label}',
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 2),
                    Text(
                      '${netProfit < 0 ? '-' : ''}₱${_money.format(netProfit.abs())}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: netProfit < 0 ? const Color(0xFFC1554A) : BaiColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${inRange.length} completed orders',
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _MetricRow(label: 'Total sales', hint: 'Gross revenue', value: '₱${_money.format(totalSales)}'),
              _MetricRow(
                label: 'Total commission (${(kCommissionRate * 100).toStringAsFixed(0)}%)',
                hint: 'Owed to B.A.I.',
                value: '-₱${_money.format(totalCommission)}',
              ),
              _MetricRow(
                label: 'Subscription cost',
                hint: '₱$kMonthlyFee ÷ 30 × ${_range.days} days',
                value: '-₱${_money.format(subscriptionCost)}',
              ),

              if (undated > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '$undated completed ${undated == 1 ? 'order has' : 'orders have'} no date and '
                    "${undated == 1 ? "isn't" : "aren't"} counted.",
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),

              const SizedBox(height: 22),
              const Text('Best sellers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (best.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No completed orders in this period.', style: TextStyle(color: Colors.black54)),
                )
              else
                ...best.take(5).toList().asMap().entries.map((e) {
                  final s = e.value;
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
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: BaiColors.lavender,
                          child: Text('${e.key + 1}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BaiColors.ink)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${s.qty} sold', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ),
                        Text('₱${_money.format(s.revenue)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label, hint, value;
  const _MetricRow({required this.label, required this.hint, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(hint, style: const TextStyle(fontSize: 11, color: Colors.black45)),
              ],
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}