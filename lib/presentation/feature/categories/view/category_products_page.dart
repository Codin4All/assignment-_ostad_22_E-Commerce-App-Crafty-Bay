import 'package:crafty_bay/core/app_colors.dart';
import 'package:crafty_bay/core/app_strings.dart';
import 'package:crafty_bay/domain/entities/category.dart';
import 'package:crafty_bay/domain/entities/product.dart';
import 'package:crafty_bay/presentation/core/product_card.dart';
import 'package:crafty_bay/presentation/core/product_grid_page.dart';
import 'package:crafty_bay/presentation/feature/cart/provider/cart_provider.dart';
import 'package:crafty_bay/presentation/feature/home/provider/product_provider.dart';
import 'package:crafty_bay/presentation/feature/product_details/view/product_details_api_page.dart';
import 'package:crafty_bay/presentation/feature/wishlist/provider/wishlist_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Products opened from a category tile. API products keep their real ids,
/// which enables the same wishlist and product-details/cart actions as Home.
class CategoryProductsPage extends StatefulWidget {
  const CategoryProductsPage({super.key, required this.category});

  final Category category;

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final products = context.read<ProductProvider>();
      if (products.products.isEmpty && !products.isLoading) {
        products.fetchProducts();
      }
    });
  }

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

  Future<void> _toggleWishlist(
    BuildContext context,
    WishlistProvider wishlist,
    Product product,
  ) async {
    final wasWished = wishlist.isWished(product.id);
    final success = await wishlist.toggle(product.id);
    if (!context.mounted) return;

    final message = success
        ? wasWished
              ? AppStrings.removedFromWishlist
              : AppStrings.addedToWishlist
        : wishlist.errorMessage;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.products.isEmpty && provider.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: Text(widget.category.title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.products.isEmpty && provider.errorMessage.isNotEmpty) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: Text(widget.category.title)),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.errorMessage),
                  TextButton(
                    onPressed: provider.fetchProducts,
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
          );
        }

        final products = provider.products;
        return ProductGridPage(
          title: widget.category.title,
          itemCount: products.length,
          itemBuilder: (_, i) {
            final product = products[i];
            return Consumer<WishlistProvider>(
              builder: (context, wishlist, _) => ProductCard(
                image: NetworkImage(
                  product.photos.isNotEmpty ? product.photos.first : '',
                ),
                title: product.title,
                price: r'$' + product.currentPrice.toString(),
                isWished: wishlist.isWished(product.id),
                onTap: () => _openDetails(context, product),
                onWishTap: () => _toggleWishlist(context, wishlist, product),
                onCartTap: () => _addToCart(context, product),
              ),
            );
          },
        );
      },
    );
  }
}
