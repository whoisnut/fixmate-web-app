class ReviewResponse {
  final String id;
  final String bookingId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  ReviewResponse({
    required this.id,
    required this.bookingId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      id: json['id'],
      bookingId: json['booking_id'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
