enum SellerToolCategory {
  shipping,
  postageLabels,
  packaging,
  bookkeeping,
  photography,
  backgroundRemoval,
  inventorySupplies,
  ecommerceTools,
  marketplaceTools,
}

class AffiliateOffer {
  const AffiliateOffer({
    required this.id,
    required this.title,
    required this.provider,
    required this.description,
    required this.category,
    required this.destinationUrl,
    required this.trackingUrl,
    required this.countryAvailability,
    required this.disclosureText,
    required this.enabled,
    required this.priority,
    this.startDate,
    this.endDate,
    this.imageAsset,
  });

  final String id;
  final String title;
  final String provider;
  final String description;
  final SellerToolCategory category;
  final Uri destinationUrl;
  final Uri trackingUrl;
  final List<String> countryAvailability;
  final String disclosureText;
  final bool enabled;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? imageAsset;
  final int priority;

  bool availableFor(String countryCode, DateTime now) {
    if (!enabled || !countryAvailability.contains(countryCode)) return false;
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }
}
