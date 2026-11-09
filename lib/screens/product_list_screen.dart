import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models/load_status.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../navigation.dart';
import '../state/product_list_notifier.dart';
import '../theme.dart';
import '../widgets/catalog_widgets.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/delayed_search_field.dart';
import '../widgets/entity_card_list.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/status_views.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, required this.query});

  final ProductQuery query;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  ProductQuery? _synced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(widget.query);
  }

  @override
  void didUpdateWidget(covariant ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _sync(widget.query);
  }

  void _sync(ProductQuery query) {
    context.read<ListLocationMemory>().products = query.toLocation();
    if (_synced == query) return;
    _synced = query;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _synced != query) return;
      context.read<ProductListNotifier>().applyQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ProductListNotifier>();
    final query = widget.query;
    final cards = MediaQuery.sizeOf(context).width < kTableBreakpoint;
    return CatalogFrame(
      header: PageHeader(
        title: 'Каталог товаров',
        subtitle:
            'Поиск, фильтры, сортировка и страница пишутся в адресе. Ссылку можно открыть заново.',
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/products/new'),
            icon: const Icon(Icons.add),
            label: const Text('Добавить'),
          ),
          IconButton(
            tooltip: 'Как работает удаление',
            onPressed: () => showDeleteHelp(context),
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
            tooltip: 'Обновить',
            onPressed: notifier.load,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            tooltip: 'Ещё',
            onSelected: (value) {
              if (value == 'error') notifier.demonstrateError();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'error',
                child: Text('Показать состояние ошибки'),
              ),
            ],
          ),
        ],
      ),
      filters: _filters(query, notifier, cards),
      banner: notifier.hasSelection && notifier.status == LoadStatus.success
          ? SelectionBar(
              count: notifier.selected.length,
              onClear: notifier.clearSelection,
              onDelete: _deleteSelected,
            )
          : null,
      body: _body(notifier, query, cards),
      footer: notifier.status == LoadStatus.success
          ? PaginationBar(
              page: notifier.result.page,
              totalPages: notifier.result.totalPages,
              totalLabel: plural(notifier.result.total, 'товар', 'товара', 'товаров'),
              size: query.size,
              onPage: (page) => goProductQuery(context, query.copyWith(page: page)),
              onSize: (size) => goProductQuery(context, query.copyWith(size: size)),
            )
          : const SizedBox(height: 48),
    );
  }

  Widget _filters(ProductQuery query, ProductListNotifier notifier, bool cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < kTableBreakpoint;
            final full = constraints.maxWidth;
            final searchWidth = narrow ? full : 280.0;
            final fieldWidth = narrow ? full : 220.0;
            final yearWidth = narrow ? full : 140.0;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: searchWidth,
                  child: DelayedSearchField(
                    key: const Key('product-search'),
                    value: query.search,
                    label: 'Поиск',
                    hint: 'Название или артикул',
                    prefixIcon: Icons.search,
                    onDebounced: (value) {
                      goProductQuery(context, query.copyWith(search: value));
                    },
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: FilterDropdown<int>(
                    label: 'Категория',
                    value: _knownId(query.categoryId, notifier.categories.map((c) => c.id)),
                    items: _categoryItems(notifier, query.categoryId),
                    onChanged: (value) {
                      goProductQuery(context, query.copyWith(categoryId: value));
                    },
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: FilterDropdown<int>(
                    label: 'Бренд',
                    value: _knownId(query.brandId, notifier.brandOptions.map((b) => b.id)),
                    items: _brandItems(notifier, query.brandId),
                    onChanged: (value) {
                      goProductQuery(context, query.copyWith(brandId: value));
                    },
                  ),
                ),
                SizedBox(
                  width: yearWidth,
                  child: DelayedSearchField(
                    value: query.yearFrom?.toString() ?? '',
                    label: 'Год от',
                    digitsOnly: true,
                    keyboardType: TextInputType.number,
                    onDebounced: (value) => _applyYear(query, from: value),
                  ),
                ),
                SizedBox(
                  width: yearWidth,
                  child: DelayedSearchField(
                    value: query.yearTo?.toString() ?? '',
                    label: 'Год до',
                    digitsOnly: true,
                    keyboardType: TextInputType.number,
                    onDebounced: (value) => _applyYear(query, to: value),
                  ),
                ),
                FilterChip(
                  label: const Text('Показывать удалённые'),
                  selected: query.includeDeleted,
                  onSelected: (value) {
                    goProductQuery(context, query.copyWith(includeDeleted: value));
                  },
                ),
                TextButton.icon(
                  onPressed: query == const ProductQuery()
                      ? null
                      : () => goProductQuery(context, const ProductQuery()),
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Сбросить'),
                ),
              ],
            );
          },
        ),
        _chips(query, notifier),
        const SizedBox(height: 8),
        if (cards)
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 280,
              child: FilterDropdown<String>(
                label: 'Сортировка',
                value: '${query.sortField}|${query.sortAscending}',
                items: [
                  for (final option in _sortOptions)
                    DropdownMenuItem(
                      value: '${option.$1}|${option.$2}',
                      child: Text(option.$3),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  final parts = value.split('|');
                  goProductQuery(
                    context,
                    query.copyWith(
                      sortField: parts.first,
                      sortAscending: parts.last == 'true',
                    ),
                  );
                },
              ),
            ),
          )
        else
          Text(
            'Сортировка: ${_sortCaption(query)}. Нажмите заголовок колонки, чтобы сменить поле или направление.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _chips(ProductQuery query, ProductListNotifier notifier) {
    final chips = <Widget>[];
    void add(String label, ProductQuery next) {
      chips.add(
        InputChip(
          label: Text(label),
          onDeleted: () => goProductQuery(context, next),
        ),
      );
    }

    if (query.search.isNotEmpty) {
      add('Поиск: ${query.search}', query.copyWith(search: ''));
    }
    if (query.categoryId != null) {
      add(
        notifier.categoryTitle(query.categoryId!),
        query.copyWith(categoryId: null),
      );
    }
    if (query.brandId != null) {
      add(notifier.brandName(query.brandId!), query.copyWith(brandId: null));
    }
    if (query.yearFrom != null) {
      add('С ${query.yearFrom}', query.copyWith(yearFrom: null));
    }
    if (query.yearTo != null) {
      add('До ${query.yearTo}', query.copyWith(yearTo: null));
    }
    if (query.includeDeleted) {
      add('Удалённые', query.copyWith(includeDeleted: false));
    }
    if (query.sortField != 'name' || !query.sortAscending) {
      add(
        _sortCaption(query),
        query.copyWith(sortField: 'name', sortAscending: true),
      );
    }
    if (query.size != 10) {
      add('По ${query.size}', query.copyWith(size: 10));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _body(ProductListNotifier notifier, ProductQuery query, bool cards) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView(message: 'Загружаем каталог…');
      case LoadStatus.error:
        return ErrorView(
          message: notifier.error ?? 'Неизвестная ошибка',
          onRetry: notifier.load,
        );
      case LoadStatus.success:
        if (notifier.result.items.isEmpty) {
          final outOfRange = notifier.result.total > 0 &&
              query.page > notifier.result.totalPages;
          return EmptyView(
            title: outOfRange ? 'Такой страницы нет' : 'Ничего не найдено',
            message: outOfRange
                ? 'В этой выборке ${notifier.result.totalPages} стр.'
                : 'По этому запросу товаров нет. Измените условия или сбросьте их.',
            actionLabel: outOfRange
                ? 'На первую'
                : (query == const ProductQuery() ? null : 'Сбросить фильтры'),
            onAction: outOfRange
                ? () => goProductQuery(context, query.copyWith(page: 1))
                : () => goProductQuery(context, const ProductQuery()),
          );
        }
        if (cards) {
          return EntityCardList<Product>(
            items: notifier.result.items,
            idOf: (item) => item.id,
            selected: notifier.selected,
            onToggleSelect: notifier.toggleSelection,
            isDimmed: (item) => item.isDeleted,
            actions: _actions,
            body: (context, item) => _card(notifier, item),
          );
        }
        return EntityTable<Product>(
          items: notifier.result.items,
          idOf: (item) => item.id,
          selected: notifier.selected,
          onToggleSelect: notifier.toggleSelection,
          sortField: query.sortField,
          sortAscending: query.sortAscending,
          isDimmed: (item) => item.isDeleted,
          onSort: (field) {
            goProductQuery(
              context,
              query.copyWith(
                sortField: field,
                sortAscending:
                    field == query.sortField ? !query.sortAscending : true,
              ),
            );
          },
          columns: [
            TableColumnSpec(
              label: 'Название',
              sortField: 'name',
              build: (item) => _nameCell(item),
            ),
            TableColumnSpec(
              label: 'Артикул',
              build: (item) => SizedBox(
                width: 120,
                child: Text(item.sku, style: skuTextStyle),
              ),
            ),
            TableColumnSpec(
              label: 'Бренд',
              build: (item) => SizedBox(
                width: 130,
                child: Text(notifier.brandName(item.brandId)),
              ),
            ),
            TableColumnSpec(
              label: 'Категория',
              build: (item) => SizedBox(
                width: 170,
                child: Text(notifier.categoryNames(item.categoryIds)),
              ),
            ),
            TableColumnSpec(
              label: 'Год',
              sortField: 'year',
              numeric: true,
              build: (item) => Text('${item.year}'),
            ),
            TableColumnSpec(
              label: 'Цена',
              sortField: 'price',
              numeric: true,
              build: (item) => Text(formatRubles(item.priceRub)),
            ),
            TableColumnSpec(
              label: 'На складе',
              numeric: true,
              build: (item) => Text(
                '${item.stockAvailable} из ${item.stockTotal}',
                style: item.stockAvailable == 0
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : null,
              ),
            ),
          ],
          actions: _actions,
        );
    }
  }

  Widget _card(ProductListNotifier notifier, Product item) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                decoration: item.isDeleted ? TextDecoration.lineThrough : null,
              ),
        ),
        if (item.isDeleted) ...[
          const SizedBox(height: 6),
          const DeletedBadge(),
        ],
        const SizedBox(height: 6),
        Text(
          formatRubles(item.priceRub),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: scheme.primary),
        ),
        const SizedBox(height: 6),
        Text('Артикул ${item.sku}', style: skuTextStyle),
        Text('${notifier.brandName(item.brandId)} · ${notifier.categoryNames(item.categoryIds)}'),
        Text('Год ${item.year} · на складе ${item.stockAvailable} из ${item.stockTotal}'),
      ],
    );
  }

  Widget _nameCell(Product item) {
    return SizedBox(
      width: 250,
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            item.name,
            style: item.isDeleted
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
          if (item.isDeleted) const DeletedBadge(),
        ],
      ),
    );
  }

  List<Widget> _actions(Product item) {
    final notifier = context.read<ProductListNotifier>();
    return [
      IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: 'Открыть карточку',
        onPressed: () => context.go('/products/${item.id}'),
        icon: const Icon(Icons.visibility_outlined),
      ),
      if (!item.isDeleted)
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Скрыть (логическое удаление)',
          onPressed: () => _softOne(item),
          icon: const Icon(Icons.visibility_off_outlined),
        )
      else
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Восстановить',
          onPressed: () => notifier.restore(item.id),
          icon: const Icon(Icons.restore),
        ),
      IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: 'Удалить навсегда',
        onPressed: () => _hardOne(item),
        icon: Icon(
          Icons.delete_forever_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    ];
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<ProductListNotifier>();
    final count = notifier.selected.length;
    final ok = await confirmAction(
      context,
      title: 'Скрыть выбранные',
      message:
          'Скрыть ${plural(count, 'товар', 'товара', 'товаров')}? '
          'Они получат метку deletedAt и пропадут из каталога, '
          'пока не включён показ удалённых.',
      confirmLabel: 'Скрыть',
    );
    if (!ok || !mounted) return;
    await notifier.deleteSelected();
  }

  Future<void> _softOne(Product item) async {
    final ok = await confirmAction(
      context,
      title: 'Скрыть товар',
      message:
          'Скрыть «${item.name}»? Запись останется в памяти и её можно восстановить.',
      confirmLabel: 'Скрыть',
    );
    if (!ok || !mounted) return;
    await context.read<ProductListNotifier>().softDelete(item.id);
  }

  Future<void> _hardOne(Product item) async {
    final ok = await confirmAction(
      context,
      title: 'Удалить навсегда',
      message: 'Стереть «${item.name}» без возможности восстановления?',
      confirmLabel: 'Удалить',
      danger: true,
    );
    if (!ok || !mounted) return;
    await context.read<ProductListNotifier>().hardDelete(item.id);
  }

  void _applyYear(ProductQuery query, {String? from, String? to}) {
    if (from != null) {
      final parsed = from.isEmpty ? null : int.tryParse(from);
      if (from.isNotEmpty && parsed == null) return;
      goProductQuery(context, query.copyWith(yearFrom: parsed));
      return;
    }
    final raw = to ?? '';
    final parsed = raw.isEmpty ? null : int.tryParse(raw);
    if (raw.isNotEmpty && parsed == null) return;
    goProductQuery(context, query.copyWith(yearTo: parsed));
  }
}

int? _knownId(int? id, Iterable<int> existing) {
  if (id == null) return null;
  return existing.contains(id) ? id : id;
}

List<DropdownMenuItem<int?>> _categoryItems(
  ProductListNotifier notifier,
  int? selected,
) {
  final items = <DropdownMenuItem<int?>>[
    const DropdownMenuItem(value: null, child: Text('Все категории')),
    for (final category in notifier.categories)
      DropdownMenuItem(value: category.id, child: Text(category.name)),
  ];
  if (selected != null && !notifier.categories.any((item) => item.id == selected)) {
    items.add(
      DropdownMenuItem(
        value: selected,
        child: Text(notifier.categoryTitle(selected)),
      ),
    );
  }
  return items;
}

List<DropdownMenuItem<int?>> _brandItems(
  ProductListNotifier notifier,
  int? selected,
) {
  final items = <DropdownMenuItem<int?>>[
    const DropdownMenuItem(value: null, child: Text('Все бренды')),
    for (final brand in notifier.brandOptions)
      DropdownMenuItem(value: brand.id, child: Text(brand.name)),
  ];
  if (selected != null && !notifier.brandOptions.any((item) => item.id == selected)) {
    items.add(
      DropdownMenuItem(value: selected, child: Text(notifier.brandName(selected))),
    );
  }
  return items;
}

const _sortOptions = <(String, bool, String)>[
  ('name', true, 'Название А–Я'),
  ('name', false, 'Название Я–А'),
  ('year', true, 'Год по возрастанию'),
  ('year', false, 'Год по убыванию'),
  ('price', true, 'Цена по возрастанию'),
  ('price', false, 'Цена по убыванию'),
];

String _sortCaption(ProductQuery query) {
  final field = switch (query.sortField) {
    'year' => 'год',
    'price' => 'цена',
    _ => 'название',
  };
  final direction = query.sortAscending ? 'по возрастанию' : 'по убыванию';
  return '$field, $direction';
}
