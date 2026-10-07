import 'package:flutter/material.dart';
import '../theme.dart';

/// One cell in the home-screen grid: either a floating decor icon
/// (cup/cookie gif) or a big square action button.
class GridCell {
  final String? decorAsset;
  final IconData? icon;
  final String? label;
  final Color? color;
  final VoidCallback? onTap;

  const GridCell.decor(this.decorAsset)
      : icon = null,
        label = null,
        color = null,
        onTap = null;

  GridCell.button({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = BaiColors.butter,
  }) : decorAsset = null;

  bool get isButton => icon != null;
}

/// Renders cells as a 2-column grid of big even squares — same size and
/// card language as the Menu screen's drink cards — centered in whatever
/// space its parent (usually an Expanded) gives it.
class HomeActionGrid extends StatelessWidget {
  final List<GridCell> cells; // row-major, length must be even (2 per row)
  const HomeActionGrid({super.key, required this.cells}) : assert(cells.length % 2 == 0);

  Widget _row(int r) {
    // The 14px gap is its own SizedBox between two equal Expanded cells.
    // (Padding inside only the left cell made it 14px smaller than the right.)
    return Row(
      children: [
        Expanded(child: AspectRatio(aspectRatio: 1, child: _cell(cells[r * 2]))),
        const SizedBox(width: 14),
        Expanded(child: AspectRatio(aspectRatio: 1, child: _cell(cells[r * 2 + 1]))),
      ],
    );
  }

  Widget _cell(GridCell cell) {
    if (!cell.isButton) {
      return Center(
        child: FractionallySizedBox(
          widthFactor: 0.72,
          heightFactor: 0.72,
          child: Image.asset(cell.decorAsset!, fit: BoxFit.contain),
        ),
      );
    }
    // Same card language as the Menu screen's drink cards: uniform cream
    // card, white border, no hard drop-shadow, generous padding — this is
    // meant to read as "big square," matching the Menu card's scale.
    return GestureDetector(
      onTap: cell.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: BaiColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 4),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(10),
        // FittedBox makes the badge+label stack shrink to fit if a device
        // is narrow enough to need it, instead of overflowing.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cell.color, shape: BoxShape.circle),
                child: Icon(cell.icon, size: 32, color: BaiColors.ink),
              ),
              const SizedBox(height: 12),
              Text(
                cell.label!,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: BaiColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = cells.length ~/ 2;
    final children = <Widget>[];
    for (var r = 0; r < rows; r++) {
      children.add(Expanded(child: _row(r)));
      if (r < rows - 1) children.add(const SizedBox(height: 14));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}