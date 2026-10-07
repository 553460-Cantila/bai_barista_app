import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../theme.dart';

/// Generic QR upload/replace screen. Used for both the cafe's
/// customer-facing GCash QR and (from the Admin Panel) B.A.I.'s own
/// vendor QR for subscription renewals — same UI, different target.
class UploadQrScreen extends StatefulWidget {
  final String title;
  final String description;
  final Stream<String?> qrStream;
  final Future<void> Function(String url) onSave;

  const UploadQrScreen({
    super.key,
    this.title = 'Update payment QR',
    this.description = 'This QR is shown to customers who pay via GCash.',
    required this.qrStream,
    required this.onSave,
  });

  /// Convenience constructor for the cafe's own customer-facing QR
  /// (the original, most common use of this screen).
  factory UploadQrScreen.cafeQr(FirestoreService fs) => UploadQrScreen(
        qrStream: fs.paymentQrUrl(),
        onSave: fs.setPaymentQr,
      );

  @override
  State<UploadQrScreen> createState() => _UploadQrScreenState();
}

class _UploadQrScreenState extends State<UploadQrScreen> {
  final _cloudinary = CloudinaryService();
  File? _newImage;
  bool _uploading = false;

  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _newImage = File(picked.path));
  }

  Future<void> _save() async {
    if (_newImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick an image first')));
      return;
    }
    setState(() => _uploading = true);
    final url = await _cloudinary.upload(_newImage!);
    if (url != null) {
      await widget.onSave(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New QR saved.')));
        Navigator.pop(context);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed — check your Cloudinary settings.')));
    }
    if (mounted) setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text(widget.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.description),
            const SizedBox(height: 16),
            const Text('Current QR', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: StreamBuilder<String?>(
                stream: widget.qrStream,
                builder: (context, snap) {
                  if (snap.data == null || snap.data!.isEmpty) {
                    return const SizedBox(height: 150, child: Center(child: Text('No QR set yet')));
                  }
                  return Image.network(snap.data!, height: 180);
                },
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _pick,
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
                        Flexible(
                          child: Text('Upload new QR — tap to browse your gallery', textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                    if (_newImage != null) ...[
                      const SizedBox(height: 10),
                      Image.file(_newImage!, height: 140),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24), // was Spacer() — incompatible with a scrollable parent
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BaiColors.mint,
                foregroundColor: BaiColors.ink,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              onPressed: _uploading ? null : _save,
              child: _uploading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}