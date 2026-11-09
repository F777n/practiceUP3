import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models/load_status.dart';
import '../navigation.dart';
import '../repositories/brand_repository.dart';
import '../repositories/directory_repositories.dart';
import '../repositories/product_repository.dart';
import '../state/product_details_notifier.dart';
import '../state/product_list_notifier.dart';
import '../widgets/catalog_widgets.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/status_views.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key, required this.id});

  final int id;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late final ProductDetailsNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ProductDetailsNotifier(
      context.read<ProductRepository>(),
      context.read<BrandRepository>(),
      context.read<CategoryRepository>(),
      context.read<DisciplineRepository>(),
    )..load(widget.id);
  }

  @override
  void didUpdateWidget(covariant ProductDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) _notifier.load(widget.id);
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _notifier,
      child: const ProductDetailsView(),
    );
  }
}

class ProductDetailsView extends StatelessWidget {
  const ProductDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ProductDetailsNotifier>();
    final back = context.read<ListLocationMemory>().products;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => context.go(back),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('К списку'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _content(context, notifier),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, ProductDetailsNotifier notifier) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const SizedBox(
          height: 280,
          child: LoadingView(message: 'Открываем карточку…'),
        );
      case LoadStatus.error:
        return ErrorView(
          message: notifier.error ?? 'Неизвестная ошибка',
          onRetry: () => notifier.load(
            notifier.product?.id ?? 0,
          ),
        );
      case LoadStatus.success:
        if (notifier.permanentlyDeleted) {
          return const EmptyView(
            title: 'Товар удалён навсегда',
            message: 'Запись стёрта из памяти. Вернуть её нельзя.',
          );
        }
        final product = notifier.product;
        if (product == null) {
          return const EmptyView(
            title: 'Товар не найден',
            message: 'Такой записи в каталоге нет.',
          );
        }
        final scheme = Theme.of(context).colorScheme;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.isDeleted) ...[
                  const DeletedBadge(),
                  const SizedBox(height: 8),
                  Text('Скрыт ${formatDateTime(product.deletedAt!)}'),
                  const SizedBox(height: 12),
                ],
                Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  formatRubles(product.priceRub),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: scheme.primary,
                      ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: 240,
                      child: DetailLine(label: 'Артикул', value: product.sku),
                    ),
                    SizedBox(
                      width: 240,
                      child: DetailLine(label: 'Год выпуска', value: '${product.year}'),
                    ),
                    SizedBox(
                      width: 240,
                      child: DetailLine(
                        label: 'Вес',
                        value: formatWeight(product.weightGrams),
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: DetailLine(
                        label: 'На складе',
                        value: '${product.stockAvailable} из ${product.stockTotal}',
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Бренд',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/brands/${product.brandId}'),
                            child: Text(notifier.brandName),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: DetailLine(label: 'Категории', value: notifier.categories),
                    ),
                    SizedBox(
                      width: 240,
                      child: DetailLine(label: 'Дисциплины', value: notifier.disciplines),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: product.stockTotal == 0
                      ? 0
                      : product.stockAvailable / product.stockTotal,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => context.go('/products/${product.id}/edit'),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Изменить'),
                    ),
                    if (!product.isDeleted)
                      OutlinedButton.icon(
                        onPressed: () => _soft(context, notifier),
                        icon: const Icon(Icons.visibility_off_outlined),
                        label: const Text('Скрыть'),
                      )
                    else
                      FilledButton.tonalIcon(
                        onPressed: () => _restore(context, notifier),
                        icon: const Icon(Icons.restore),
                        label: const Text('Восстановить'),
                      ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                      ),
                      onPressed: () => _hard(context, notifier),
                      icon: const Icon(Icons.delete_forever_outlined),
                      label: const Text('Удалить навсегда'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
    }
  }

  Future<void> _soft(BuildContext context, ProductDetailsNotifier notifier) async {
    final name = notifier.product?.name ?? '';
    final ok = await confirmAction(
      context,
      title: 'Скрыть товар',
      message: 'Скрыть «$name»? Его можно вернуть из списка удалённых.',
      confirmLabel: 'Скрыть',
    );
    if (!ok || !context.mounted) return;
    final done = await notifier.softDelete();
    if (done && context.mounted) {
      await context.read<ProductListNotifier>().load();
    }
  }

  Future<void> _restore(BuildContext context, ProductDetailsNotifier notifier) async {
    final done = await notifier.restore();
    if (done && context.mounted) {
      await context.read<ProductListNotifier>().load();
    }
  }

  Future<void> _hard(BuildContext context, ProductDetailsNotifier notifier) async {
    final name = notifier.product?.name ?? '';
    final ok = await confirmAction(
      context,
      title: 'Удалить навсегда',
      message: 'Стереть «$name» без возможности восстановления?',
      confirmLabel: 'Удалить',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    final done = await notifier.hardDelete();
    if (done && context.mounted) {
      await context.read<ProductListNotifier>().load();
    }
  }
}
