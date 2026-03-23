class Booking {
  final String id;
  final String customerId;
  final String? technicianId;
  final String serviceId;
  final String status;
  final String address;
  final double lat;
  final double lng;
  final double totalPrice;
  final String? notes;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.customerId,
    this.technicianId,
    required this.serviceId,
    required this.status,
    required this.address,
    required this.lat,
    required this.lng,
    required this.totalPrice,
    this.notes,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      customerId: json['customer_id'],
      technicianId: json['technician_id'],
      serviceId: json['service_id'],
      status: json['status'],
      address: json['address'],
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}