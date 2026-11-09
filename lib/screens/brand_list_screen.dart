import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../forms/validators.dart';
import '../format.dart';
import '../repositories/product_repository.dart';
import '../models/brand.dart';
import '../models/brand_query.dart';
import '../models/load_status.dart';
import '../navigation.dart';
import '../state/brand_list_notifier.dart';
import '../theme.dart';
import '../widgets/catalog_widgets.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/delayed_search_field.dart';
import '../widgets/entity_card_list.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/status_views.dart';

class BrandListScreen extends StatefulWidget {
  const BrandListScreen({super.key, required this.query});

  final BrandQuery query;

  @override
  State<BrandListScreen> createState() => _BrandListScreenState();
}

class _BrandListScreenState extends State<BrandListScreen> {
  BrandQuery? _synced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(widget.query);
  }

  @override
  void didUpdateWidget(covariant BrandListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _sync(widget.query);
  }

  void _sync(BrandQuery query) {
    context.read<ListLocationMemory>().brands = query.toLocation();
    if (_synced == query) return;
    _synced = query;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _synced != query) return;
      context.read<BrandListNotifier>().applyQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BrandListNotifier>();
    final query = widget.query;
    final cards = MediaQuery.sizeOf(context).width < kTableBreakpoint;
    return CatalogFrame(
      header: PageHeader(
        title: 'Бренды',
        subtitle: 'Страна и годы основания вместе с поиском остаются в адресе.',
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/brands/new'),
            icon: const Icon(Icons.add),
            label: const Text('Добавить'),
          ),
        ],
      ),
      filters: _filters(query, cards),
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
              totalLabel: plural(notifier.result.total, 'бренд', 'бренда', 'брендов'),
              size: query.size,
              onPage: (page) => goBrandQuery(context, query.copyWith(page: page)),
              onSize: (size) => goBrandQuery(context, query.copyWith(size: size)),
            )
          : const SizedBox(height: 48),
    );
  }

  Widget _filters(BrandQuery query, bool cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < kTableBreakpoint;
            final full = constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: narrow ? full : 280,
                  child: DelayedSearchField(
                    key: const Key('brand-search'),
                    value: query.search,
                    label: 'Поиск',
                    hint: 'Название или страна',
                    prefixIcon: Icons.search,
                    onDebounced: (value) {
                      goBrandQuery(context, query.copyWith(search: value));
                    },
                  ),
                ),
                SizedBox(
                  width: narrow ? full : 220,
                  child: FilterDropdown<String>(
                    label: 'Страна',
                    value: query.country,
                    items: _countryItems(query.country),
                    onChanged: (value) {
                      goBrandQuery(context, query.copyWith(country: value));
                    },
                  ),
                ),
                SizedBox(
                  width: narrow ? full : 140,
                  child: DelayedSearchField(
                    value: query.yearFrom?.toString() ?? '',
                    label: 'Год от',
                    digitsOnly: true,
                    keyboardType: TextInputType.number,
                    onDebounced: (value) {
                      goBrandQuery(context, query.copyWith(yearFrom: _brandYear(value)));
                    },
                  ),
                ),
                SizedBox(
                  width: narrow ? full : 140,
                  child: DelayedSearchField(
                    value: query.yearTo?.toString() ?? '',
                    label: 'Год до',
                    digitsOnly: true,
                    keyboardType: TextInputType.number,
                    onDebounced: (value) {
                      goBrandQuery(context, query.copyWith(yearTo: _brandYear(value)));
                    },
                  ),
                ),
                FilterChip(
                  label: const Text('Показывать удалённые'),
                  selected: query.includeDeleted,
                  onSelected: (value) {
                    goBrandQuery(context, query.copyWith(includeDeleted: value));
                  },
                ),
                TextButton.icon(
                  onPressed: query == const BrandQuery()
                      ? null
                      : () => goBrandQuery(context, const BrandQuery()),
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Сбросить'),
                ),
                IconButton(
                  tooltip: 'Обновить',
                  onPressed: context.read<BrandListNotifier>().load,
                  icon: const Icon(Icons.refresh),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Ещё',
                  onSelected: (value) {
                    if (value == 'error') {
                      context.read<BrandListNotifier>().demonstrateError();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'error',
                      child: Text('Показать состояние ошибки'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
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
                  goBrandQuery(
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
            'Сортировка: ${_sortCaption(query)}. Нажмите заголовок колонки.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _body(BrandListNotifier notifier, BrandQuery query, bool cards) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const LoadingView(message: 'Загружаем бренды…');
      case LoadStatus.error:
        return ErrorView(
          message: notifier.error ?? 'Неизвестная ошибка',
          onRetry: notifier.load,
        );
      case LoadStatus.success:
        if (notifier.result.items.isEmpty) {
          return EmptyView(
            title: 'Ничего не найдено',
            message: 'По этому запросу брендов нет.',
            actionLabel: query == const BrandQuery() ? null : 'Сбросить фильтры',
            onAction: () => goBrandQuery(context, const BrandQuery()),
          );
        }
        if (cards) {
          return EntityCardList<Brand>(
            items: notifier.result.items,
            idOf: (item) => item.id,
            selected: notifier.selected,
            onToggleSelect: notifier.toggleSelection,
            isDimmed: (item) => item.isDeleted,
            actions: _actions,
            body: (context, item) => _card(item),
          );
        }
        return EntityTable<Brand>(
          items: notifier.result.items,
          idOf: (item) => item.id,
          selected: notifier.selected,
          onToggleSelect: notifier.toggleSelection,
          sortField: query.sortField,
          sortAscending: query.sortAscending,
          isDimmed: (item) => item.isDeleted,
          onSort: (field) {
            goBrandQuery(
              context,
              query.copyWith(
                sortField: field,
                sortAscending: field == query.sortField ? !query.sortAscending : true,
              ),
            );
          },
          columns: [
            TableColumnSpec(
              label: 'Название',
              sortField: 'name',
              build: _titleCell,
            ),
            TableColumnSpec(
              label: 'Страна',
              sortField: 'country',
              build: (item) => Text(item.country),
            ),
            TableColumnSpec(
              label: 'Год основания',
              sortField: 'foundedYear',
              numeric: true,
              build: (item) => Text('${item.foundedYear}'),
            ),
            TableColumnSpec(
              label: 'Специализация',
              build: (item) => SizedBox(width: 240, child: Text(item.specialization)),
            ),
          ],
          actions: _actions,
        );
    }
  }

  Widget _card(Brand item) {
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
        Text('${item.country} · основан в ${item.foundedYear}'),
        Text(item.specialization),
      ],
    );
  }

  Widget _titleCell(Brand item) {
    return SizedBox(
      width: 180,
      child: Wrap(
        spacing: 8,
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

  List<Widget> _actions(Brand item) {
    final notifier = context.read<BrandListNotifier>();
    return [
      IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: 'Открыть карточку',
        onPressed: () => context.go('/brands/${item.id}'),
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

  Future<bool> _blocked(Brand item) async {
    final count = await context.read<ProductRepository>().countLinked(brandId: item.id);
    final message = linkedDeleteMessage(item.name, count);
    if (message == null || !mounted) return false;
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

  Future<void> _deleteSelected() async {
    final notifier = context.read<BrandListNotifier>();
    final picked = notifier.result.items.where((item) => notifier.selected.contains(item.id));
    for (final item in picked) {
      if (await _blocked(item)) return;
    }
    if (!mounted) return;
    final ok = await confirmAction(
      context,
      title: 'Скрыть выбранные',
      message:
          'Скрыть ${plural(notifier.selected.length, 'бренд', 'бренда', 'брендов')}?',
      confirmLabel: 'Скрыть',
    );
    if (!ok || !mounted) return;
    await notifier.deleteSelected();
  }

  Future<void> _softOne(Brand item) async {
    if (await _blocked(item)) return;
    if (!mounted) return;
    final ok = await confirmAction(
      context,
      title: 'Скрыть бренд',
      message: 'Скрыть «${item.name}»? Запись можно будет восстановить.',
      confirmLabel: 'Скрыть',
    );
    if (!ok || !mounted) return;
    await context.read<BrandListNotifier>().softDelete(item.id);
  }

  Future<void> _hardOne(Brand item) async {
    if (await _blocked(item)) return;
    if (!mounted) return;
    final ok = await confirmAction(
      context,
      title: 'Удалить навсегда',
      message: 'Стереть бренд «${item.name}» без восстановления?',
      confirmLabel: 'Удалить',
      danger: true,
    );
    if (!ok || !mounted) return;
    await context.read<BrandListNotifier>().hardDelete(item.id);
  }
}

List<DropdownMenuItem<String?>> _countryItems(String? selected) {
  final items = <DropdownMenuItem<String?>>[
    const DropdownMenuItem(value: null, child: Text('Все страны')),
    for (final country in brandCountries)
      DropdownMenuItem(value: country, child: Text(country)),
  ];
  if (selected != null && !brandCountries.contains(selected)) {
    items.add(DropdownMenuItem(value: selected, child: Text(selected)));
  }
  return items;
}

const _sortOptions = <(String, bool, String)>[
  ('name', true, 'Название А–Я'),
  ('name', false, 'Название Я–А'),
  ('country', true, 'Страна А–Я'),
  ('country', false, 'Страна Я–А'),
  ('foundedYear', true, 'Год по возрастанию'),
  ('foundedYear', false, 'Год по убыванию'),
];

int? _brandYear(String raw) {
  if (raw.trim().isEmpty) return null;
  return int.tryParse(raw.trim());
}

String _sortCaption(BrandQuery query) {
  final field = switch (query.sortField) {
    'country' => 'страна',
    'foundedYear' => 'год основания',
    _ => 'название',
  };
  final direction = query.sortAscending ? 'по возрастанию' : 'по убыванию';
  return '$field, $direction';
}
