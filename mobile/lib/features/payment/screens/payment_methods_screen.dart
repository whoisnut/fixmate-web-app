import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/payment_method.dart';
import '../providers/payment_provider.dart';
import 'add_payment_method_screen.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  @override
  Widget build(BuildContext context) {
    final paymentMethods = ref.watch(paymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: paymentMethods.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppTheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load payment methods',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(paymentMethodsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (methods) => methods.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payment_outlined,
                        size: 64,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No payment methods',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a card to proceed with bookings',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _navigateToAddPaymentMethod,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Payment Method'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: methods.length + 1,
                itemBuilder: (context, index) {
                  if (index == methods.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton.icon(
                        onPressed: _navigateToAddPaymentMethod,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Payment Method'),
                      ),
                    );
                  }

                  final method = methods[index];
                  return _buildPaymentMethodCard(context, method);
                },
              ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(BuildContext context, PaymentMethod method) {
    final isExpired = method.isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _getBrandIcon(method.brand),
                              const SizedBox(width: 8),
                              Text(
                                method.cardDisplay,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            method.cardholderName,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Expires: ${method.expiryDisplay}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isExpired
                                          ? AppTheme.error
                                          : AppTheme.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    if (method.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primary),
                        ),
                        child: Text(
                          'Default',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                if (isExpired)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'This card has expired',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete') {
                  _showDeleteConfirmation(context, method);
                } else if (value == 'default' && !method.isDefault) {
                  await ref
                      .read(addPaymentMethodProvider.notifier)
                      .setDefaultPaymentMethod(method.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Default payment method updated'),
                      ),
                    );
                  }
                }
              },
              itemBuilder: (BuildContext context) => [
                if (!method.isDefault)
                  const PopupMenuItem<String>(
                    value: 'default',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Set as Default'),
                      ],
                    ),
                  ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getBrandIcon(String brand) {
    final icon = switch (brand.toLowerCase()) {
      'visa' => Icons.credit_card,
      'mastercard' => Icons.payment,
      'amex' => Icons.domain_verification,
      _ => Icons.credit_card,
    };

    return Icon(
      icon,
      size: 24,
      color: AppTheme.primary,
    );
  }

  void _showDeleteConfirmation(BuildContext context, PaymentMethod method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method?'),
        content: Text(
          'Are you sure you want to delete ${method.cardDisplay}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(addPaymentMethodProvider.notifier)
                  .deletePaymentMethod(method.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment method deleted'),
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddPaymentMethod() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddPaymentMethodScreen()),
    );

    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment method added successfully'),
        ),
      );
    }
  }
}
