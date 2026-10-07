import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/order_state.dart';
import '../../theme.dart';
import 'home_screen.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});
  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        final order = context.read<OrderState>();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
          (route) => false,
        );
        // Clear the order only AFTER the old screens (Menu, Cup Size, Review...)
        // are gone. Clearing first made them rebuild with no drink and crash.
        WidgetsBinding.instance.addPostFrameCallback((_) => order.reset());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3D6),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: BaiColors.mint, width: 5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 48, color: Color(0xFF3D8A5F)),
              const SizedBox(height: 10),
              const Text('Order placed!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('See you at the counter.'),
            ],
          ),
        ),
      ),
    );
  }
}