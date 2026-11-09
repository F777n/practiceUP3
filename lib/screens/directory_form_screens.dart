import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../forms/field_spec.dart';
import '../forms/spec_form_screen.dart';
import '../forms/validators.dart';
import '../models/category.dart';
import '../models/category_query.dart';
import '../models/customer.dart';
import '../models/customer_query.dart';
import '../models/discipline.dart';
import '../models/discipline_query.dart';
import '../navigation.dart';
import '../repositories/directory_repositories.dart';
import '../state/simple_list_notifier.dart';

class CategoryFormScreen extends StatelessWidget {
  const CategoryFormScreen({super.key, this.id});

  final int? id;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<CategoryRepository>();
    return SpecFormScreen(
      fallback: context.read<ListLocationMemory>().categories,
      locationFor: (savedId) => '/categories/$savedId',
      onSaved: () => context.read<SimpleListNotifier<Category, CategoryQuery>>().load(),
      load: () => _loadCategory(repository),
      save: (values) => _saveCategory(repository, values),
    );
  }

  Future<FormBlueprint> _loadCategory(CategoryRepository repository) async {
    final category = id == null ? null : await repository.findById(id!);
    if (id != null && category == null) throw StateError('Категория с номером $id не найдена.');
    final taken = (await repository.all())
        .where((item) => item.id != id)
        .map((item) => item.code)
        .toList();
    return FormBlueprint(
      title: id == null ? 'Новая категория' : 'Изменение категории',
      submitLabel: id == null ? 'Создать' : 'Сохранить',
      values: {
        'name': category?.name ?? '',
        'code': category?.code ?? '',
        'description': category?.description ?? '',
        'kind': category?.kind,
        'introducedYear': category == null ? '' : '${category.introducedYear}',
      },
      fields: (values) => [
        TextFieldSpec(
          id: 'name',
          label: 'Название',
          initialValue: textValue(values, 'name'),
          validator: (value, _) =>
              requiredText(value, message: 'Укажите название') ?? lengthBetween(value, 2, 40),
        ),
        TextFieldSpec(
          id: 'code',
          label: 'Код',
          hint: 'GLV',
          initialValue: textValue(values, 'code'),
          validator: (value, _) =>
              (requiredText(value, message: 'Укажите код') ?? lengthBetween(value, 2, 12)) ??
              uniqueValue(value, taken, 'Такой код уже есть'),
        ),
        StringChoiceSpec(
          id: 'kind',
          label: 'Группа',
          value: stringValue(values, 'kind'),
          options: [for (final kind in categoryKinds) ChoiceOption(kind, kind)],
          validator: (value) => value == null ? 'Выберите группу' : null,
        ),
        TextFieldSpec(
          id: 'introducedYear',
          label: 'Год появления',
          initialValue: textValue(values, 'introducedYear'),
          digitsOnly: true,
          keyboardType: TextInputType.number,
          validator: (value, _) => intInRange(value, min: 1800, max: 2026, empty: 'Укажите год'),
        ),
        TextFieldSpec(
          id: 'description',
          label: 'Описание',
          initialValue: textValue(values, 'description'),
          maxLines: 3,
          validator: (value, _) =>
              requiredText(value, message: 'Добавьте описание') ?? lengthBetween(value, 10, 300),
        ),
      ],
    );
  }

  Future<int> _saveCategory(CategoryRepository repository, Map<String, Object?> values) async {
    final draft = Category(
      id: id ?? 0,
      name: textValue(values, 'name'),
      code: textValue(values, 'code'),
      description: textValue(values, 'description'),
      kind: stringValue(values, 'kind') ?? '',
      introducedYear: int.parse(textValue(values, 'introducedYear')),
    );
    if (await repository.isCodeTaken(draft.code, exceptId: id)) {
      throw StateError('Такой код уже есть.');
    }
    if (id == null) return (await repository.create(draft)).id;
    final current = await repository.findById(id!);
    if (current == null) throw StateError('Категория уже удалена.');
    return (await repository.update(
      Category(
        id: current.id,
        name: draft.name,
        code: draft.code,
        description: draft.description,
        kind: draft.kind,
        introducedYear: draft.introducedYear,
        deletedAt: current.deletedAt,
      ),
    ))
        .id;
  }
}

class DisciplineFormScreen extends StatelessWidget {
  const DisciplineFormScreen({super.key, this.id});

  final int? id;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<DisciplineRepository>();
    return SpecFormScreen(
      fallback: context.read<ListLocationMemory>().disciplines,
      locationFor: (savedId) => '/disciplines/$savedId',
      onSaved: () => context.read<SimpleListNotifier<Discipline, DisciplineQuery>>().load(),
      load: () => _load(repository),
      save: (values) => _save(repository, values),
    );
  }

  Future<FormBlueprint> _load(DisciplineRepository repository) async {
    final discipline = id == null ? null : await repository.findById(id!);
    if (id != null && discipline == null) {
      throw StateError('Дисциплина с номером $id не найдена.');
    }
    final countries = {...brandCountries, 'Великобритания', 'Греция'}.toList()..sort();
    return FormBlueprint(
      title: id == null ? 'Новая дисциплина' : 'Изменение дисциплины',
      submitLabel: id == null ? 'Создать' : 'Сохранить',
      values: {
        'name': discipline?.name ?? '',
        'country': discipline?.country,
        'establishedYear': discipline == null ? '' : '${discipline.establishedYear}',
        'summary': discipline?.summary ?? '',
      },
      fields: (values) => [
        TextFieldSpec(
          id: 'name',
          label: 'Название',
          initialValue: textValue(values, 'name'),
          validator: (value, _) =>
              requiredText(value, message: 'Укажите название') ?? lengthBetween(value, 2, 40),
        ),
        StringChoiceSpec(
          id: 'country',
          label: 'Страна',
          value: stringValue(values, 'country'),
          options: [for (final country in countries) ChoiceOption(country, country)],
          validator: (value) => value == null ? 'Выберите страну' : null,
        ),
        TextFieldSpec(
          id: 'establishedYear',
          label: 'Год оформления правил',
          initialValue: textValue(values, 'establishedYear'),
          digitsOnly: true,
          keyboardType: TextInputType.number,
          validator: (value, _) => intInRange(value, min: 1800, max: 2026, empty: 'Укажите год'),
        ),
        TextFieldSpec(
          id: 'summary',
          label: 'Описание',
          initialValue: textValue(values, 'summary'),
          maxLines: 3,
          validator: (value, _) =>
              requiredText(value, message: 'Добавьте описание') ?? lengthBetween(value, 10, 300),
        ),
      ],
    );
  }

  Future<int> _save(DisciplineRepository repository, Map<String, Object?> values) async {
    final draft = Discipline(
      id: id ?? 0,
      name: textValue(values, 'name'),
      country: stringValue(values, 'country') ?? '',
      establishedYear: int.parse(textValue(values, 'establishedYear')),
      summary: textValue(values, 'summary'),
    );
    if (id == null) return (await repository.create(draft)).id;
    final current = await repository.findById(id!);
    if (current == null) throw StateError('Дисциплина уже удалена.');
    return (await repository.update(
      Discipline(
        id: current.id,
        name: draft.name,
        country: draft.country,
        establishedYear: draft.establishedYear,
        summary: draft.summary,
        deletedAt: current.deletedAt,
      ),
    ))
        .id;
  }
}

class CustomerFormScreen extends StatelessWidget {
  const CustomerFormScreen({super.key, this.id});

  final int? id;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<CustomerRepository>();
    return SpecFormScreen(
      fallback: context.read<ListLocationMemory>().customers,
      locationFor: (savedId) => '/customers/$savedId',
      onSaved: () => context.read<SimpleListNotifier<Customer, CustomerQuery>>().load(),
      load: () => _load(repository),
      save: (values) => _save(repository, values),
    );
  }

  Future<FormBlueprint> _load(CustomerRepository repository) async {
    final customer = id == null ? null : await repository.findById(id!);
    if (id != null && customer == null) throw StateError('Клиент с номером $id не найден.');
    final taken = (await repository.all())
        .where((item) => item.id != id)
        .map((item) => item.email)
        .toList();
    return FormBlueprint(
      title: id == null ? 'Новый клиент' : 'Изменение клиента',
      submitLabel: id == null ? 'Создать' : 'Сохранить',
      values: {
        'fullName': customer?.fullName ?? '',
        'email': customer?.email ?? '',
        'phone': customer?.phone ?? '+7',
        'city': customer?.city ?? '',
        'birthYear': customer == null ? '' : '${customer.birthYear}',
        'cardNumber': customer?.card.number ?? '',
        'issuedOn': customer?.card.issuedOn ?? '',
        'discountPercent': customer == null ? '' : '${customer.card.discountPercent}',
        'cardActive': customer?.card.active ?? true,
      },
      fields: (values) => [
        TextFieldSpec(
          id: 'fullName',
          label: 'Имя',
          initialValue: textValue(values, 'fullName'),
          validator: (value, _) =>
              requiredText(value, message: 'Укажите имя') ?? lengthBetween(value, 2, 80),
        ),
        TextFieldSpec(
          id: 'email',
          label: 'Почта',
          initialValue: textValue(values, 'email'),
          keyboardType: TextInputType.emailAddress,
          validator: (value, _) =>
              emailText(value) ?? uniqueValue(value, taken, 'Такая почта уже есть'),
        ),
        TextFieldSpec(
          id: 'phone',
          label: 'Телефон',
          hint: '+79001110001',
          initialValue: textValue(values, 'phone'),
          keyboardType: TextInputType.phone,
          formatters: const [RuPhoneFormatter()],
          validator: (value, _) => phoneText(value),
        ),
        TextFieldSpec(
          id: 'city',
          label: 'Город',
          initialValue: textValue(values, 'city'),
          validator: (value, _) =>
              requiredText(value, message: 'Укажите город') ?? lengthBetween(value, 2, 40),
        ),
        TextFieldSpec(
          id: 'birthYear',
          label: 'Год рождения',
          initialValue: textValue(values, 'birthYear'),
          digitsOnly: true,
          keyboardType: TextInputType.number,
          validator: (value, _) => intInRange(value, min: 1940, max: 2012, empty: 'Укажите год'),
        ),
        const SectionSpec(
          id: 'cardSection',
          title: 'Карта клиента',
          subtitle: 'Один клиент — одна карта. Отдельного экрана у карты нет.',
        ),
        TextFieldSpec(
          id: 'cardNumber',
          label: 'Номер карты',
          initialValue: textValue(values, 'cardNumber'),
          digitsOnly: true,
          keyboardType: TextInputType.number,
          validator: (value, _) =>
              requiredText(value, message: 'Укажите номер') ?? lengthBetween(value, 6, 12),
        ),
        TextFieldSpec(
          id: 'issuedOn',
          label: 'Дата выдачи',
          hint: '2024-05-15',
          initialValue: textValue(values, 'issuedOn'),
          validator: (value, _) => calendarDate(value),
        ),
        TextFieldSpec(
          id: 'discountPercent',
          label: 'Скидка, %',
          initialValue: textValue(values, 'discountPercent'),
          digitsOnly: true,
          keyboardType: TextInputType.number,
          validator: (value, _) => intInRange(value, min: 0, max: 40, empty: 'Укажите скидку'),
        ),
        BoolSpec(
          id: 'cardActive',
          label: 'Карта активна',
          value: boolValue(values, 'cardActive', fallback: true),
        ),
      ],
    );
  }

  Future<int> _save(CustomerRepository repository, Map<String, Object?> values) async {
    final email = textValue(values, 'email');
    if (await repository.isEmailTaken(email, exceptId: id)) {
      throw StateError('Такая почта уже есть.');
    }
    final draft = Customer(
      id: id ?? 0,
      fullName: textValue(values, 'fullName'),
      email: email,
      phone: normalizePhone(textValue(values, 'phone')),
      city: textValue(values, 'city'),
      birthYear: int.parse(textValue(values, 'birthYear')),
      card: LoyaltyCard(
        number: textValue(values, 'cardNumber'),
        issuedOn: textValue(values, 'issuedOn'),
        discountPercent: int.parse(textValue(values, 'discountPercent')),
        active: boolValue(values, 'cardActive', fallback: true),
      ),
    );
    if (id == null) return (await repository.create(draft)).id;
    final current = await repository.findById(id!);
    if (current == null) throw StateError('Клиент уже удалён.');
    return (await repository.update(draft.copyWith(deletedAt: current.deletedAt))).id;
  }
}
