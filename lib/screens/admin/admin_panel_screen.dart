import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';
import '../staff/upload_qr_screen.dart';
import 'admin_history_screen.dart';
import 'admin_commission_screen.dart';
import 'admin_earnings_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  static final _dateFmt = DateFormat('MMM d, y');

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Admin Panel')),
      body: StreamBuilder<SubscriptionStatus>(
        stream: fs.subscriptionStatus(),
        builder: (context, subSnap) {
          if (!subSnap.hasData) return const Center(child: CircularProgressIndicator());
          final sub = subSnap.data!;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ---------- Subscription management ----------
              const Text('Subscription', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BaiColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sub.cafeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    Text(sub.plan, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: sub.isActive ? const Color(0xFF3D8A5F) : const Color(0xFFC1554A)),
                        const SizedBox(width: 6),
                        Text(sub.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: sub.isActive ? const Color(0xFF3D8A5F) : const Color(0xFFC1554A),
                            )),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _infoRow('Last payment', sub.lastPaymentDate != null ? _dateFmt.format(sub.lastPaymentDate!) : 'No date'),
                    _infoRow('Next billing', sub.nextBillingDate != null ? _dateFmt.format(sub.nextBillingDate!) : 'No date'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BaiColors.mint,
                              foregroundColor: BaiColors.ink,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () async {
                              await fs.markAsPaid();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(content: Text('Marked as paid — subscription active.')));
                              }
                            },
                            child: const Text('Mark as Paid'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BaiColors.red,
                              foregroundColor: BaiColors.ink,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () async {
                              await fs.deactivateSubscription();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(content: Text('Deactivated — app is now locked.')));
                              }
                            },
                            child: const Text('Deactivate'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              OutlinedButton.icon(
                icon: const Icon(Icons.qr_code),
                label: const Text("Update B.A.I.'s vendor GCash QR"),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UploadQrScreen(
                      title: "B.A.I.'s GCash QR",
                      description: 'Shown to the cafe when they renew their subscription — separate from the '
                          "cafe's own customer-facing QR.",
                      qrStream: fs.vendorQrUrl(),
                      onSave: fs.setVendorQr,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ---------- Earnings report ----------
              const Text('Earnings Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const AdminEarningsScreen())),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BaiColors.mint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bar_chart_outlined, color: BaiColors.ink),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Earnings report',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Subscriptions + remitted commission',
                                style: TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ---------- Commissions ----------
              const Text('Commissions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              StreamBuilder<List<OrderDoc>>(
                stream: fs.ordersSince(CommissionRange.thisMonth.start()),
                builder: (context, snap) {
                  final orders = snap.data ?? const <OrderDoc>[];
                  final total = orders.fold<double>(0, (sum, o) => sum + o.commission);
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const AdminCommissionScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: BaiColors.butter,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_outlined, color: BaiColors.ink),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(snap.hasData ? '₱${NumberFormat('#,##0.00').format(total)}' : '—',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                Text('accrued this month · ${orders.length} orders',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // ---------- Pending receipts ----------
              const Text('Pending Receipts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              StreamBuilder<List<SubscriptionPayment>>(
                stream: fs.pendingReceipts(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('Could not load receipts: ${snap.error}',
                          style: const TextStyle(color: Colors.black54)),
                    );
                  }
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final receipts = snap.data!;
                  if (receipts.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Nothing waiting for review.', style: TextStyle(color: Colors.black54)),
                    );
                  }
                  return Column(
                    children: receipts.map((r) => _ReceiptCard(payment: r, fs: fs, dateFmt: _dateFmt)).toList(),
                  );
                },
              ),

              const SizedBox(height: 20),
              OutlinedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text('View subscription payment history'),
                onPressed: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHistoryScreen())),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _infoRow(String label, String value) => Padding(
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

class _ReceiptCard extends StatelessWidget {
  final SubscriptionPayment payment;
  final FirestoreService fs;
  final DateFormat dateFmt;
  const _ReceiptCard({required this.payment, required this.fs, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BaiColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (payment.imageUrl == null) return;
              showDialog(
                context: context,
                builder: (_) => Dialog(child: Image.network(payment.imageUrl!)),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: payment.imageUrl != null
                  ? Image.network(payment.imageUrl!, width: 64, height: 64, fit: BoxFit.cover)
                  : Container(width: 64, height: 64, color: Colors.white,
                      child: const Icon(Icons.receipt_long_outlined)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('₱${payment.amount} claimed', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  payment.createdAt != null ? 'Submitted ${dateFmt.format(payment.createdAt!)}' : 'No date',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (payment.notes != null && payment.notes!.isNotEmpty)
                  Text('"${payment.notes}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BaiColors.mint,
                          foregroundColor: BaiColors.ink,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => fs.approveReceipt(payment.id),
                        child: const Text('Approve', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BaiColors.red,
                          foregroundColor: BaiColors.ink,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => fs.declineReceipt(payment.id),
                        child: const Text('Decline', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}