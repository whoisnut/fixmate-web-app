import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/repositories/payout_repository.dart';
import 'package:mobile/models/payout.dart';

final payoutRepositoryProvider = Provider((ref) => PayoutRepository());

final createPayoutProvider = FutureProvider.family<PayoutResponse,
    ({double amount, String method, String paymentAccount})>(
  (ref, params) async {
    final repo = ref.watch(payoutRepositoryProvider);
    return repo.createPayoutRequest(
      amount: params.amount,
      method: params.method,
      paymentAccount: params.paymentAccount,
    );
  },
);

final getMyPayoutsProvider = FutureProvider<List<PayoutResponse>>(
  (ref) async {
    final repo = ref.watch(payoutRepositoryProvider);
    return repo.getMyPayouts();
  },
);

final getPayoutProvider = FutureProvider.family<PayoutResponse, String>(
  (ref, payoutId) async {
    final repo = ref.watch(payoutRepositoryProvider);
    return repo.getPayout(payoutId);
  },
);
