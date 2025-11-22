import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      context.read<OrderCubit>().fetchOrderItems(orderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.order['order_id'] as String? ?? '';
    // Customer name is already enriched in the order data by the repository
    final customerName = (widget.order['customer_name'] as String?) ?? 'Customer';
    final status = (widget.order['status'] as int?) ?? -999;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$orderId'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(child: _StatusBadge(status: status)),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.textGrey.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: AppColors.caramel, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Order Items
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: context.read<OrderCubit>().streamOrderItems(orderId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.content_cut, size: 60, color: AppColors.textGrey),
                        SizedBox(height: 16),
                        Text(
                          'No items for this order',
                          style: TextStyle(fontSize: 16, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) => _ItemCard(index: i + 1, item: items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
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
        color: OrderCubit.getStatusColor(status),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        OrderCubit.getStatusLabel(status),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  const _ItemCard({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    final description = item['description'] as String? ?? 'Item';
    final price = (item['price'] as num?)?.toDouble() ?? (item['totalprice'] as num?)?.toDouble() ?? 0.0;
    final fabric = (item['fabric'] as Map<String, dynamic>?) ?? const {};
    final measurements = (item['measurements'] as Map<String, dynamic>?) ?? const {};
    final dueData = item['due_data'] as String?;
    final imagePath = item['imagePath'] as String? ?? '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item ${index.toString().padLeft(2,'0')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.caramel.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Rs. ${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.caramel,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            // Due Date
            if (dueData != null && dueData.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.textGrey),
                  const SizedBox(width: 6),
                  Text(
                    'Due: $dueData',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            // Design Image
            if (imagePath.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Design Reference',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 16/9,
                  child: Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 40, color: AppColors.textGrey),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Fabric Details
            if (fabric.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Fabric Details',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('Shirt', fabric['shirt_fabric']),
              _buildDetailRow('Trouser', fabric['trouser_fabric']),
              _buildDetailRow('Dupata', fabric['dupata_fabric']),
            ],

            // Measurements
            if (measurements.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Measurements',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                  },
                  children: measurements.entries.map((e) {
                    final label = _formatMeasurementLabel(e.key);
                    final value = e.value;
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            '$value${_unitForKey(e.key)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, Object? value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: AppColors.textBlack,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _unitForKey(String key) {
    const measurementKeys = [
      'chest','waist','hips','shoulder','arm_length','wrist','armpit'
    ];
    if (measurementKeys.contains(key)) return ' in';
    return '';
  }

  String _formatMeasurementLabel(String key) {
    switch (key) {
      case 'arm_length': return 'Arm Length';
      case 'chest': return 'Chest';
      case 'shoulder': return 'Shoulder';
      case 'waist': return 'Waist';
      case 'hips': return 'Hips';
      case 'wrist': return 'Wrist';
      case 'fitting_preferences': return 'Fitting';
      default: return key.replaceAll('_', ' ').split(' ').map((word) =>
        word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
      ).join(' ');
    }
  }
}
