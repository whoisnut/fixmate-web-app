import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/repositories/message_repository.dart';
import 'package:mobile/models/message.dart';

final messageRepositoryProvider = Provider((ref) => MessageRepository());

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
