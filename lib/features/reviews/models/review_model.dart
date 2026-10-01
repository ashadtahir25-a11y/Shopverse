class Review {
  final String id;
  final String productId;
  final String productName;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final int rating; // 1-5
  final String text;
  final List<String> imageUrls;
  final DateTime date;
  final bool verifiedPurchase;
  final String status; // 'pending' | 'approved' | 'rejected'

  const Review({
    required this.id,
    required this.productId,
    required this.productName,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.rating,
    required this.text,
    this.imageUrls = const [],
    required this.date,
    this.verifiedPurchase = true,
    this.status = 'pending',
  });

  Map<String, dynamic> toFirestoreMap() => {
    'productId': productId,
    'productName': productName,
    'userId': userId,
    'userName': userName,
    'userAvatarUrl': userAvatarUrl,
    'rating': rating,
    'text': text,
    'imageUrls': imageUrls,
    'date': date.toIso8601String(),
    'verifiedPurchase': verifiedPurchase,
    'status': status,
  };

  factory Review.fromFirestore(String id, Map<String, dynamic> data) {
    return Review(
      id: id,
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Anonymous',
      userAvatarUrl: data['userAvatarUrl'] as String?,
      rating: (data['rating'] as num?)?.toInt() ?? 5,
      text: data['text'] as String? ?? '',
      imageUrls:
          (data['imageUrls'] as List?)?.map((e) => e as String).toList() ??
          const [],
      date: DateTime.tryParse(data['date'] as String? ?? '') ?? DateTime.now(),
      verifiedPurchase: data['verifiedPurchase'] as bool? ?? true,
      status: data['status'] as String? ?? 'pending',
    );
  }
}
