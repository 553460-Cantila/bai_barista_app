import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';
import '../../utils/date_text.dart';

/// Staff: what the cafe currently owes B.A.I. — any unpaid subscription plus
/// the 5% commission on completed orders that hasn't been remitted yet.
class DuePaymentsScreen extends StatefulWidget {
  const DuePaymentsScreen({super.key});
  @override
  State<DuePaymentsScreen> createState() => _DuePaymentsScreenState();
}

class _DuePaymentsScreenState extends State<DuePaymentsScreen> {
  final _fs = FirestoreService();
  static final _money = NumberFormat('#,##0.00');

  late final Stream<List<OrderDoc>> _orders = _fs.completedOrders();
  late final Stream<SubscriptionStatus> _sub = _fs.subscriptionStatus();
  late final Stream<List<SubscriptionPayment>> _payments = _fs.subscriptionPaymentHistory();
  late final Stream<List<Remittance>> _remittances = _fs.remittances();

  bool _remitting = false;

  Future<void> _remit(List<OrderDoc> due) async {
    final total = due.fold<double>(0, (s, o) => s + o.commission);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as remitted?'),
        content: Text(
          'This records ₱${_money.format(total)} from ${due.length} '
          '${due.length == 1 ? 'order' : 'orders'} as sent to B.A.I. and resets your commission due to ₱0.00.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mark as remitted')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _remitting = true);
    try {
      await _fs.remitCommission(due);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Remitted ₱${_money.format(total)} to B.A.I.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not record remittance: $e')));
      }
    } finally {
      if (mounted) setState(() => _remitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Due payments')),
      body: StreamBuilder<List<OrderDoc>>(
        stream: _orders,
        builder: (context, orderSnap) {
          if (orderSnap.hasError) {
            return Center(child: Text('Could not load.\n${orderSnap.error}', textAlign: TextAlign.center));
          }
          if (!orderSnap.hasData) return const Center(child: CircularProgressIndicator());

          // Completed orders whose commission hasn't been remitted yet.
          final due = orderSnap.data!.where((o) => !o.remitted).toList();
          final commissionDue = due.fold<double>(0, (s, o) => s + o.commission);

          return StreamBuilder<SubscriptionStatus>(
            stream: _sub,
            builder: (context, subSnap) {
              final sub = subSnap.data;
              // An inactive subscription means this month's fee hasn't been paid.
              final subscriptionDue =
                  (sub != null && !sub.isActive) ? (sub.monthlyFee > 0 ? sub.monthlyFee : kMonthlyFee) : 0;
              final totalDue = subscriptionDue + commissionDue;

              return ListView(
                padding: const EdgeInsets.all(20),
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
                        const Text('Total amount due to B.A.I.',
                            style: TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 2),
                        Text('₱${_money.format(totalDue)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
                        const SizedBox(height: 10),
                        _line('Unpaid subscription', '₱${_money.format(subscriptionDue)}'),
                        _line('Commission due (${due.length} ${due.length == 1 ? 'order' : 'orders'})',
                            '₱${_money.format(commissionDue)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BaiColors.mint,
                      foregroundColor: BaiColors.ink,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    onPressed: (_remitting || due.isEmpty) ? null : () => _remit(due),
                    child: _remitting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Mark as remitted'),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Commission is transferred to B.A.I. monthly. Marking it as remitted only clears the '
                      'commission — the subscription is renewed from the Subscription screen.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),

                  // ---------- Commission breakdown ----------
                  const SizedBox(height: 22),
                  const Text('Commission breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (due.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No unremitted commission.', style: TextStyle(color: Colors.black54)),
                    )
                  else
                    ...due.map((o) => _CommissionTile(order: o)),

                  // ---------- Subscription history ----------
                  const SizedBox(height: 22),
                  const Text('Subscription history', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  _SubscriptionHistory(stream: _payments),

                  // ---------- Remittance history ----------
                  const SizedBox(height: 22),
                  const Text('Remittance history', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  _RemittanceHistory(stream: _remittances),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: BaiColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white, width: 4),
    );

class _CommissionTile extends StatelessWidget {
  final OrderDoc order;
  const _CommissionTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length > 6 ? order.id.substring(0, 6) : order.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${shortId.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(formatDateTime(order.completedOrCreated),
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
                Text('Order total ₱${order.total}', style: const TextStyle(fontSize: 11, color: Colors.black38)),
              ],
            ),
          ),
          Text('₱${NumberFormat('#,##0.00').format(order.commission)}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SubscriptionHistory extends StatelessWidget {
  final Stream<List<SubscriptionPayment>> stream;
  const _SubscriptionHistory({required this.stream});

  static const _statusColor = {
    'paid': BaiColors.mint,
    'pending': BaiColors.butter,
    'declined': BaiColors.red,
  };
  static const _statusLabel = {'paid': 'Paid', 'pending': 'Pending', 'declined': 'Declined'};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SubscriptionPayment>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Text('Could not load: ${snap.error}', style: const TextStyle(color: Colors.black54));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final payments = snap.data!;
        if (payments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No subscription payments yet.', style: TextStyle(color: Colors.black54)),
          );
        }
        return Column(
          children: payments.map((p) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('₱${p.amount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(formatDateTime(p.decidedAt ?? p.createdAt),
                            style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor[p.status] ?? Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_statusLabel[p.status] ?? p.status, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _RemittanceHistory extends StatelessWidget {
  final Stream<List<Remittance>> stream;
  const _RemittanceHistory({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Remittance>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Text('Could not load: ${snap.error}', style: const TextStyle(color: Colors.black54));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!;
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No remittances yet.', style: TextStyle(color: Colors.black54)),
          );
        }
        return Column(
          children: items.map((r) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: _cardDecoration(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatDateTime(r.dateRemitted), style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${r.orderCount} ${r.orderCount == 1 ? 'order' : 'orders'}',
                            style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  Text('₱${NumberFormat('#,##0.00').format(r.amount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}