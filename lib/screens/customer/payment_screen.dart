import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../state/order_state.dart';
import '../../theme.dart';
import 'loading_screen.dart';

/// GCash is the only payment method — no Cash option. This screen shows
/// the order summary, the cafe's GCash QR, and a proof-of-payment upload.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _fs = FirestoreService();
  final _cloudinary = CloudinaryService();
  bool _placing = false;

  Future<void> _pickProof() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null && mounted) {
      context.read<OrderState>().setProofImage(File(picked.path));
    }
  }

  Future<void> _placeOrder() async {
    final order = context.read<OrderState>();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    setState(() => _placing = true);

    final proofUrl = await _cloudinary.upload(order.proofImage!);
    if (proofUrl == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Proof upload failed — try again.')));
        setState(() => _placing = false);
      }
      return;
    }

    final doc = OrderDoc(
      id: '',
      customerId: uid,
      drinkName: order.drink!.name,
      size: OrderState.sizeNames[order.sizeIndex],
      addOns: order.selectedAddOns.map((a) => a.name).toList(),
      total: order.total,
      paymentMethod: order.paymentMethod, // always 'gcash'
      status: 'new',
      proofUrl: proofUrl,
    );
    await _fs.placeOrder(doc);

    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoadingScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderState>();
    if (order.drink == null) return const SizedBox.shrink(); // order already placed and cleared
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: BaiColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Column(
              children: [
                _row('${order.drink!.name} (${OrderState.sizeNames[order.sizeIndex]})', '₱${order.basePrice}'),
                for (final a in order.selectedAddOns) _row(a.name, '₱${a.price}'),
                const Divider(),
                _row('Total', '₱${order.total}', bold: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Icon(Icons.smartphone_outlined, size: 18, color: BaiColors.ink),
              SizedBox(width: 8),
              Text('Pay with GCash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Column(
              children: [
                StreamBuilder<String?>(
                  stream: _fs.paymentQrUrl(),
                  builder: (context, snap) {
                    if (snap.data == null || snap.data!.isEmpty) {
                      return const SizedBox(height: 140, child: Center(child: Text('QR not set up yet')));
                    }
                    return Image.network(snap.data!, height: 160);
                  },
                ),
                const SizedBox(height: 8),
                const Text('Scan with GCash', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickProof,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BaiColors.lavender, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.camera_alt_outlined, size: 18, color: BaiColors.ink),
                      SizedBox(width: 8),
                      Text('Upload proof of payment'),
                    ],
                  ),
                  if (order.proofImage != null) ...[
                    const SizedBox(height: 10),
                    Image.file(order.proofImage!, height: 130),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BaiColors.mint,
              foregroundColor: BaiColors.ink,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
            onPressed: (order.canPlaceOrder && !_placing) ? _placeOrder : null,
            child: _placing
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Place order'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
            Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      );
}