import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models/category.dart';
import '../models/category_query.dart';
import '../models/customer.dart';
import '../models/customer_query.dart';
import '../models/discipline.dart';
import '../models/discipline_query.dart';
import '../models/load_status.dart';
import '../repositories/product_repository.dart';
import '../widgets/catalog_widgets.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/status_views.dart';
import 'directory_browser.dart';
import '../forms/validators.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key, required this.query});

  final CategoryQuery query;

  @override
  Widget build(BuildContext context) {
    return DirectoryBrowser<Category, CategoryQuery>(
      query: query,
      title: 'Категории',
      subtitle: 'Группы товаров. Удаление запрещено, если категория стоит на товаре.',
      basePath: '/categories',
      searchHint: 'Название или код',
      emptyText: 'По этому запросу категорий нет.',
      totalLabel: (total) => plural(total, 'категория', 'категории', 'категорий'),
      remember: (memory, location) => memory.categories = location,
      emptyQuery: const CategoryQuery(),
      searchOf: (item) => item.search,
      deletedOf: (item) => item.includeDeleted,
      sortFieldOf: (item) => item.sortField,
      sortAscendingOf: (item) => item.sortAscending,
      sizeOf: (item) => item.size,
      withSearch: (item, value) => item.copyWith(search: value),
      withDeleted: (item, value) => item.copyWith(includeDeleted: value),
      withSort: (item, field, ascending) => item.copyWith(sortField: field, sortAscending: ascending),
      withPage: (item, page, size) => item.copyWith(page: page, size: size),
      idOf: (item) => item.id,
      nameOf: (item) => item.name,
      isDeleted: (item) => item.isDeleted,
      deletedAt: (item) => item.deletedAt,
      cardText: (item) => '${item.code} · ${item.kind} · ${item.introducedYear}',
      linksOf: (id) => context.read<ProductRepository>().countLinked(categoryId: id),
      sortCaption: (item) {
        final field = switch (item.sortField) {
          'introducedYear' => 'год',
          'kind' => 'группа',
          _ => 'название',
        };
        return '$field, ${item.sortAscending ? 'по возрастанию' : 'по убыванию'}';
      },
      sortOptions: const [
        ('name', true, 'Название А–Я'),
        ('name', false, 'Название Я–А'),
        ('kind', true, 'Группа А–Я'),
        ('introducedYear', false, 'Год по убыванию'),
      ],
      columns: [
        DirectoryColumn(label: 'Название', sortField: 'name', text: (item) => item.name),
        DirectoryColumn(label: 'Код', text: (item) => item.code),
        DirectoryColumn(label: 'Группа', sortField: 'kind', text: (item) => item.kind),
        DirectoryColumn(
          label: 'Год',
          sortField: 'introducedYear',
          numeric: true,
          text: (item) => '${item.introducedYear}',
        ),
      ],
      filters: (context, item, narrow, go) {
        final width = MediaQuery.sizeOf(context).width;
        return [
          SizedBox(
            width: narrow ? width : 180,
            child: FilterDropdown<String>(
              label: 'Группа',
              value: item.kind,
              items: [
                const DropdownMenuItem(value: null, child: Text('Все группы')),
                for (final kind in categoryKinds) DropdownMenuItem(value: kind, child: Text(kind)),
              ],
              onChanged: (value) => go(item.copyWith(kind: value)),
            ),
          ),
          yearBox(
            narrow: narrow,
            width: width,
            label: 'Год от',
            value: item.yearFrom?.toString() ?? '',
            onDebounced: (value) => go(item.copyWith(yearFrom: _year(value))),
          ),
          yearBox(
            narrow: narrow,
            width: width,
            label: 'Год до',
            value: item.yearTo?.toString() ?? '',
            onDebounced: (value) => go(item.copyWith(yearTo: _year(value))),
          ),
        ];
      },
    );
  }
}

class DisciplineListScreen extends StatelessWidget {
  const DisciplineListScreen({super.key, required this.query});

  final DisciplineQuery query;

  @override
  Widget build(BuildContext context) {
    return DirectoryBrowser<Discipline, DisciplineQuery>(
      query: query,
      title: 'Дисциплины',
      subtitle: 'Единоборства, к которым относится товар. Связь многие ко многим.',
      basePath: '/disciplines',
      searchHint: 'Название или страна',
      emptyText: 'По этому запросу дисциплин нет.',
      totalLabel: (total) => plural(total, 'дисциплина', 'дисциплины', 'дисциплин'),
      remember: (memory, location) => memory.disciplines = location,
      emptyQuery: const DisciplineQuery(),
      searchOf: (item) => item.search,
      deletedOf: (item) => item.includeDeleted,
      sortFieldOf: (item) => item.sortField,
      sortAscendingOf: (item) => item.sortAscending,
      sizeOf: (item) => item.size,
      withSearch: (item, value) => item.copyWith(search: value),
      withDeleted: (item, value) => item.copyWith(includeDeleted: value),
      withSort: (item, field, ascending) => item.copyWith(sortField: field, sortAscending: ascending),
      withPage: (item, page, size) => item.copyWith(page: page, size: size),
      idOf: (item) => item.id,
      nameOf: (item) => item.name,
      isDeleted: (item) => item.isDeleted,
      deletedAt: (item) => item.deletedAt,
      cardText: (item) => '${item.country} · ${item.establishedYear}',
      linksOf: (id) => context.read<ProductRepository>().countLinked(disciplineId: id),
      sortCaption: (item) {
        final field = switch (item.sortField) {
          'country' => 'страна',
          'establishedYear' => 'год',
          _ => 'название',
        };
        return '$field, ${item.sortAscending ? 'по возрастанию' : 'по убыванию'}';
      },
      sortOptions: const [
        ('name', true, 'Название А–Я'),
        ('country', true, 'Страна А–Я'),
        ('establishedYear', false, 'Год по убыванию'),
      ],
      columns: [
        DirectoryColumn(label: 'Название', sortField: 'name', text: (item) => item.name),
        DirectoryColumn(label: 'Страна', sortField: 'country', text: (item) => item.country),
        DirectoryColumn(
          label: 'Год',
          sortField: 'establishedYear',
          numeric: true,
          text: (item) => '${item.establishedYear}',
        ),
      ],
      filters: (context, item, narrow, go) {
        final width = MediaQuery.sizeOf(context).width;
        const countries = [
          'Великобритания',
          'Германия',
          'Греция',
          'Россия',
          'США',
          'Таиланд',
          'Франция',
          'Япония',
        ];
        return [
          SizedBox(
            width: narrow ? width : 200,
            child: FilterDropdown<String>(
              label: 'Страна',
              value: item.country,
              items: [
                const DropdownMenuItem(value: null, child: Text('Все страны')),
                for (final country in countries) DropdownMenuItem(value: country, child: Text(country)),
              ],
              onChanged: (value) => go(item.copyWith(country: value)),
            ),
          ),
          yearBox(
            narrow: narrow,
            width: width,
            label: 'Год от',
            value: item.yearFrom?.toString() ?? '',
            onDebounced: (value) => go(item.copyWith(yearFrom: _year(value))),
          ),
          yearBox(
            narrow: narrow,
            width: width,
            label: 'Год до',
            value: item.yearTo?.toString() ?? '',
            onDebounced: (value) => go(item.copyWith(yearTo: _year(value))),
          ),
        ];
      },
    );
  }
}

class CustomerListScreen extends StatelessWidget {
  const CustomerListScreen({super.key, required this.query});

  final CustomerQuery query;

  @override
  Widget build(BuildContext context) {
    return DirectoryBrowser<Customer, CustomerQuery>(
      query: query,
      title: 'Клиенты',
      subtitle: 'Карта клиента редактируется в той же форме, отдельного экрана у неё нет.',
      basePath: '/customers',
      searchHint: 'Имя, почта или номер карты',
      emptyText: 'По этому запросу клиентов нет.',
      totalLabel: (total) => plural(total, 'клиент', 'клиента', 'клиентов'),
      remember: (memory, location) => memory.customers = location,
      emptyQuery: const CustomerQuery(),
      searchOf: (item) => item.search,
      deletedOf: (item) => item.includeDeleted,
      sortFieldOf: (item) => item.sortField,
      sortAscendingOf: (item) => item.sortAscending,
      sizeOf: (item) => item.size,
      withSearch: (item, value) => item.copyWith(search: value),
      withDeleted: (item, value) => item.copyWith(includeDeleted: value),
      withSort: (item, field, ascending) => item.copyWith(sortField: field, sortAscending: ascending),
      withPage: (item, page, size) => item.copyWith(page: page, size: size),
      idOf: (item) => item.id,
      nameOf: (item) => item.fullName,
      isDeleted: (item) => item.isDeleted,
      deletedAt: (item) => item.deletedAt,
      cardText: (item) => '${item.email} · ${item.city}',
      linksOf: (_) async => 0,
      sortCaption: (item) {
        final field = switch (item.sortField) {
          'email' => 'почта',
          'birthYear' => 'год рождения',
          _ => 'имя',
        };
        return '$field, ${item.sortAscending ? 'по возрастанию' : 'по убыванию'}';
      },
      sortOptions: const [
        ('fullName', true, 'Имя А–Я'),
        ('email', true, 'Почта А–Я'),
        ('birthYear', false, 'Год рождения'),
      ],
      columns: [
        DirectoryColumn(label: 'Имя', sortField: 'fullName', text: (item) => item.fullName),
        DirectoryColumn(label: 'Почта', sortField: 'email', text: (item) => item.email, width: 220),
        DirectoryColumn(label: 'Город', text: (item) => item.city),
        DirectoryColumn(
          label: 'Год',
          sortField: 'birthYear',
          numeric: true,
          text: (item) => '${item.birthYear}',
        ),
      ],
      filters: (context, item, narrow, go) {
        final width = MediaQuery.sizeOf(context).width;
        return [
          SizedBox(
            width: narrow ? width : 180,
            child: FilterDropdown<String>(
              label: 'Город',
              value: item.city,
              items: [
                const DropdownMenuItem(value: null, child: Text('Все города')),
                for (final city in const [
                  'Москва',
                  'Санкт-Петербург',
                  'Казань',
                  'Екатеринбург',
                  'Новосибирск',
                  'Краснодар',
                ])
                  DropdownMenuItem(value: city, child: Text(city)),
              ],
              onChanged: (value) => go(item.copyWith(city: value)),
            ),
          ),
          SizedBox(
            width: narrow ? width : 180,
            child: FilterDropdown<bool>(
              label: 'Карта',
              value: item.cardActive,
              items: const [
                DropdownMenuItem(value: null, child: Text('Любая')),
                DropdownMenuItem(value: true, child: Text('Активна')),
                DropdownMenuItem(value: false, child: Text('Заблокирована')),
              ],
              onChanged: (value) => go(item.copyWith(cardActive: value)),
            ),
          ),
          yearBox(
            narrow: narrow,
            width: width,
            label: 'Родился от',
            value: item.yearFrom?.toString() ?? '',
            onDebounced: (value) => go(item.copyWith(yearFrom: _year(value))),
          ),
          yearBox(
            narrow: narrow,
            width: width,
            label: 'Родился до',
            value: item.yearTo?.toString() ?? '',
            onDebounced: (value) => go(item.copyWith(yearTo: _year(value))),
          ),
        ];
      },
    );
  }
}

int? _year(String raw) {
  if (raw.trim().isEmpty) return null;
  return int.tryParse(raw.trim());
}

class RecordDetailsPage extends StatefulWidget {
  const RecordDetailsPage({
    super.key,
    required this.id,
    required this.back,
    required this.load,
    required this.editPath,
    required this.onSoft,
    required this.onRestore,
    required this.onHard,
    required this.onReloadList,
    required this.linksOf,
  });

  final int id;
  final String back;
  final String editPath;
  final Future<RecordView?> Function(int id) load;
  final Future<void> Function(int id) onSoft;
  final Future<void> Function(int id) onRestore;
  final Future<void> Function(int id) onHard;
  final Future<void> Function() onReloadList;
  final Future<int> Function(int id) linksOf;

  @override
  State<RecordDetailsPage> createState() => _RecordDetailsPageState();
}

class RecordView {
  const RecordView({
    required this.title,
    required this.lines,
    required this.deleted,
    this.deletedAt,
  });

  final String title;
  final List<(String, String)> lines;
  final bool deleted;
  final DateTime? deletedAt;
}

class _RecordDetailsPageState extends State<RecordDetailsPage> {
  RecordView? _record;
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RecordDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) _load();
  }

  Future<void> _load() async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
      _gone = false;
    });
    try {
      final record = await widget.load(widget.id);
      if (!mounted) return;
      if (record == null) {
        setState(() {
          _record = null;
          _error = 'Запись с номером ${widget.id} не найдена.';
          _status = LoadStatus.error;
        });
        return;
      }
      setState(() {
        _record = record;
        _status = LoadStatus.success;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось открыть карточку: $error';
        _status = LoadStatus.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;
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
                onPressed: () => context.go(widget.back),
                icon: const Icon(Icons.arrow_back),
                label: const Text('К списку'),
              ),
            ),
            const SizedBox(height: 16),
            if (_status == LoadStatus.loading || _status == LoadStatus.idle)
              const SizedBox(height: 280, child: LoadingView(message: 'Открываем карточку…'))
            else if (_status == LoadStatus.error)
              ErrorView(message: _error ?? 'Неизвестная ошибка', onRetry: _load)
            else if (_gone)
              const EmptyView(
                title: 'Запись удалена навсегда',
                message: 'Вернуть её нельзя.',
              )
            else if (record != null)
              _card(context, record),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, RecordView record) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record.deleted) ...[
              const DeletedBadge(),
              if (record.deletedAt != null) Text('Скрыт ${formatDateTime(record.deletedAt!)}'),
              const SizedBox(height: 12),
            ],
            Text(record.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            for (final line in record.lines) DetailLine(label: line.$1, value: line.$2),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => context.go(widget.editPath),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Изменить'),
                ),
                if (!record.deleted)
                  OutlinedButton.icon(
                    onPressed: () => _mutate(soft: true, name: record.title),
                    icon: const Icon(Icons.visibility_off_outlined),
                    label: const Text('Скрыть'),
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      await widget.onRestore(widget.id);
                      if (mounted) {
                        await widget.onReloadList();
                        await _load();
                      }
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Восстановить'),
                  ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                  onPressed: () => _mutate(soft: false, name: record.title),
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

  Future<void> _mutate({required bool soft, required String name}) async {
    final count = await widget.linksOf(widget.id);
    final blocked = linkedDeleteMessage(name, count);
    if (blocked != null) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Удаление невозможно'),
          content: Text(blocked),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Понятно')),
          ],
        ),
      );
      return;
    }
    if (!mounted) return;
    final ok = await confirmAction(
      context,
      title: soft ? 'Скрыть запись' : 'Удалить навсегда',
      message: soft ? 'Скрыть «$name»?' : 'Стереть «$name» без восстановления?',
      confirmLabel: soft ? 'Скрыть' : 'Удалить',
      danger: !soft,
    );
    if (!ok || !mounted) return;
    if (soft) {
      await widget.onSoft(widget.id);
      if (mounted) {
        await widget.onReloadList();
        await _load();
      }
      return;
    }
    await widget.onHard(widget.id);
    if (!mounted) return;
    await widget.onReloadList();
    setState(() => _gone = true);
  }
}
