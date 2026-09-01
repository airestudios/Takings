import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_track/features/seller_tools/data/seller_tools_repository.dart';
import 'package:profit_track/features/seller_tools/domain/affiliate_offer.dart';

final sellerToolsRepositoryProvider = Provider<SellerToolsRepository>(
  (ref) => const SellerToolsRepository(),
);

final affiliateOffersProvider = FutureProvider<List<AffiliateOffer>>((ref) {
  return ref.watch(sellerToolsRepositoryProvider).affiliateOffers();
});
