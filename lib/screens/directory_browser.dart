import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../forms/validators.dart';
import '../models/load_status.dart';
import '../navigation.dart';
import '../state/simple_list_notifier.dart';
import '../theme.dart';
import '../widgets/catalog_widgets.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/delayed_search_field.dart';
import '../widgets/entity_card_list.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/status_views.dart';

class DirectoryColumn<T> {
  const DirectoryColumn({
    required this.label,
    required this.text,
    this.sortField,
    this.numeric = false,
    this.width,
  });

  final String label;
  final String? sortField;
  final bool numeric;
  final double? width;
  final String Function(T item) text;
}

class DirectoryBrowser<T, Q> extends StatefulWidget {
  const DirectoryBrowser({
    super.key,
    required this.query,
    required this.title,
    required this.subtitle,
    required this.basePath,
    required this.searchHint,
    required this.emptyText,
    required this.totalLabel,
    required this.remember,
    required this.columns,
    required this.cardText,
    required this.idOf,
    required this.nameOf,
    required this.isDeleted,
    required this.deletedAt,
    required this.filters,
    required this.sortOptions,
    required this.sortCaption,
    required this.linksOf,
    required this.searchOf,
    required this.deletedOf,
    required this.sortFieldOf,
    required this.sortAscendingOf,
    required this.sizeOf,
    required this.emptyQuery,
    required this.withSearch,
    required this.withDeleted,
    required this.withSort,
    required this.withPage,
  });

  final Q query;
  final String title;
  final String subtitle;
  final String basePath;
  final String searchHint;
  final String emptyText;
  final String Function(int total) totalLabel;
  final void Function(ListLocationMemory memory, String location) remember;
  final List<DirectoryColumn<T>> columns;
  final String Function(T item) cardText;
  final int Function(T item) idOf;
  final String Function(T item) nameOf;
  final bool Function(T item) isDeleted;
  final DateTime? Function(T item) deletedAt;
  final List<Widget> Function(BuildContext context, Q query, bool narrow, void Function(Q next) go) filters;
  final List<(String, bool, String)> sortOptions;
  final String Function(Q query) sortCaption;
  final Future<int> Function(int id) linksOf;
  final String Function(Q query) searchOf;
  final bool Function(Q query) deletedOf;
  final String Function(Q query) sortFieldOf;
  final bool Function(Q query) sortAscendingOf;
  final int Function(Q query) sizeOf;
  final Q emptyQuery;
  final Q Function(Q query, String search) withSearch;
  final Q Function(Q query, bool includeDeleted) withDeleted;
  final Q Function(Q query, String field, bool ascending) withSort;
  final Q Function(Q query, int? page, int? size) withPage;

  @override
  State<DirectoryBrowser<T, Q>> createState() => _DirectoryBrowserState<T, Q>();
}

class _DirectoryBrowserState<T, Q> extends State<DirectoryBrowser<T, Q>> {
  Q? _synced;

  SimpleListNotifier<T, Q> get _notifier => context.read<SimpleListNotifier<T, Q>>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(widget.query);
  }

  @override
  void didUpdateWidget(covariant DirectoryBrowser<T, Q> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _sync(widget.query);
  }

  void _sync(Q query) {
    widget.remember(context.read<ListLocationMemory>(), '$query');
    if (_synced == query) return;
    _synced = query;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _synced != query) return;
      _notifier.applyQuery(query);
    });
  }

  void _go(Q next) {
    if (widget.query == next) return;
    final location = '$next';
    widget.remember(context.read<ListLocationMemory>(), location);
    context.go(location);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SimpleListNotifier<T, Q>>();
    final cards = MediaQuery.sizeOf(context).width < kTableBreakpoint;
    final query = widget.query;
    return CatalogFrame(
      header: PageHeader(
        title: widget.title,
        subtitle: widget.subtitle,
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('${widget.basePath}/new'),
            icon: const Icon(Icons.add),
            label: const Text('Добавить'),
          ),
        ],
      ),
      filters: _filterBar(context, query, notifier),
      banner: notifier.hasSelection && notifier.status == LoadStatus.success
          ? SelectionBar(
              count: notifier.selected.length,
              onClear: notifier.clearSelection,
              onDelete: () => _deleteSelected(notifier),
            )
          : null,
      body: _body(notifier, query, cards),
      footer: notifier.status == LoadStatus.success
          ? PaginationBar(
              page: notifier.result.page,
              totalPages: notifier.result.totalPages,
              totalLabel: widget.totalLabel(notifier.result.total),
              size: widget.sizeOf(query),
              onPage: (page) => _go(widget.withPage(query, page, null)),
              onSize: (size) => _go(widget.withPage(query, null, size)),
            )
          : const SizedBox(height: 48),
    );
  }

  Widget _filterBar(BuildContext context, Q query, SimpleListNotifier<T, Q> notifier) {
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
                    value: widget.searchOf(query),
                    label: 'Поиск',
                    hint: widget.searchHint,
                    prefixIcon: Icons.search,
                    onDebounced: (value) => _go(widget.withSearch(query, value)),
                  ),
                ),
                ...widget.filters(context, query, narrow, _go),
                FilterChip(
                  label: const Text('Показывать удалённые'),
                  selected: widget.deletedOf(query),
                  onSelected: (value) => _go(widget.withDeleted(query, value)),
                ),
                TextButton.icon(
                  onPressed: query == widget.emptyQuery ? null : () => _go(widget.emptyQuery),
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Сбросить'),
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
                    PopupMenuItem(value: 'error', child: Text('Показать состояние ошибки')),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        if (MediaQuery.sizeOf(context).width < kTableBreakpoint)
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 280,
              child: FilterDropdown<String>(
                label: 'Сортировка',
                value: '${widget.sortFieldOf(query)}|${widget.sortAscendingOf(query)}',
                items: [
                  for (final option in widget.sortOptions)
                    DropdownMenuItem(
                      value: '${option.$1}|${option.$2}',
                      child: Text(option.$3),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  final parts = value.split('|');
                  _go(widget.withSort(query, parts.first, parts.last == 'true'));
                },
              ),
            ),
          )
        else
          Text(
            'Сортировка: ${widget.sortCaption(query)}. Нажмите заголовок колонки.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _body(SimpleListNotifier<T, Q> notifier, Q query, bool cards) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return LoadingView(message: 'Загружаем ${widget.title.toLowerCase()}…');
      case LoadStatus.error:
        return ErrorView(message: notifier.error ?? 'Неизвестная ошибка', onRetry: notifier.load);
      case LoadStatus.success:
        if (notifier.result.items.isEmpty) {
          return EmptyView(
            title: 'Ничего не найдено',
            message: widget.emptyText,
            actionLabel: query == widget.emptyQuery ? null : 'Сбросить фильтры',
            onAction: () => _go(widget.emptyQuery),
          );
        }
        if (cards) {
          return EntityCardList<T>(
            items: notifier.result.items,
            idOf: widget.idOf,
            selected: notifier.selected,
            onToggleSelect: notifier.toggleSelection,
            isDimmed: widget.isDeleted,
            actions: (item) => _actions(item, notifier),
            body: (context, item) => _card(item),
          );
        }
        return EntityTable<T>(
          items: notifier.result.items,
          idOf: widget.idOf,
          selected: notifier.selected,
          onToggleSelect: notifier.toggleSelection,
          sortField: widget.sortFieldOf(query),
          sortAscending: widget.sortAscendingOf(query),
          isDimmed: widget.isDeleted,
          onSort: (field) {
            final same = field == widget.sortFieldOf(query);
            _go(widget.withSort(query, field, same ? !widget.sortAscendingOf(query) : true));
          },
          columns: [
            for (final column in widget.columns)
              TableColumnSpec<T>(
                label: column.label,
                sortField: column.sortField,
                numeric: column.numeric,
                build: (item) => column.width == null
                    ? Text(column.text(item))
                    : SizedBox(width: column.width, child: Text(column.text(item))),
              ),
          ],
          actions: (item) => _actions(item, notifier),
        );
    }
  }

  Widget _card(T item) {
    final deleted = widget.deletedAt(item);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.nameOf(item), style: Theme.of(context).textTheme.titleMedium),
        if (deleted != null) ...[
          const SizedBox(height: 6),
          const DeletedBadge(),
          Text('Скрыт ${formatDateTime(deleted)}'),
        ],
        const SizedBox(height: 4),
        Text(widget.cardText(item)),
      ],
    );
  }

  List<Widget> _actions(T item, SimpleListNotifier<T, Q> notifier) {
    final id = widget.idOf(item);
    return [
      IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: 'Открыть',
        onPressed: () => context.go('${widget.basePath}/$id'),
        icon: const Icon(Icons.open_in_new),
      ),
      IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: 'Изменить',
        onPressed: () => context.go('${widget.basePath}/$id/edit'),
        icon: const Icon(Icons.edit_outlined),
      ),
      if (!widget.isDeleted(item))
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Скрыть',
          onPressed: () => _softOne(item),
          icon: const Icon(Icons.visibility_off_outlined),
        )
      else
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Восстановить',
          onPressed: () => notifier.restore(id),
          icon: const Icon(Icons.restore),
        ),
      IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: 'Удалить навсегда',
        onPressed: () => _hardOne(item),
        icon: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
      ),
    ];
  }

  Future<bool> _blocked(int id, String name) async {
    final count = await widget.linksOf(id);
    final message = linkedDeleteMessage(name, count);
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

  Future<void> _deleteSelected(SimpleListNotifier<T, Q> notifier) async {
    final picked = notifier.result.items.where((item) => notifier.selected.contains(widget.idOf(item)));
    for (final item in picked) {
      if (await _blocked(widget.idOf(item), widget.nameOf(item))) return;
    }
    if (!mounted) return;
    final ok = await confirmAction(
      context,
      title: 'Скрыть выбранные',
      message: 'Скрыть ${plural(notifier.selected.length, 'запись', 'записи', 'записей')}?',
      confirmLabel: 'Скрыть',
    );
    if (!ok || !mounted) return;
    await notifier.deleteSelected();
  }

  Future<void> _softOne(T item) async {
    if (await _blocked(widget.idOf(item), widget.nameOf(item))) return;
    if (!mounted) return;
    final ok = await confirmAction(
      context,
      title: 'Скрыть запись',
      message: 'Скрыть «${widget.nameOf(item)}»? Её можно будет восстановить.',
      confirmLabel: 'Скрыть',
    );
    if (!ok || !mounted) return;
    await _notifier.softDelete(widget.idOf(item));
  }

  Future<void> _hardOne(T item) async {
    if (await _blocked(widget.idOf(item), widget.nameOf(item))) return;
    if (!mounted) return;
    final ok = await confirmAction(
      context,
      title: 'Удалить навсегда',
      message: 'Стереть «${widget.nameOf(item)}» без восстановления?',
      confirmLabel: 'Удалить',
      danger: true,
    );
    if (!ok || !mounted) return;
    await _notifier.hardDelete(widget.idOf(item));
  }
}

Widget yearBox({
  required bool narrow,
  required double width,
  required String label,
  required String value,
  required ValueChanged<String> onDebounced,
}) {
  return SizedBox(
    width: narrow ? width : 140,
    child: DelayedSearchField(
      value: value,
      label: label,
      digitsOnly: true,
      keyboardType: TextInputType.number,
      onDebounced: onDebounced,
    ),
  );
}
