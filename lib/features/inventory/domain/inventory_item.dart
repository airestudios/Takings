enum InventoryStatus { unlisted, listed, sold }

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.item,
    required this.purchaseCostMinor,
    required this.purchaseDate,
    required this.marketplace,
    required this.listingPriceMinor,
    required this.category,
    this.status = InventoryStatus.unlisted,
    this.externalListingId,
    this.notes = '',
  });

  final String id;
  final String item;
  final int purchaseCostMinor;
  final DateTime purchaseDate;
  final String marketplace;
  final int listingPriceMinor;
  final String category;
  final InventoryStatus status;
  final String? externalListingId;
  final String notes;

  int get potentialProfitMinor => listingPriceMinor - purchaseCostMinor;
}
