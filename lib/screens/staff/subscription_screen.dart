import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../theme.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _fs = FirestoreService();
  final _cloudinary = CloudinaryService();
  static final _dateFmt = DateFormat('MMM d, y');

  bool _renewing = false;
  File? _receiptImage;
  final _notes = TextEditingController();
  bool _submitting = false;

  Future<void> _pickReceipt() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _receiptImage = File(picked.path));
  }

  Future<void> _submit() async {
    if (_receiptImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload your receipt first')));
      return;
    }
    setState(() => _submitting = true);
    final url = await _cloudinary.upload(_receiptImage!, folder: 'bai/receipts');
    if (url == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed — try again.')));
        setState(() => _submitting = false);
      }
      return;
    }
    await _fs.submitSubscriptionReceipt(url, _notes.text.trim().isEmpty ? null : _notes.text.trim());
    if (mounted) {
      setState(() { _submitting = false; _renewing = false; _receiptImage = null; _notes.clear(); });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt submitted — waiting for approval.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Subscription')),
      body: StreamBuilder<SubscriptionStatus>(
        stream: _fs.subscriptionStatus(),
        builder: (context, subSnap) {
          if (!subSnap.hasData) return const Center(child: CircularProgressIndicator());
          final sub = subSnap.data!;

          return StreamBuilder<SubscriptionPayment?>(
            stream: _fs.latestPendingReceipt(),
            builder: (context, pendingSnap) {
              final pending = pendingSnap.data;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                          Text(sub.plan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
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
                          const SizedBox(height: 8),
                          Text(
                              'Next billing: ${sub.nextBillingDate != null ? _dateFmt.format(sub.nextBillingDate!) : 'No date'}',
                              style: const TextStyle(color: Colors.black54, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (pending != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: BaiColors.butter, borderRadius: BorderRadius.circular(18)),
                        child: const Row(
                          children: [
                            Icon(Icons.hourglass_empty, color: BaiColors.ink),
                            SizedBox(width: 10),
                            Expanded(child: Text('Pending Approval — your receipt is waiting for review.')),
                          ],
                        ),
                      )
                    else if (!_renewing)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BaiColors.mint,
                          foregroundColor: BaiColors.ink,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        ),
                        onPressed: () => setState(() => _renewing = true),
                        child: const Text('Renew'),
                      ),

                    if (_renewing && pending == null) ...[
                      const SizedBox(height: 16),
                      const Text('Pay ₱500 to B.A.I. via GCash.', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: StreamBuilder<String?>(
                          stream: _fs.vendorQrUrl(),
                          builder: (context, qrSnap) {
                            if (qrSnap.data == null || qrSnap.data!.isEmpty) {
                              return const SizedBox(height: 140, child: Center(child: Text("B.A.I.'s QR isn't set up yet")));
                            }
                            return Image.network(qrSnap.data!, height: 170);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickReceipt,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: BaiColors.lavender, width: 2),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined, size: 18, color: BaiColors.ink),
                                  SizedBox(width: 8),
                                  Text('Upload receipt'),
                                ],
                              ),
                              if (_receiptImage != null) ...[
                                const SizedBox(height: 10),
                                Image.file(_receiptImage!, height: 140),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _notes,
                        decoration: const InputDecoration(hintText: 'Notes (optional)'),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BaiColors.mint,
                          foregroundColor: BaiColors.ink,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        ),
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Submit'),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}