class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.type,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
    this.email,
    this.adminResponse,
  });

  final String id;
  final String ticketNumber;
  final String type;
  final String subject;
  final String message;
  final String status;
  final DateTime createdAt;
  final String? email;
  final String? adminResponse;

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
    id: json['id'] as String,
    ticketNumber: json['ticketNumber'] as String,
    type: json['type'] as String? ?? 'feedback',
    subject: json['subject'] as String? ?? '',
    message: json['message'] as String? ?? '',
    status: json['status'] as String? ?? 'open',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    email: json['email'] as String?,
    adminResponse: json['adminResponse'] as String?,
  );
}
