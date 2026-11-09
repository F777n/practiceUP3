import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../widgets/confirm_dialog.dart';
import 'field_spec.dart';
import 'form_guard.dart';

class EntityForm extends StatefulWidget {
  const EntityForm({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.fields,
    required this.initial,
    required this.fallback,
    required this.onChanged,
    required this.onSubmit,
  });

  final String title;
  final String submitLabel;
  final List<FieldSpec> fields;
  final Map<String, Object?> initial;
  final String fallback;
  final void Function(String id, Object? value) onChanged;
  final Future<void> Function(Map<String, Object?> values) onSubmit;

  @override
  State<EntityForm> createState() => _EntityFormState();
}

class _EntityFormState extends State<EntityForm> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  AutovalidateMode _mode = AutovalidateMode.disabled;
  bool _leave = false;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      if (field is TextFieldSpec) {
        final controller = TextEditingController(text: field.initialValue);
        controller.addListener(_onText);
        _controllers[field.id] = controller;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FormGuard>().reset();
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.removeListener(_onText);
      controller.dispose();
    }
    super.dispose();
  }

  void _onText() => _publishDirty();

  Map<String, String> _texts() {
    return {
      for (final entry in _controllers.entries) entry.key: entry.value.text,
    };
  }

  bool _computeDirty() {
    for (final entry in _controllers.entries) {
      final initial = widget.initial[entry.key];
      if (entry.value.text != (initial is String ? initial : '')) return true;
    }
    for (final field in widget.fields) {
      if (field is IntChoiceSpec && field.value != widget.initial[field.id]) return true;
      if (field is StringChoiceSpec && field.value != widget.initial[field.id]) return true;
      if (field is BoolSpec && field.value != (widget.initial[field.id] as bool? ?? false)) {
        return true;
      }
      if (field is MultiSpec) {
        final initial = _idList(widget.initial[field.id]);
        if (!_sameIds(field.values, initial)) return true;
      }
    }
    return false;
  }

  void _publishDirtyLater() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publishDirty();
    });
  }

  void _publishDirty() {
    final next = _computeDirty();
    if (next == _dirty) return;
    setState(() => _dirty = next);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FormGuard>().setDirty(_dirty);
    });
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      setState(() => _mode = AutovalidateMode.onUserInteraction);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSubmit(_collect());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Map<String, Object?> _collect() {
    final values = Map<String, Object?>.of(widget.initial);
    for (final entry in _controllers.entries) {
      values[entry.key] = entry.value.text.trim();
    }
    for (final field in widget.fields) {
      if (field is IntChoiceSpec) values[field.id] = field.value;
      if (field is StringChoiceSpec) values[field.id] = field.value;
      if (field is MultiSpec) values[field.id] = List<int>.of(field.values);
      if (field is BoolSpec) values[field.id] = field.value;
    }
    return values;
  }

  Future<void> _askLeave() async {
    final ok = await confirmAction(
      context,
      title: 'Есть несохранённые изменения',
      message: 'Уйти со страницы? Введённые данные не сохранятся.',
      confirmLabel: 'Уйти',
      danger: true,
    );
    if (!ok || !mounted) return;
    context.read<FormGuard>().allowProgrammaticLeave();
    setState(() => _leave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(widget.fallback);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final guard = context.watch<FormGuard>();
    final canPop = _leave || guard.force || !_dirty;
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _leave || guard.force) return;
        _askLeave();
      },
      child: Form(
        key: _formKey,
        autovalidateMode: _mode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Назад'),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            for (final field in widget.fields) ...[
              _buildField(field),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(widget.submitLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(FieldSpec field) {
    if (field is SectionSpec) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.title, style: Theme.of(context).textTheme.titleMedium),
            if (field.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                field.subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      );
    }
    if (field is TextFieldSpec) {
      return TextFormField(
        controller: _controllers[field.id],
        keyboardType: field.keyboardType,
        maxLines: field.maxLines,
        style: field.style,
        inputFormatters: field.formatters.isNotEmpty
            ? field.formatters
            : digitFormatters(field.digitsOnly),
        decoration: InputDecoration(labelText: field.label, hintText: field.hint),
        validator: (value) => field.validator(value, _texts()),
      );
    }
    if (field is IntChoiceSpec) return _intChoice(field);
    if (field is StringChoiceSpec) return _stringChoice(field);
    if (field is MultiSpec) return _multi(field);
    if (field is BoolSpec) {
      return CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(field.label),
        value: field.value,
        onChanged: (value) {
          widget.onChanged(field.id, value ?? false);
          _publishDirtyLater();
        },
      );
    }
    return const SizedBox.shrink();
  }

  Widget _intChoice(IntChoiceSpec field) {
    final known = field.options.any((item) => item.value == field.value);
    return DropdownButtonFormField<int?>(
      key: ValueKey('${field.id}-${field.value}'),
      value: known ? field.value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: field.label),
      items: [
        DropdownMenuItem<int?>(value: null, child: Text(field.emptyLabel)),
        for (final option in field.options)
          DropdownMenuItem<int?>(value: option.value, child: Text(option.label)),
      ],
      onChanged: (value) {
        widget.onChanged(field.id, value);
        _publishDirtyLater();
      },
      validator: field.validator,
    );
  }

  Widget _stringChoice(StringChoiceSpec field) {
    final known = field.options.any((item) => item.value == field.value);
    return DropdownButtonFormField<String?>(
      key: ValueKey('${field.id}-${field.value}'),
      value: known ? field.value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: field.label),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text(field.emptyLabel)),
        for (final option in field.options)
          DropdownMenuItem<String?>(value: option.value, child: Text(option.label)),
      ],
      onChanged: (value) {
        widget.onChanged(field.id, value);
        _publishDirtyLater();
      },
      validator: field.validator,
    );
  }

  Widget _multi(MultiSpec field) {
    return FormField<List<int>>(
      key: ValueKey('${field.id}-${field.values.join(',')}'),
      initialValue: List<int>.of(field.values),
      validator: field.validator,
      builder: (state) {
        final selected = state.value ?? const <int>[];
        return InputDecorator(
          decoration: InputDecoration(
            labelText: field.label,
            errorText: state.errorText,
            helperText: field.options.isEmpty ? field.hint : null,
          ),
          child: field.options.isEmpty
              ? Text(field.hint ?? 'Нет значений')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in field.options)
                      FilterChip(
                        label: Text(option.label),
                        selected: selected.contains(option.value),
                        onSelected: (_) {
                          final next = List<int>.of(selected);
                          if (next.contains(option.value)) {
                            next.remove(option.value);
                          } else {
                            next.add(option.value);
                          }
                          state.didChange(next);
                          widget.onChanged(field.id, next);
                          _publishDirtyLater();
                        },
                      ),
                  ],
                ),
        );
      },
    );
  }
}

List<int> _idList(Object? value) {
  if (value is List<int>) return value;
  if (value is List) {
    return value.whereType<int>().toList();
  }
  return const [];
}

bool _sameIds(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  final a = [...left]..sort();
  final b = [...right]..sort();
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
