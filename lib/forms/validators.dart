final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final skuPattern = RegExp(r'^[A-Za-zА-Яа-яЁё0-9][A-Za-zА-Яа-яЁё0-9\-]{3,31}$');
final phonePattern = RegExp(r'^\+7\d{10}$');
final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

String? requiredText(String? value, {String message = 'Заполните поле'}) {
  if (value == null || value.trim().isEmpty) return message;
  return null;
}

String? lengthBetween(String? value, int min, int max) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  if (text.length < min) return 'Минимум $min символа';
  if (text.length > max) return 'Максимум $max символов';
  return null;
}

String? matches(String? value, RegExp pattern, String message) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  if (!pattern.hasMatch(text)) return message;
  return null;
}

String? emailText(String? value) {
  return requiredText(value, message: 'Укажите почту') ??
      matches(value, emailPattern, 'Почта вида name@mail.ru');
}

String? phoneText(String? value) {
  final raw = value?.replaceAll(RegExp(r'[\s\-()]'), '') ?? '';
  return requiredText(value, message: 'Укажите телефон') ??
      matches(raw, phonePattern, 'Телефон в формате +7 и 10 цифр');
}

String? skuText(String? value) {
  return requiredText(value, message: 'Укажите артикул') ??
      matches(value, skuPattern, '4–32 символа: буквы, цифры и дефис');
}

String? intInRange(
  String? value, {
  required int min,
  required int max,
  bool positive = false,
  String empty = 'Заполните поле',
}) {
  final missing = requiredText(value, message: empty);
  if (missing != null) return missing;
  final number = int.tryParse(value!.trim());
  if (number == null) return 'Введите целое число';
  if (positive && number <= 0) return 'Число должно быть больше нуля';
  if (number < min || number > max) return 'Допустимо от $min до $max';
  return null;
}

String? calendarDate(String? value, {bool notInFuture = true}) {
  final missing = requiredText(value, message: 'Укажите дату');
  if (missing != null) return missing;
  final text = value!.trim();
  if (!datePattern.hasMatch(text)) return 'Дата в формате ГГГГ-ММ-ДД';
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return 'Такой даты нет';
  final normalized =
      '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  if (normalized != text) return 'Такой даты нет';
  if (notInFuture) {
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day);
    if (parsed.isAfter(end)) return 'Дата не может быть в будущем';
  }
  return null;
}

String? uniqueValue(String? value, Iterable<String> taken, String message) {
  final text = value?.trim().toLowerCase() ?? '';
  if (text.isEmpty) return null;
  if (taken.any((item) => item.trim().toLowerCase() == text)) return message;
  return null;
}

String? requiredIds(List<int>? value, String message) {
  if (value == null || value.isEmpty) return message;
  return null;
}

String normalizePhone(String value) => value.replaceAll(RegExp(r'[\s\-()]'), '');

String? linkedDeleteMessage(String name, int count) {
  if (count <= 0) return null;
  final mod10 = count.abs() % 10;
  final mod100 = count.abs() % 100;
  final word = mod10 == 1 && mod100 != 11
      ? 'товар'
      : (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14))
          ? 'товара'
          : 'товаров';
  return 'Нельзя удалить «$name»: с записью связано $count $word. '
      'Сначала измените или удалите эти товары.';
}
