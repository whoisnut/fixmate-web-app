import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_method.dart';
import '../repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

// Fetch all payment methods
final paymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPaymentMethods();
});

// Default payment method
final defaultPaymentMethodProvider =
    FutureProvider<PaymentMethod?>((ref) async {
  final methods = await ref.watch(paymentMethodsProvider.future);
  try {
    return methods.firstWhere((m) => m.isDefault);
  } catch (e) {
    return null;
  }
});

// State notifier for adding payment method
class AddPaymentMethodNotifier extends StateNotifier<AddPaymentMethodState> {
  final PaymentRepository _repository;
  final Ref _ref;

  AddPaymentMethodNotifier(this._repository, this._ref)
      : super(const AddPaymentMethodState.initial());

  Future<void> addPaymentMethod({
    required String cardholderName,
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvc,
  }) async {
    state = const AddPaymentMethodState.loading();
    try {
      await _repository.addPaymentMethod(
        cardholderName: cardholderName,
        cardNumber: cardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvc: cvc,
      );
      state = const AddPaymentMethodState.success();
      // Invalidate payment methods cache to refresh
      _ref.invalidate(paymentMethodsProvider);
    } catch (e) {
      state = AddPaymentMethodState.error(e.toString());
    }
  }

  Future<void> setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      await _repository.setDefaultPaymentMethod(paymentMethodId);
      _ref.invalidate(paymentMethodsProvider);
      _ref.invalidate(defaultPaymentMethodProvider);
    } catch (e) {
      state = AddPaymentMethodState.error(e.toString());
    }
  }

  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      await _repository.deletePaymentMethod(paymentMethodId);
      _ref.invalidate(paymentMethodsProvider);
      _ref.invalidate(defaultPaymentMethodProvider);
    } catch (e) {
      state = AddPaymentMethodState.error(e.toString());
    }
  }
}

sealed class AddPaymentMethodState {
  const AddPaymentMethodState();

  const factory AddPaymentMethodState.initial() = _Initial;

  const factory AddPaymentMethodState.loading() = _Loading;

  const factory AddPaymentMethodState.success() = _Success;

  const factory AddPaymentMethodState.error(String message) = _Error;
}

class _Initial extends AddPaymentMethodState {
  const _Initial();
}

class _Loading extends AddPaymentMethodState {
  const _Loading();
}

class _Success extends AddPaymentMethodState {
  const _Success();
}

class _Error extends AddPaymentMethodState {
  final String message;

  const _Error(this.message);
}

final addPaymentMethodProvider =
    StateNotifierProvider<AddPaymentMethodNotifier, AddPaymentMethodState>(
        (ref) {
  return AddPaymentMethodNotifier(
    ref.watch(paymentRepositoryProvider),
    ref,
  );
});
