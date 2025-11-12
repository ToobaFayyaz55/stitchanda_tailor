import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:stichanda_tailor/controller/order_cubit.dart';
import 'package:stichanda_tailor/theme/theme.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    final orderId = widget.order['order_id'] as String? ?? '';
    if (orderId.isNotEmpty) {
      // Kick off an initial load once (optional)
      context.read<OrderCubit>().fetchOrderItems(orderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.order['order_id'] as String? ?? '';
    return Scaffold(
      appBar: AppBar(title: Text('Order #$orderId')),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: context.read<OrderCubit>().streamOrder(orderId),
        builder: (context, orderSnap) {
          final liveOrder = orderSnap.data ?? widget.order;
          final pickup = liveOrder['pickup_location'] as Map<String, dynamic>?;
          final dropoff = liveOrder['dropoff_location'] as Map<String, dynamic>?;
          final status = liveOrder['status'] as int? ?? -999;
          final total = (liveOrder['total_price'] as num?)?.toDouble() ?? 0.0;
          final paymentMethod = (liveOrder['payment_method'] as String?) ?? 'N/A';
          final paymentStatus = (liveOrder['payment_status'] as String?) ?? 'N/A';
          final riderId = (liveOrder['rider_id'] as String?) ?? '';
          final deliveryTs = liveOrder['delivery_date'];
          final createdTs = liveOrder['created_at'];
          final updatedTs = liveOrder['updated_at'];

          return Column(
            children: [
              _HeaderCard(
                orderId: orderId,
                pickup: pickup?['full_address'] ?? '-',
                dropoff: dropoff?['full_address'] ?? '-',
                total: total,
                status: status,
                paymentMethod: paymentMethod,
                paymentStatus: paymentStatus,
                riderId: riderId,
                deliveryDate: _fmtTs(deliveryTs),
                createdAt: _fmtTs(createdTs),
                updatedAt: _fmtTs(updatedTs),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: context.read<OrderCubit>().streamOrderItems(orderId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snapshot.data ?? const [];
                    if (items.isEmpty) {
                      return const Center(child: Text('No items for this order'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, i) => _ItemCard(index: i + 1, item: items[i]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _fmtTs(Object? ts) {
    if (ts == null) return '—';
    DateTime dt;
    if (ts is String) {
      dt = DateTime.tryParse(ts) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else if (ts is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(ts);
    } else {
      return '—';
    }
    return '${dt.year}-${_2(dt.month)}-${_2(dt.day)} ${_2(dt.hour)}:${_2(dt.minute)}';
  }

  String _2(int v) => v.toString().padLeft(2, '0');
}

class _HeaderCard extends StatelessWidget {
  final String orderId;
  final String pickup;
  final String dropoff;
  final double total;
  final int status;
  final String paymentMethod;
  final String paymentStatus;
  final String riderId;
  final String deliveryDate;
  final String createdAt;
  final String updatedAt;
  const _HeaderCard({
    required this.orderId,
    required this.pickup,
    required this.dropoff,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.riderId,
    required this.deliveryDate,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #$orderId', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      _kv('Pickup', pickup),
                      _kv('Dropoff', dropoff),
                      _kv('Delivery Date', deliveryDate),
                      _kv('Rider', riderId.isEmpty ? '—' : riderId),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _pill('Total: Rs. ${total.toStringAsFixed(0)}', AppColors.caramel),
                _pill('Payment: $paymentMethod', Colors.blueGrey),
                _pill('Status: $paymentStatus', paymentStatus.toLowerCase() == 'paid' ? Colors.green : Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _kv('Created', createdAt)),
                Expanded(child: _kv('Updated', updatedAt)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textGrey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.4)),
      ),
      child: Text(text, style: TextStyle(color: color.darken(), fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

extension on Color {
  Color darken([double amount = .2]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness(max(0.0, hsl.lightness - amount));
    return hslDark.toColor();
  }
}

class _StatusBadge extends StatelessWidget {
  final int status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color(status),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(_label(status), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  String _label(int s) {
    switch (s) {
      case -2: return 'Pending';
      case -1: return 'Accepted';
      case -3: return 'Rejected';
      case 0: return 'Unassigned';
      case 1: return 'Rider Assigned';
      case 2: return 'Picked (Cust)';
      case 3: return 'Completed (Cust)';
      case 4: return 'Received';
      case 5: return 'Tailor Done';
      case 6: return 'Call Rider';
      case 7: return 'Rider Assigned';
      case 8: return 'Picked (Tailor)';
      case 9: return 'Delivered';
      case 10: return 'Confirmed';
      case 11: return 'Self Delivery';
      default: return 'Unknown';
    }
  }

  Color _color(int s) {
    switch (s) {
      case -2: return Colors.red;
      case -3: return Colors.grey;
      case -1: return Colors.orange;
      case 0: return Colors.blueGrey;
      case 1: return Colors.blue;
      case 2: return Colors.purple;
      case 3: return Colors.indigo;
      case 4: return Colors.cyan;
      case 5: return Colors.green.shade700;
      case 6: return Colors.deepOrange;
      case 7: return Colors.deepPurple;
      case 8: return Colors.teal;
      case 9: return Colors.lightGreen;
      case 10: return Colors.greenAccent.shade400;
      case 11: return Colors.brown;
      default: return Colors.black54;
    }
  }
}

class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  const _ItemCard({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    final description = item['description'] as String? ?? '';
    final price = (item['price'] as num?)?.toDouble() ?? (item['totalprice'] as num?)?.toDouble() ?? 0.0;
    final fabric = (item['fabric'] as Map<String, dynamic>?) ?? const {};
    final measurements = (item['measurements'] as Map<String, dynamic>?) ?? const {};
    final dueData = item['due_data'] as String?; // assume ISO or plain
    final imagePath = item['image_path'] as String? ?? '';
    final customerName = item['customer_name'] as String? ?? '';

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${index.toString().padLeft(2,'0')}. ${description.isEmpty ? 'Item' : description}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                Text('Rs. ${price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.caramel, fontWeight: FontWeight.w700)),
              ],
            ),
            if (customerName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Customer: $customerName', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
            ],
            if (dueData != null && dueData.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('Due: $dueData', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
            ],
            if (imagePath.isNotEmpty) ...[
              const SizedBox(height: 10),
              AspectRatio(
                aspectRatio: 16/9,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)) ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (fabric.isNotEmpty) ...[
              const _SectionTitle('Fabric'),
              const SizedBox(height: 6),
              _fabricRow('Shirt', fabric['shirt_fabric']),
              _fabricRow('Trouser', fabric['trouser_fabric']),
              _fabricRow('Dupata', fabric['dupata_fabric']),
            ],
            if (measurements.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _SectionTitle('Measurements'),
              const SizedBox(height: 6),
              Table(
                columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
                children: measurements.entries.map((e) {
                  final label = 'hardcoded';
                  final value = e.value;
                  return TableRow(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('$value${_unitForKey(e.key)}', style: const TextStyle(fontSize: 12)),
                    ),
                  ]);
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _fabricRow(String label, Object? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(child: Text('${value ?? '-'}', style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  String _unitForKey(String key) {
    const measurementKeys = [
      'chest','waist','hips','shoulder','arm_length','wrist','armpit'
    ];
    if (measurementKeys.contains(key)) return ' in'; // assume inches
    return '';
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700));
  }
}
