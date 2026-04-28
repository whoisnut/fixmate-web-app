class MessageResponse {
  final String id;
  final String bookingId;
  final String senderId;
  final String content;
  final DateTime sentAt;

  MessageResponse({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.content,
    required this.sentAt,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    return MessageResponse(
      id: json['id'],
      bookingId: json['booking_id'],
      senderId: json['sender_id'],
      content: json['content'],
      sentAt: DateTime.parse(json['sent_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'sender_id': senderId,
      'content': content,
      'sent_at': sentAt.toIso8601String(),
    };
  }
}

class ChatInfo {
  final String bookingId;
  final ({String id, String name, String? avatarUrl}) otherUser;
  final String bookingStatus;
  final String serviceName;
  final String? latestMessage;
  final DateTime? latestMessageTime;

  ChatInfo({
    required this.bookingId,
    required this.otherUser,
    required this.bookingStatus,
    required this.serviceName,
    this.latestMessage,
    this.latestMessageTime,
  });

  factory ChatInfo.fromJson(Map<String, dynamic> json) {
    return ChatInfo(
      bookingId: json['booking_id'],
      otherUser: (
        id: json['other_user']['id'],
        name: json['other_user']['name'],
        avatarUrl: json['other_user']['avatar_url'],
      ),
      bookingStatus: json['booking_status'],
      serviceName: json['service_name'],
      latestMessage: json['latest_message'],
      latestMessageTime: json['latest_message_time'] != null
          ? DateTime.parse(json['latest_message_time'])
          : null,
    );
  }
}
