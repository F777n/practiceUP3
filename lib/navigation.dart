import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'models/brand_query.dart';
import 'models/category_query.dart';
import 'models/customer_query.dart';
import 'models/discipline_query.dart';
import 'models/product_query.dart';

class ListLocationMemory {
  String products = '/products';
  String brands = '/brands';
  String categories = '/categories';
  String disciplines = '/disciplines';
  String customers = '/customers';
}

void goProductQuery(BuildContext context, ProductQuery next) {
  final current = ProductQuery.fromUri(GoRouterState.of(context).uri);
  if (current == next) return;
  final location = next.toLocation();
  context.read<ListLocationMemory>().products = location;
  context.go(location);
}

void goBrandQuery(BuildContext context, BrandQuery next) {
  final current = BrandQuery.fromUri(GoRouterState.of(context).uri);
  if (current == next) return;
  final location = next.toLocation();
  context.read<ListLocationMemory>().brands = location;
  context.go(location);
}

void goCategoryQuery(BuildContext context, CategoryQuery next) {
  final current = CategoryQuery.fromUri(GoRouterState.of(context).uri);
  if (current == next) return;
  final location = next.toLocation();
  context.read<ListLocationMemory>().categories = location;
  context.go(location);
}

void goDisciplineQuery(BuildContext context, DisciplineQuery next) {
  final current = DisciplineQuery.fromUri(GoRouterState.of(context).uri);
  if (current == next) return;
  final location = next.toLocation();
  context.read<ListLocationMemory>().disciplines = location;
  context.go(location);
}

void goCustomerQuery(BuildContext context, CustomerQuery next) {
  final current = CustomerQuery.fromUri(GoRouterState.of(context).uri);
  if (current == next) return;
  final location = next.toLocation();
  context.read<ListLocationMemory>().customers = location;
  context.go(location);
}
