enum ReturnStatus {
  requested,
  underReview,
  approved,
  rejected,
  pickupScheduled,
  received,
  refundProcessing,
  refunded,
}

extension ReturnStatusX on ReturnStatus {
  String get label => switch (this) {
    ReturnStatus.requested => 'Requested',
    ReturnStatus.underReview => 'Under Review',
    ReturnStatus.approved => 'Approved',
    ReturnStatus.rejected => 'Rejected',
    ReturnStatus.pickupScheduled => 'Pickup Scheduled',
    ReturnStatus.received => 'Received',
    ReturnStatus.refundProcessing => 'Refund Processing',
    ReturnStatus.refunded => 'Refunded',
  };

  static ReturnStatus fromWire(String value) => ReturnStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => ReturnStatus.requested,
  );
}

const returnReasons = [
  'Item damaged/defective',
  'Wrong item received',
  'Item not as described',
  'Changed my mind',
  'Size/fit issue',
  'Other',
];

class ReturnRequest {
  final String id;
  final String orderId;
  final String userId;
  final String customerName;
  final String productId;
  final String productName;
  final int quantity;
  final String reason;
  final String description;
  final List<String> imageUrls;
  final DateTime requestedAt;
  final ReturnStatus status;

  const ReturnRequest({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.customerName,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.reason,
    required this.description,
    this.imageUrls = const [],
    required this.requestedAt,
    this.status = ReturnStatus.requested,
  });

  Map<String, dynamic> toFirestoreMap() => {
    'orderId': orderId,
    'userId': userId,
    'customerName': customerName,
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'reason': reason,
    'description': description,
    'imageUrls': imageUrls,
    'requestedAt': requestedAt.toIso8601String(),
    'status': status.name,
  };

  factory ReturnRequest.fromFirestore(String id, Map<String, dynamic> data) {
    return ReturnRequest(
      id: id,
      orderId: data['orderId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Unknown',
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      reason: data['reason'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrls:
          (data['imageUrls'] as List?)?.map((e) => e as String).toList() ??
          const [],
      requestedAt:
          DateTime.tryParse(data['requestedAt'] as String? ?? '') ??
          DateTime.now(),
      status: ReturnStatusX.fromWire(data['status'] as String? ?? 'requested'),
    );
  }
}
