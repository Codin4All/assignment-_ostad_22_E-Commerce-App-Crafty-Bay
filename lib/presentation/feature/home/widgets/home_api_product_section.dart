import 'package:crafty_bay/core/app_strings.dart';
import 'package:crafty_bay/domain/entities/product.dart';
import 'package:crafty_bay/presentation/core/product_card.dart';
import 'package:crafty_bay/presentation/core/product_grid_page.dart';
import 'package:crafty_bay/presentation/core/product_section.dart';
import 'package:crafty_bay/presentation/feature/cart/provider/cart_provider.dart';
import 'package:crafty_bay/presentation/feature/product_details/view/product_details_api_page.dart';
import 'package:crafty_bay/presentation/feature/wishlist/provider/wishlist_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Home row of API products, sized so three cards fit on screen.
/// "See All" opens the full list in a [ProductGridPage].
class HomeApiProductSection extends StatelessWidget {
  const HomeApiProductSection({
    super.key,
    required this.title,
    required this.products,
  });

  final String title;
  final List<Product> products;

  void _openDetails(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsApiPage(productId: product.id),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context, Product product) async {
    final cart = context.read<CartProvider>();
    final success = await cart.add(productId: product.id, quantity: 1);
    if (!context.mounted) return;

    final message = success ? AppStrings.addedToCart : cart.errorMessage;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // Consumer (not context.watch) because this also runs inside the pushed
  // "See All" route, where the section's own context is not building.
  Widget _card(BuildContext context, Product product, {double? width}) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlist, _) => ProductCard(
        width: width,
        image: NetworkImage(
          product.photos.isNotEmpty ? product.photos.first : '',
        ),
        title: product.title,
        price: r'$' + product.currentPrice.toString(),
        isWished: wishlist.isWished(product.id),
        onTap: () => _openDetails(context, product),
        onWishTap: () => wishlist.toggle(product.id),
        onCartTap: () => _addToCart(context, product),
      ),
    );
  }

  void _openAll(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductGridPage(
          title: title,
          itemCount: products.length,
          itemBuilder: (_, i) => _card(context, products[i]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = (MediaQuery.sizeOf(context).width - 10 - 10) / 3;

    return ProductSection(
      title: title,
      seeAllLabel: AppStrings.seeAll,
      onSeeAllTap: () => _openAll(context),
      itemCount: products.length,
      itemBuilder: (_, i) => _card(context, products[i], width: cardWidth),
    );
  }
}
