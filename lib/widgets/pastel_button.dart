  import 'package:flutter/material.dart';

class PastelButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color shadowColor;
  final Color textColor;
  final VoidCallback onTap;
  final bool outlined;

  const PastelButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color = const Color(0xFFFCE883),
    this.shadowColor = const Color(0xFFE2C86F),
    this.textColor = const Color(0xFF6B4A3A),
    this.outlined = false,
  });

  @override
  State<PastelButton> createState() => _PastelButtonState();
}

class _PastelButtonState extends State<PastelButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: double.infinity,
        margin: EdgeInsets.only(top: _pressed ? 4 : 0, bottom: _pressed ? 0 : 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: widget.outlined ? Colors.white : widget.color,
          borderRadius: BorderRadius.circular(22),
          border: widget.outlined ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: widget.shadowColor,
              offset: Offset(0, _pressed ? 1 : 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: widget.textColor, size: 20),
              const SizedBox(width: 10),
            ],
            Text(
              widget.label,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: widget.textColor),
            ),
          ],
        ),
      ),
    );
  }
}