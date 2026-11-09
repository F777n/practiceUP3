import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models/load_status.dart';
import '../models/product_query.dart';
import '../navigation.dart';
import '../forms/validators.dart';
import '../repositories/brand_repository.dart';
import '../repositories/directory_repositories.dart';
import '../repositories/product_repository.dart';
import '../state/brand_details_notifier.dart';
import '../state/brand_list_notifier.dart';
import '../widgets/catalog_widgets.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/status_views.dart';

class BrandDetailsPage extends StatefulWidget {
  const BrandDetailsPage({super.key, required this.id});

  final int id;

  @override
  State<BrandDetailsPage> createState() => _BrandDetailsPageState();
}

class _BrandDetailsPageState extends State<BrandDetailsPage> {
  late final BrandDetailsNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = BrandDetailsNotifier(
      context.read<BrandRepository>(),
      context.read<ProductRepository>(),
      context.read<CategoryRepository>(),
    )..load(widget.id);
  }

  @override
  void didUpdateWidget(covariant BrandDetailsPage oldWidget) {
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
      child: const BrandDetailsView(),
    );
  }
}

class BrandDetailsView extends StatelessWidget {
  const BrandDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BrandDetailsNotifier>();
    final back = context.read<ListLocationMemory>().brands;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () => context.go(back),
                icon: const Icon(Icons.arrow_back),
                label: const Text('К списку'),
              ),
            ),
            const SizedBox(height: 16),
            _content(context, notifier),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, BrandDetailsNotifier notifier) {
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
          onRetry: () => notifier.load(notifier.brand?.id ?? 0),
        );
      case LoadStatus.success:
        if (notifier.permanentlyDeleted) {
          return const EmptyView(
            title: 'Бренд удалён навсегда',
            message: 'Запись стёрта из памяти.',
          );
        }
        final brand = notifier.brand;
        if (brand == null) {
          return const EmptyView(
            title: 'Бренд не найден',
            message: 'Такой записи нет.',
          );
        }
        final scheme = Theme.of(context).colorScheme;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (brand.isDeleted) ...[
                  const DeletedBadge(),
                  const SizedBox(height: 8),
                  Text('Скрыт ${formatDateTime(brand.deletedAt!)}'),
                  const SizedBox(height: 12),
                ],
                Text(brand.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: 220,
                      child: DetailLine(label: 'Страна', value: brand.country),
                    ),
                    SizedBox(
                      width: 220,
                      child: DetailLine(
                        label: 'Год основания',
                        value: '${brand.foundedYear}',
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      child: DetailLine(
                        label: 'Специализация',
                        value: brand.specialization,
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      child: DetailLine(label: 'Почта', value: brand.email),
                    ),
                    SizedBox(
                      width: 280,
                      child: DetailLine(label: 'Категории', value: notifier.categories),
                    ),
                    SizedBox(
                      width: 220,
                      child: DetailLine(
                        label: 'Товаров в каталоге',
                        value: plural(
                          notifier.productCount,
                          'товар',
                          'товара',
                          'товаров',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () => context.go('/brands/${brand.id}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Изменить'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () {
                    context.go(ProductQuery(brandId: brand.id).toLocation());
                  },
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Товары этого бренда'),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (!brand.isDeleted)
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

  Future<bool> _blocked(BuildContext context, BrandDetailsNotifier notifier) async {
    final message = linkedDeleteMessage(notifier.brand?.name ?? 'Бренд', notifier.productCount);
    if (message == null) return false;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление невозможно'),
        content: Text(message),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Понятно')),
        ],
      ),
    );
    return true;
  }

  Future<void> _soft(BuildContext context, BrandDetailsNotifier notifier) async {
    if (await _blocked(context, notifier)) return;
    if (!context.mounted) return;
    final name = notifier.brand?.name ?? '';
    final ok = await confirmAction(
      context,
      title: 'Скрыть бренд',
      message: 'Скрыть «$name»?',
      confirmLabel: 'Скрыть',
    );
    if (!ok || !context.mounted) return;
    final done = await notifier.softDelete();
    if (done && context.mounted) {
      await context.read<BrandListNotifier>().load();
    }
  }

  Future<void> _restore(BuildContext context, BrandDetailsNotifier notifier) async {
    final done = await notifier.restore();
    if (done && context.mounted) {
      await context.read<BrandListNotifier>().load();
    }
  }

  Future<void> _hard(BuildContext context, BrandDetailsNotifier notifier) async {
    if (await _blocked(context, notifier)) return;
    if (!context.mounted) return;
    final name = notifier.brand?.name ?? '';
    final ok = await confirmAction(
      context,
      title: 'Удалить навсегда',
      message: 'Стереть бренд «$name»?',
      confirmLabel: 'Удалить',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    final done = await notifier.hardDelete();
    if (done && context.mounted) {
      await context.read<BrandListNotifier>().load();
    }
  }
}
