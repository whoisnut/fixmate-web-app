import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/booking_repository.dart';

final bookingRepositoryProvider = Provider((ref) => BookingRepository());

final bookingsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookings();
});

final activeBookingsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getActiveBookings();
});

final completedBookingsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getCompletedBookings();
});

final bookingDetailsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, bookingId) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBooking(bookingId);
});

final createBookingProvider =
    StateNotifierProvider<CreateBookingNotifier, CreateBookingState>(
  (ref) => CreateBookingNotifier(ref.watch(bookingRepositoryProvider)),
);

class CreateBookingNotifier extends StateNotifier<CreateBookingState> {
  final BookingRepository _bookingRepository;

  CreateBookingNotifier(this._bookingRepository)
      : super(const CreateBookingState.initial());

  Future<void> createBooking({
    required String serviceId,
    required String address,
    required double lat,
    required double lng,
    required DateTime scheduledAt,
    String? notes,
  }) async {
    state = const CreateBookingState.loading();
    try {
      final result = await _bookingRepository.createBooking(
        serviceId: serviceId,
        address: address,
        lat: lat,
        lng: lng,
        scheduledAt: scheduledAt,
        notes: notes,
      );
      state = CreateBookingState.success(result);
    } catch (e) {
      state = CreateBookingState.error(e.toString());
    }
  }

  void reset() {
    state = const CreateBookingState.initial();
  }
}

sealed class CreateBookingState {
  const CreateBookingState();

  const factory CreateBookingState.initial() = _Initial;
  const factory CreateBookingState.loading() = _Loading;
  const factory CreateBookingState.success(Map<String, dynamic> booking) =
      _Success;
  const factory CreateBookingState.error(String message) = _Error;
}

class _Initial extends CreateBookingState {
  const _Initial();
}

class _Loading extends CreateBookingState {
  const _Loading();
}

class _Success extends CreateBookingState {
  final Map<String, dynamic> booking;

  const _Success(this.booking);
}

class _Error extends CreateBookingState {
  final String message;

  const _Error(this.message);
}
