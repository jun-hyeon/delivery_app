import 'package:delivery_app/common/component/pagination_list_view.dart';
import 'package:delivery_app/product/provider/product_provider.dart';
import 'package:delivery_app/restaurant/view/restaurant_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../component/product_card.dart';
import '../model/product_model.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return PaginationListView<ProductModel>(
        itemBuilder: <ProductModel>(_, index, model) {
          return GestureDetector(
            onTap: () {
              context.goNamed(
                RestaurantDetailScreen.routeName,
                pathParameters: {'rid': model.restaurant.id},
              );
            },
            child: ProductCard.fromProductModel(model: model),
          );
        },
        provider: productProvider);
  }
}
