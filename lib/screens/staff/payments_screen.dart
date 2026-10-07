import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';
import '../../utils/date_text.dart';
import 'upload_qr_screen.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  bool _isToday(DateTime? d) {
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Manage payment')),
      body: StreamBuilder<List<OrderDoc>>(
        stream: fs.allOrders(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Could not load.\n${snap.error}', textAlign: TextAlign.center));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final todays = snap.data!.where((o) => _isToday(o.createdAt)).toList();
          final gcashTotal = todays.fold<int>(0, (t, o) => t + o.total);
          final paidCount = todays.where((o) => o.proofUrl != null && o.proofUrl!.isNotEmpty).length;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Receipts from customer orders — all paid via GCash.'),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BaiColors.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.smartphone_outlined, size: 16, color: BaiColors.ink),
                        SizedBox(width: 6),
                        Text("Today's total (GCash)", style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                    Text('₱$gcashTotal', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    Text('$paidCount of ${todays.length} orders confirmed',
                        style: const TextStyle(fontSize: 12, color: Colors.black45)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Recent receipts', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (todays.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No orders yet today.', style: TextStyle(color: Colors.black54)),
                ),
              ...todays.map((o) {
                final waiting = o.proofUrl == null || o.proofUrl!.isEmpty;
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
                            Text('Order #${o.id.substring(0, 5).toUpperCase()} — ₱${o.total}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              'GCash · ${formatDateTime(o.createdAt)}',
                              style: const TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      if (!waiting)
                        TextButton(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => Dialog(child: Image.network(o.proofUrl!)),
                          ),
                          child: const Text('View proof'),
                        )
                      else if (waiting)
                        _Tag(text: 'waiting', icon: Icons.hourglass_empty, color: BaiColors.butter)
                      else
                        _Tag(text: 'paid', icon: Icons.check, color: BaiColors.mint),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BaiColors.mint,
                  foregroundColor: BaiColors.ink,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                onPressed: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => UploadQrScreen.cafeQr(fs))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.refresh, size: 18, color: BaiColors.ink),
                    SizedBox(width: 8),
                    Text('Upload new QR code'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}



class _Tag extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;
  const _Tag({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: BaiColors.ink),
            const SizedBox(width: 3),
          ],
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}