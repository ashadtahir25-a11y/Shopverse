import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../product/models/product_model.dart';
import '../../product/providers/product_provider.dart';
import 'wishlist_provider.dart';

/// The wishlist as it should be DISPLAYED: every saved item swapped for
/// the current version of that product from the live catalog.
///
/// A wishlist entry is stored as a copy of the product from the moment
/// it was hearted, so its price/discount went stale whenever an admin
/// edited the product (Home showed Rs. 7500 while Wishlist still said
/// Rs. 7000). Rather than depending on the notifier being pushed new
/// data, this works out the live version at read time from the same
/// `productsProvider` stream the Home screen uses — so the two screens
/// can never disagree.
///
/// A product that is no longer in the catalog (unpublished/deleted)
/// keeps its saved copy, so its heart can still be un-tapped.
final liveWishlistProvider = Provider<List<Product>>((ref) {
  final saved = ref.watch(wishlistProvider);
  final live = ref.watch(productsProvider).valueOrNull;
  if (live == null || live.isEmpty) return saved;

  final byId = {for (final p in live) p.id: p};
  return [for (final p in saved) byId[p.id] ?? p];
});
