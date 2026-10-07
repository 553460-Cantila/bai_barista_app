import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class AdminHistoryScreen extends StatefulWidget {
  const AdminHistoryScreen({super.key});
  @override
  State<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> {
  static final _dateFmt = DateFormat('MMM d, y');
  String _statusFilter = 'All'; // All | Paid | Pending | Declined
  DateTime? _start, _end;

  static const _statusColor = {
    'paid': BaiColors.mint,
    'pending': BaiColors.butter,
    'declined': BaiColors.red,
  };

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: _start != null && _end != null ? DateTimeRange(start: _start!, end: _end!) : null,
    );
    if (range != null) setState(() { _start = range.start; _end = range.end; });
  }

  bool _matches(SubscriptionPayment p) {
    if (_statusFilter != 'All' && p.status != _statusFilter.toLowerCase()) return false;
    final d = p.decidedAt ?? p.createdAt;
    if (_start != null && d != null && d.isBefore(_start!)) return false;
    if (_end != null && d != null && d.isAfter(_end!.add(const Duration(days: 1)))) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      backgroundColor: BaiColors.pink,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Subscription payment history')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: ['All', 'Paid', 'Pending', 'Declined'].map((s) {
                    return ChoiceChip(
                      label: Text(s),
                      selected: _statusFilter == s,
                      selectedColor: BaiColors.lavender,
                      backgroundColor: Colors.white,
                      onSelected: (_) => setState(() => _statusFilter = s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.date_range, size: 18),
                      label: Text(_start == null
                          ? 'Filter by date range'
                          : '${_dateFmt.format(_start!)} – ${_dateFmt.format(_end!)}'),
                      onPressed: _pickRange,
                    ),
                    if (_start != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() { _start = null; _end = null; }),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<SubscriptionPayment>>(
              stream: fs.subscriptionPaymentHistory(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Could not load history: ${snap.error}', textAlign: TextAlign.center),
                    ),
                  );
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final items = snap.data!.where(_matches).toList();
                if (items.isEmpty) {
                  return const Center(child: Text('No records match these filters.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final p = items[i];
                    final d = p.decidedAt ?? p.createdAt;
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('₱${p.amount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                d != null ? _dateFmt.format(d) : 'No date',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                              Text(
                                p.source == 'manual' ? 'Manual override' : 'Receipt upload',
                                style: const TextStyle(fontSize: 11, color: Colors.black38),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor[p.status] ?? Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              p.status[0].toUpperCase() + p.status.substring(1),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}