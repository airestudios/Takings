import 'package:profit_track/features/seller_tools/domain/affiliate_offer.dart';
import 'package:profit_track/features/seller_tools/domain/sponsorship_campaign.dart';

class SellerToolsRepository {
  const SellerToolsRepository();

  Future<List<AffiliateOffer>> affiliateOffers() async => const [];

  Future<List<SponsorshipCampaign>> sponsorships() async => const [];
}
