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

final availableBookingsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getAvailableBookings();
});

final acceptBookingProvider =
    StateNotifierProvider<AcceptBookingNotifier, AcceptBookingState>(
  (ref) => AcceptBookingNotifier(ref.watch(bookingRepositoryProvider)),
);

final bookingActionProvider =
    StateNotifierProvider<BookingActionNotifier, BookingActionState>(
  (ref) => BookingActionNotifier(ref.watch(bookingRepositoryProvider)),
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

// Accept Booking Notifier
class AcceptBookingNotifier extends StateNotifier<AcceptBookingState> {
  final BookingRepository _bookingRepository;

  AcceptBookingNotifier(this._bookingRepository)
      : super(const AcceptBookingState.initial());

  Future<void> acceptBooking(String bookingId) async {
    state = const AcceptBookingState.loading();
    try {
      final result = await _bookingRepository.acceptBooking(bookingId);
      state = AcceptBookingState.success(result);
    } catch (e) {
      state = AcceptBookingState.error(e.toString());
    }
  }

  void reset() {
    state = const AcceptBookingState.initial();
  }
}

sealed class AcceptBookingState {
  const AcceptBookingState();

  const factory AcceptBookingState.initial() = _AcceptInitial;
  const factory AcceptBookingState.loading() = _AcceptLoading;
  const factory AcceptBookingState.success(Map<String, dynamic> booking) =
      _AcceptSuccess;
  const factory AcceptBookingState.error(String message) = _AcceptError;
}

class _AcceptInitial extends AcceptBookingState {
  const _AcceptInitial();
}

class _AcceptLoading extends AcceptBookingState {
  const _AcceptLoading();
}

class _AcceptSuccess extends AcceptBookingState {
  final Map<String, dynamic> booking;

  const _AcceptSuccess(this.booking);
}

class _AcceptError extends AcceptBookingState {
  final String message;

  const _AcceptError(this.message);
}

// Booking Action Notifier (start, complete, cancel)
class BookingActionNotifier extends StateNotifier<BookingActionState> {
  final BookingRepository _bookingRepository;

  BookingActionNotifier(this._bookingRepository)
      : super(const BookingActionState.initial());

  Future<void> startBooking(String bookingId) async {
    state = const BookingActionState.loading();
    try {
      final result = await _bookingRepository.startBooking(bookingId);
      state = BookingActionState.success(result, 'Booking started');
    } catch (e) {
      state = BookingActionState.error(e.toString());
    }
  }

  Future<void> completeBooking(String bookingId) async {
    state = const BookingActionState.loading();
    try {
      final result = await _bookingRepository.completeBooking(bookingId);
      state = BookingActionState.success(result, 'Booking completed');
    } catch (e) {
      state = BookingActionState.error(e.toString());
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    state = const BookingActionState.loading();
    try {
      await _bookingRepository.cancelBooking(bookingId);
      state = const BookingActionState.success({}, 'Booking cancelled');
    } catch (e) {
      state = BookingActionState.error(e.toString());
    }
  }

  void reset() {
    state = const BookingActionState.initial();
  }
}

sealed class BookingActionState {
  const BookingActionState();

  const factory BookingActionState.initial() = _ActionInitial;
  const factory BookingActionState.loading() = _ActionLoading;
  const factory BookingActionState.success(
    Map<String, dynamic> booking,
    String message,
  ) = _ActionSuccess;
  const factory BookingActionState.error(String message) = _ActionError;
}

class _ActionInitial extends BookingActionState {
  const _ActionInitial();
}

class _ActionLoading extends BookingActionState {
  const _ActionLoading();
}

class _ActionSuccess extends BookingActionState {
  final Map<String, dynamic> booking;
  final String message;

  const _ActionSuccess(this.booking, this.message);
}

class _ActionError extends BookingActionState {
  final String message;

  const _ActionError(this.message);
}
