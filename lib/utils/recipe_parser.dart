/// Helpers that turn the recipe text staff type ("18 g", "coffee_beans +10 g")
/// into numbers, so ordering can deduct stock automatically.

/// How much of the (Medium) base recipe each cup size uses.
const Map<String, double> kSizeScale = {'Small': 0.75, 'Medium': 1.0, 'Large': 1.25};

/// Lower-case letters and digits only, so "Coffee beans", "coffee_beans" and
/// "Coffee-Beans" all compare equal.
String normalizeName(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

class ParsedAmount {
  final String name; // ingredient name as written
  final double amount; // signed: "+10" -> 10, "-5" -> -5
  final String unit; // as written, may be empty
  const ParsedAmount(this.name, this.amount, this.unit);
}

/// Recipe line: name "Coffee beans", amount "18 g".
ParsedAmount? parseRecipeLine(String name, String amount) {
  final m = RegExp(r'(\d+(?:\.\d+)?)\s*([A-Za-z]*)').firstMatch(amount);
  if (m == null || name.trim().isEmpty) return null;
  return ParsedAmount(name.trim(), double.parse(m.group(1)!), m.group(2) ?? '');
}

/// Add-on effect: "coffee_beans +10 g" or "oat_milk +200 ml".
ParsedAmount? parseEffect(String effect) {
  final m = RegExp(r'^\s*([A-Za-z_ \-]+?)\s*([+\-]?)\s*(\d+(?:\.\d+)?)\s*([A-Za-z]*)\s*$').firstMatch(effect);
  if (m == null) return null;
  final value = double.parse(m.group(3)!);
  return ParsedAmount(m.group(1)!.trim(), m.group(2) == '-' ? -value : value, m.group(4) ?? '');
}

// canonical base unit + factor to that base
(String, double)? _canon(String unit) {
  switch (unit.toLowerCase()) {
    case 'g': case 'gram': case 'grams': return ('g', 1);
    case 'kg': return ('g', 1000);
    case 'ml': return ('ml', 1);
    case 'l': case 'liter': case 'litre': return ('ml', 1000);
    case 'pcs': case 'pc': case 'piece': case 'pieces': return ('pcs', 1);
  }
  return null;
}

/// Converts [amount] written in [unit] into the inventory item's own unit.
/// Returns null if the units can't be compared (e.g. "tbsp" vs "ml").
double? convertToInventoryUnit(double amount, String unit, String inventoryUnit) {
  if (unit.isEmpty) return amount; // no unit written: assume the inventory unit
  final from = _canon(unit), to = _canon(inventoryUnit);
  if (from == null || to == null || from.$1 != to.$1) {
    return unit.toLowerCase() == inventoryUnit.toLowerCase() ? amount : null;
  }
  return amount * from.$2 / to.$2;
}