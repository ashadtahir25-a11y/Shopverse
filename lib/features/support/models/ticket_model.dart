enum TicketStatus { open, inProgress, resolved, closed }

extension TicketStatusX on TicketStatus {
  String get label => switch (this) {
    TicketStatus.open => 'Open',
    TicketStatus.inProgress => 'In Progress',
    TicketStatus.resolved => 'Resolved',
    TicketStatus.closed => 'Closed',
  };

  static TicketStatus fromWire(String value) => TicketStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => TicketStatus.open,
  );
}

class TicketResponse {
  final String author; // 'Customer' or 'Support Team'
  final String message;
  final DateTime timestamp;

  const TicketResponse({
    required this.author,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'author': author,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TicketResponse.fromMap(Map<String, dynamic> map) => TicketResponse(
    author: map['author'] as String? ?? 'Support Team',
    message: map['message'] as String? ?? '',
    timestamp:
        DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
  );
}

class SupportTicket {
  final String id;
  final String userId;
  final String customerName;
  final String customerEmail;
  final String subject;
  final String message;
  final DateTime createdAt;
  final TicketStatus status;
  final List<TicketResponse> responses;

  const SupportTicket({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.subject,
    required this.message,
    required this.createdAt,
    this.status = TicketStatus.open,
    this.responses = const [],
  });

  SupportTicket copyWith({
    TicketStatus? status,
    List<TicketResponse>? responses,
  }) {
    return SupportTicket(
      id: id,
      userId: userId,
      customerName: customerName,
      customerEmail: customerEmail,
      subject: subject,
      message: message,
      createdAt: createdAt,
      status: status ?? this.status,
      responses: responses ?? this.responses,
    );
  }

  Map<String, dynamic> toFirestoreMap() => {
    'userId': userId,
    'customerName': customerName,
    'customerEmail': customerEmail,
    'subject': subject,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'responses': responses.map((r) => r.toMap()).toList(),
  };

  factory SupportTicket.fromFirestore(String id, Map<String, dynamic> data) {
    return SupportTicket(
      id: id,
      userId: data['userId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Unknown',
      customerEmail: data['customerEmail'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      message: data['message'] as String? ?? '',
      createdAt:
          DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.now(),
      status: TicketStatusX.fromWire(data['status'] as String? ?? 'open'),
      responses: (data['responses'] as List? ?? [])
          .map(
            (r) => TicketResponse.fromMap(Map<String, dynamic>.from(r as Map)),
          )
          .toList(),
    );
  }
}
