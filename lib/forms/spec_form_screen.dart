import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../widgets/status_views.dart';
import 'entity_form.dart';
import 'field_spec.dart';
import 'form_guard.dart';

class FormBlueprint {
  const FormBlueprint({
    required this.title,
    required this.submitLabel,
    required this.values,
    required this.fields,
  });

  final String title;
  final String submitLabel;
  final Map<String, Object?> values;
  final List<FieldSpec> Function(Map<String, Object?> values) fields;
}

class SpecFormScreen extends StatefulWidget {
  const SpecFormScreen({
    super.key,
    required this.load,
    required this.save,
    required this.fallback,
    required this.locationFor,
    this.onSaved,
    this.adjust,
  });

  final Future<FormBlueprint> Function() load;
  final Future<int> Function(Map<String, Object?> values) save;
  final String fallback;
  final String Function(int id) locationFor;
  final Future<void> Function()? onSaved;
  final void Function(Map<String, Object?> values, String id, Object? value)? adjust;

  @override
  State<SpecFormScreen> createState() => _SpecFormScreenState();
}

class _SpecFormScreenState extends State<SpecFormScreen> {
  FormBlueprint? _blueprint;
  Map<String, Object?> _values = {};
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final blueprint = await widget.load();
      if (!mounted) return;
      setState(() {
        _blueprint = blueprint;
        _values = Map<String, Object?>.of(blueprint.values);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  Future<void> _submit(Map<String, Object?> values) async {
    try {
      final id = await widget.save(values);
      if (!mounted) return;
      if (widget.onSaved != null) await widget.onSaved!();
      if (!mounted) return;
      context.read<FormGuard>().allowProgrammaticLeave();
      context.go(widget.locationFor(id));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_loading)
              const SizedBox(height: 320, child: LoadingView(message: 'Открываем форму…'))
            else if (_error != null)
              ErrorView(message: _error!, onRetry: _load)
            else
              EntityForm(
                title: _blueprint!.title,
                submitLabel: _blueprint!.submitLabel,
                fields: _blueprint!.fields(_values),
                initial: _blueprint!.values,
                fallback: widget.fallback,
                onChanged: (id, value) {
                  setState(() {
                    _values[id] = value;
                    widget.adjust?.call(_values, id, value);
                  });
                },
                onSubmit: _submit,
              ),
          ],
        ),
      ),
    );
  }
}

String textValue(Map<String, Object?> values, String key) {
  final value = values[key];
  return value is String ? value : '';
}

int? intValue(Map<String, Object?> values, String key) {
  final value = values[key];
  return value is int ? value : null;
}

String? stringValue(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value is String && value.isNotEmpty) return value;
  return null;
}

List<int> idValue(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value is List<int>) return value;
  if (value is List) return value.whereType<int>().toList();
  return const [];
}

bool boolValue(Map<String, Object?> values, String key, {bool fallback = false}) {
  final value = values[key];
  return value is bool ? value : fallback;
}
