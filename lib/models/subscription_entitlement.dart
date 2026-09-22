class SubscriptionEntitlement {
  const SubscriptionEntitlement({
    required this.active,
    required this.state,
    this.productId,
    this.basePlanId,
    this.offerId,
    this.expiresAt,
    this.autoRenewing = false,
  });

  const SubscriptionEntitlement.inactive()
    : active = false,
      state = 'SUBSCRIPTION_STATE_UNSPECIFIED',
      productId = null,
      basePlanId = null,
      offerId = null,
      expiresAt = null,
      autoRenewing = false;

  final bool active;
  final String state;
  final String? productId;
  final String? basePlanId;
  final String? offerId;
  final DateTime? expiresAt;
  final bool autoRenewing;

  factory SubscriptionEntitlement.fromJson(
    Map<String, dynamic> json, {
    DateTime? now,
  }) {
    final referenceTime = now ?? DateTime.now();
    final expiresAt = _dateTime(json['expiresAt'] ?? json['expiryTime']);
    final state =
        json['state'] as String? ??
        json['status'] as String? ??
        'SUBSCRIPTION_STATE_UNSPECIFIED';
    final serverActive =
        json['active'] as bool? ??
        const {
          'active',
          'grace_period',
          'canceled',
          'SUBSCRIPTION_STATE_ACTIVE',
          'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
          'SUBSCRIPTION_STATE_CANCELED',
        }.contains(state);
    final hasNotExpired = expiresAt == null || expiresAt.isAfter(referenceTime);

    return SubscriptionEntitlement(
      active: serverActive && hasNotExpired,
      state: state,
      productId: json['productId'] as String?,
      basePlanId: json['basePlanId'] as String? ?? json['planId'] as String?,
      offerId: json['offerId'] as String?,
      expiresAt: expiresAt,
      autoRenewing: json['autoRenewing'] as bool? ?? false,
    );
  }

  static DateTime? _dateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    try {
      final converted = (value as dynamic)?.toDate();
      return converted is DateTime ? converted : null;
    } on Object {
      return null;
    }
  }
}
