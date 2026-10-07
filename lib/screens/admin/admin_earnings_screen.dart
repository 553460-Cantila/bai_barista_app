import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';
import '../../utils/date_text.dart';
import '../../utils/period_range.dart';

/// Admin: what B.A.I. has actually earned — approved subscription payments
/// plus commission the cafe has remitted. Commission only counts once it has
/// been remitted (Mark as remitted on the cafe's Due Payments screen).
class AdminEarningsScreen extends StatefulWidget {
  const AdminEarningsScreen({super.key});
  @override
  State<AdminEarningsScreen> createState() => _AdminEarningsScreenState();
}

class _Entry {
  final DateTime? date;
  final String type; // 'Subscription' | 'Commission'
  final double amount;
  const _Entry(this.date, this.type, this.amount);
}

class _AdminEarningsScreenState extends State<AdminEarningsScreen> {
  final _fs = FirestoreService();
  static final _money = NumberFormat('#,##0.00');

  late final Stream<List<SubscriptionPayment>> _payments = _fs.subscriptionPaymentHistory();
  late final Stream<List<Remittance>> _remittances = _fs.remittances();
  PeriodRange _range = PeriodRange.days30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Earnings report')),
      body: StreamBuilder<List<SubscriptionPayment>>(
        stream: _payments,
        builder: (context, paySnap) {
          if (paySnap.hasError) {
            return Center(child: Text('Could not load.\n${paySnap.error}', textAlign: TextAlign.center));
          }
          return StreamBuilder<List<Remittance>>(
            stream: _remittances,
            builder: (context, remSnap) {
              if (remSnap.hasError) {
                return Center(child: Text('Could not load.\n${remSnap.error}', textAlign: TextAlign.center));
              }
              if (!paySnap.hasData || !remSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Every earning entry: approved subscription payments + remittances.
              final entries = <_Entry>[
                ...paySnap.data!
                    .where((p) => p.status == 'paid')
                    .map((p) => _Entry(p.decidedAt ?? p.createdAt, 'Subscription', p.amount.toDouble())),
                ...remSnap.data!.map((r) => _Entry(r.dateRemitted, 'Commission', r.amount)),
              ];

              final start = _range.start();
              final inRange = entries.where((e) => e.date != null && !e.date!.isBefore(start)).toList()
                ..sort((a, b) => b.date!.compareTo(a.date!));
              final undated = entries.where((e) => e.date == null).length;

              final subscriptionTotal =
                  inRange.where((e) => e.type == 'Subscription').fold<double>(0, (s, e) => s + e.amount);
              final commissionTotal =
                  inRange.where((e) => e.type == 'Commission').fold<double>(0, (s, e) => s + e.amount);
              final total = subscriptionTotal + commissionTotal;

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
                        Text('Total earnings · ${_range.label}',
                            style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 2),
                        Text('₱${_money.format(total)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MetricRow(label: 'Subscription earnings', value: '₱${_money.format(subscriptionTotal)}'),
                  _MetricRow(label: 'Commission earnings', value: '₱${_money.format(commissionTotal)}'),
                  if (undated > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$undated ${undated == 1 ? 'entry has' : 'entries have'} no date and '
                        "${undated == 1 ? "isn't" : "aren't"} counted.",
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  const SizedBox(height: 22),
                  const Text('Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (inRange.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No earnings in this period.', style: TextStyle(color: Colors.black54)),
                    )
                  else
                    ...inRange.map((e) => _EntryTile(entry: e)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label, value;
  const _MetricRow({required this.label, required this.value});

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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final _Entry entry;
  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isSub = entry.type == 'Subscription';
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isSub ? BaiColors.lavender : BaiColors.mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(entry.type, style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(formatDateTime(entry.date), style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
          Text('+₱${NumberFormat('#,##0.00').format(entry.amount)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D8A5F))),
        ],
      ),
    );
  }
}