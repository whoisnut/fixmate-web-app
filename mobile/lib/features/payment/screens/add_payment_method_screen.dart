import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/payment_provider.dart';

class AddPaymentMethodScreen extends ConsumerStatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  ConsumerState<AddPaymentMethodScreen> createState() =>
      _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState
    extends ConsumerState<AddPaymentMethodScreen> {
  late final TextEditingController _cardholderNameController;
  late final TextEditingController _cardNumberController;
  late final TextEditingController _expiryMonthController;
  late final TextEditingController _expiryYearController;
  late final TextEditingController _cvcController;
  late final GlobalKey<FormState> _formKey;

  @override
  void initState() {
    super.initState();
    _cardholderNameController = TextEditingController();
    _cardNumberController = TextEditingController();
    _expiryMonthController = TextEditingController();
    _expiryYearController = TextEditingController();
    _cvcController = TextEditingController();
    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    _cardholderNameController.dispose();
    _cardNumberController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addPaymentState = ref.watch(addPaymentMethodProvider);

    ref.listen(addPaymentMethodProvider, (previous, next) {
      final typeName = next.runtimeType.toString();
      if (typeName.contains('Success')) {
        Navigator.pop(context, true);
      } else if (typeName.contains('Error')) {
        // Extract error message if available
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to add payment method'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    });

    final isLoading =
        addPaymentState.runtimeType.toString().contains('Loading');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Payment Method'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary,
                      AppTheme.primary.withOpacity(0.7)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.credit_card,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _cardNumberController.text.isEmpty
                          ? '•••• •••• •••• ••••'
                          : _formatCardNumber(_cardNumberController.text),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CARDHOLDER',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _cardholderNameController.text.isEmpty
                                  ? 'YOUR NAME'
                                  : _cardholderNameController.text
                                      .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EXPIRES',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _expiryMonthController.text.isEmpty ||
                                      _expiryYearController.text.isEmpty
                                  ? 'MM/YY'
                                  : '${_expiryMonthController.text}/${_expiryYearController.text.substring(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Cardholder Name
              Text(
                'Cardholder Name',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cardholderNameController,
                decoration: InputDecoration(
                  hintText: 'John Doe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter cardholder name';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Card Number
              Text(
                'Card Number',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cardNumberController,
                decoration: InputDecoration(
                  hintText: '1234 5678 9012 3456',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 19,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter card number';
                  }
                  final digits = value?.replaceAll(' ', '') ?? '';
                  if (digits.length < 13 || digits.length > 19) {
                    return 'Invalid card number';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Expiry and CVC Row
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Month',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _expiryMonthController,
                          decoration: InputDecoration(
                            hintText: 'MM',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 2,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Required';
                            }
                            final month = int.tryParse(value!) ?? 0;
                            if (month < 1 || month > 12) {
                              return 'Invalid';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Year',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _expiryYearController,
                          decoration: InputDecoration(
                            hintText: 'YYYY',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Required';
                            }
                            final year = int.tryParse(value!) ?? 0;
                            if (year < DateTime.now().year) {
                              return 'Invalid';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CVC',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _cvcController,
                          decoration: InputDecoration(
                            hintText: '123',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: true,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Required';
                            }
                            if (value!.length < 3) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Security Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 20,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your card details are encrypted and secure',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Add Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitForm,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Add Payment Method'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCardNumber(String input) {
    final digits = input.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }

    return buffer.toString();
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref.read(addPaymentMethodProvider.notifier).addPaymentMethod(
            cardholderName: _cardholderNameController.text,
            cardNumber: _cardNumberController.text.replaceAll(' ', ''),
            expiryMonth: _expiryMonthController.text.padLeft(2, '0'),
            expiryYear: _expiryYearController.text,
            cvc: _cvcController.text,
          );
    }
  }
}
