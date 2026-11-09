import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'forms/form_guard.dart';
import 'models/category.dart';
import 'models/category_query.dart';
import 'models/customer.dart';
import 'models/customer_query.dart';
import 'models/discipline.dart';
import 'models/discipline_query.dart';
import 'navigation.dart';
import 'repositories/brand_repository.dart';
import 'repositories/directory_repositories.dart';
import 'repositories/in_memory_brand_repository.dart';
import 'repositories/in_memory_product_repository.dart';
import 'repositories/product_repository.dart';
import 'router.dart';
import 'state/brand_list_notifier.dart';
import 'state/product_list_notifier.dart';
import 'state/simple_list_notifier.dart';
import 'storage/catalog_store.dart';
import 'theme.dart';

Widget buildRingApp({CatalogSession? session}) {
  final products = session?.products ?? InMemoryProductRepository();
  final brands = session?.brands ?? InMemoryBrandRepository();
  final categories = session?.categories ?? InMemoryCategoryRepository();
  final disciplines = session?.disciplines ?? InMemoryDisciplineRepository();
  final customers = session?.customers ?? InMemoryCustomerRepository();
  final notice = session?.notice ?? StorageNotice(null);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeController()),
      ChangeNotifierProvider(create: (_) => FormGuard()),
      ChangeNotifierProvider<StorageNotice>.value(value: notice),
      Provider(create: (_) => ListLocationMemory()),
      Provider<ProductRepository>.value(value: products),
      Provider<BrandRepository>.value(value: brands),
      Provider<CategoryRepository>.value(value: categories),
      Provider<DisciplineRepository>.value(value: disciplines),
      Provider<CustomerRepository>.value(value: customers),
      ChangeNotifierProvider(
        create: (context) => ProductListNotifier(
          context.read<ProductRepository>(),
          context.read<BrandRepository>(),
          context.read<CategoryRepository>(),
        ),
      ),
      ChangeNotifierProvider(
        create: (context) => BrandListNotifier(context.read<BrandRepository>()),
      ),
      ChangeNotifierProvider(
        create: (context) => SimpleListNotifier<Category, CategoryQuery>(
          find: context.read<CategoryRepository>().find,
          softDeleteById: context.read<CategoryRepository>().softDelete,
          hardDeleteById: context.read<CategoryRepository>().hardDelete,
          restoreById: context.read<CategoryRepository>().restore,
          deleteManyById: context.read<CategoryRepository>().deleteMany,
          initialQuery: const CategoryQuery(),
          failureText: 'Учебная имитация: справочник категорий не ответил',
        ),
      ),
      ChangeNotifierProvider(
        create: (context) => SimpleListNotifier<Discipline, DisciplineQuery>(
          find: context.read<DisciplineRepository>().find,
          softDeleteById: context.read<DisciplineRepository>().softDelete,
          hardDeleteById: context.read<DisciplineRepository>().hardDelete,
          restoreById: context.read<DisciplineRepository>().restore,
          deleteManyById: context.read<DisciplineRepository>().deleteMany,
          initialQuery: const DisciplineQuery(),
          failureText: 'Учебная имитация: справочник дисциплин не ответил',
        ),
      ),
      ChangeNotifierProvider(
        create: (context) => SimpleListNotifier<Customer, CustomerQuery>(
          find: context.read<CustomerRepository>().find,
          softDeleteById: context.read<CustomerRepository>().softDelete,
          hardDeleteById: context.read<CustomerRepository>().hardDelete,
          restoreById: context.read<CustomerRepository>().restore,
          deleteManyById: context.read<CustomerRepository>().deleteMany,
          initialQuery: const CustomerQuery(),
          failureText: 'Учебная имитация: справочник клиентов не ответил',
        ),
      ),
    ],
    child: RingApp(router: createRouter()),
  );
}

class RingApp extends StatelessWidget {
  const RingApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    return MaterialApp.router(
      title: 'Ринг — боксёрские принадлежности',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: theme.mode,
      routerConfig: router,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      scrollBehavior: const AppScrollBehavior(),
    );
  }
}
