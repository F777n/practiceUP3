import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef TextRule = String? Function(String? value, Map<String, String> texts);

class FieldSpec {
  const FieldSpec(this.id);
  final String id;
}

class TextFieldSpec extends FieldSpec {
  const TextFieldSpec({
    required String id,
    required this.label,
    required this.initialValue,
    required this.validator,
    this.hint,
    this.keyboardType,
    this.digitsOnly = false,
    this.formatters = const [],
    this.maxLines = 1,
    this.style,
  }) : super(id);

  final String label;
  final String initialValue;
  final TextRule validator;
  final String? hint;
  final TextInputType? keyboardType;
  final bool digitsOnly;
  final List<TextInputFormatter> formatters;
  final int maxLines;
  final TextStyle? style;
}

class IntChoiceSpec extends FieldSpec {
  const IntChoiceSpec({
    required String id,
    required this.label,
    required this.value,
    required this.options,
    required this.validator,
    this.emptyLabel = 'Выберите',
  }) : super(id);

  final String label;
  final int? value;
  final List<ChoiceOption<int>> options;
  final String? Function(int? value) validator;
  final String emptyLabel;
}

class StringChoiceSpec extends FieldSpec {
  const StringChoiceSpec({
    required String id,
    required this.label,
    required this.value,
    required this.options,
    required this.validator,
    this.emptyLabel = 'Выберите',
  }) : super(id);

  final String label;
  final String? value;
  final List<ChoiceOption<String>> options;
  final String? Function(String? value) validator;
  final String emptyLabel;
}

class ChoiceOption<T> {
  const ChoiceOption(this.value, this.label);
  final T value;
  final String label;
}

class MultiSpec extends FieldSpec {
  const MultiSpec({
    required String id,
    required this.label,
    required this.values,
    required this.options,
    required this.validator,
    this.hint,
  }) : super(id);

  final String label;
  final List<int> values;
  final List<ChoiceOption<int>> options;
  final String? Function(List<int>? value) validator;
  final String? hint;
}

class BoolSpec extends FieldSpec {
  const BoolSpec({
    required String id,
    required this.label,
    required this.value,
  }) : super(id);

  final String label;
  final bool value;
}

class SectionSpec extends FieldSpec {
  const SectionSpec({
    required String id,
    required this.title,
    this.subtitle,
  }) : super(id);

  final String title;
  final String? subtitle;
}

List<TextInputFormatter> digitFormatters(bool digitsOnly) {
  if (!digitsOnly) return const [];
  return [FilteringTextInputFormatter.digitsOnly];
}

/// Телефон клиента: префикс «+7» нельзя стереть, дальше только 10 цифр.
class RuPhoneFormatter extends TextInputFormatter {
  const RuPhoneFormatter();

  static const prefix = '+7';

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final national = nationalDigits(newValue.text);
    final text = '$prefix$national';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: _offset(newValue, text.length)),
    );
  }

  static String nationalDigits(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('7')) digits = digits.substring(1);
    if (digits.length > 10) digits = digits.substring(0, 10);
    return digits;
  }

  static int _offset(TextEditingValue value, int length) {
    final end = value.selection.extentOffset.clamp(0, value.text.length);
    var digitsBefore = value.text.substring(0, end).replaceAll(RegExp(r'\D'), '').length;
    if (digitsBefore > 0) digitsBefore -= 1;
    final mapped = prefix.length + digitsBefore;
    if (mapped < prefix.length) return prefix.length;
    if (mapped > length) return length;
    return mapped;
  }
}
