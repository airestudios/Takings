class SponsorshipCampaign {
  const SponsorshipCampaign({
    required this.id,
    required this.campaignName,
    required this.advertiserName,
    required this.headline,
    required this.body,
    required this.cta,
    required this.destinationUrl,
    required this.countryCodes,
    required this.placementIds,
    required this.startDate,
    required this.endDate,
    required this.impressionCap,
    required this.clickCap,
    required this.enabled,
    required this.disclosureText,
    this.imageUrl,
  });

  final String id;
  final String campaignName;
  final String advertiserName;
  final String headline;
  final String body;
  final String cta;
  final Uri destinationUrl;
  final Uri? imageUrl;
  final List<String> countryCodes;
  final List<String> placementIds;
  final DateTime startDate;
  final DateTime endDate;
  final int impressionCap;
  final int clickCap;
  final bool enabled;
  final String disclosureText;
}
