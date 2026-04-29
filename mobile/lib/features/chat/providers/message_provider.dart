import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/repositories/message_repository.dart';
import 'package:mobile/models/message.dart';

final messageRepositoryProvider = Provider((ref) => MessageRepository());

// StateNotifier for managing messages
class MessageNotifier extends StateNotifier<AsyncValue<List<MessageResponse>>> {
  final MessageRepository _repository;

  MessageNotifier(this._repository) : super(const AsyncValue.data([]));

  Future<void> loadMessages(String bookingId) async {
    state = const AsyncValue.loading();
    try {
      final messages = await _repository.getBookingMessages(bookingId);
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> sendMessage({
    required String bookingId,
    required String message,
  }) async {
    try {
      final newMessage = await _repository.sendMessage(bookingId, message);
      state = AsyncValue.data([...?state.asData?.value, newMessage]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

// StateNotifierProvider for message management
final messageProvider =
    StateNotifierProvider<MessageNotifier, AsyncValue<List<MessageResponse>>>(
  (ref) {
    final repo = ref.watch(messageRepositoryProvider);
    return MessageNotifier(repo);
  },
);

final sendMessageProvider = FutureProvider.family<MessageResponse,
    ({String bookingId, String content})>(
  (ref, params) async {
    final repo = ref.watch(messageRepositoryProvider);
    return repo.sendMessage(params.bookingId, params.content);
  },
);

final getBookingMessagesProvider =
    FutureProvider.family<List<MessageResponse>, String>(
  (ref, bookingId) async {
    final repo = ref.watch(messageRepositoryProvider);
    return repo.getBookingMessages(bookingId);
  },
);

final getUserChatsProvider = FutureProvider<List<ChatInfo>>(
  (ref) async {
    final repo = ref.watch(messageRepositoryProvider);
    return repo.getUserChats();
  },
);
