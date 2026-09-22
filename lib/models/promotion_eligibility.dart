class PromotionEligibility {
  const PromotionEligibility({
    required this.availableOfferTags,
    this.bestOfferTag,
    this.founderSpotsRemaining,
  });

  final List<String> availableOfferTags;
  final String? bestOfferTag;
  final int? founderSpotsRemaining;

  factory PromotionEligibility.fromJson(Map<String, dynamic> json) =>
      PromotionEligibility(
        availableOfferTags: (json['availableOfferTags'] as List<dynamic>? ?? [])
            .whereType<String>()
            .toList(growable: false),
        bestOfferTag: json['bestOfferTag'] as String?,
        founderSpotsRemaining: (json['founderSpotsRemaining'] as num?)?.toInt(),
      );
}
