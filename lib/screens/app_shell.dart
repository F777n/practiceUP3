import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../forms/form_guard.dart';
import '../storage/catalog_store.dart';
import '../theme.dart';
import '../widgets/confirm_dialog.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final index = _sectionIndex(path);
    final wide = MediaQuery.sizeOf(context).width >= kTableBreakpoint;
    final theme = context.watch<ThemeController>();
    final notice = context.watch<StorageNotice>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.sports_mma, color: scheme.onPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ринг'),
                  if (MediaQuery.sizeOf(context).width >= 720)
                    Text(
                      'Магазин боксёрских принадлежностей',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: theme.isDark ? 'Светлая тема' : 'Тёмная тема',
            onPressed: theme.toggle,
            icon: Icon(theme.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (notice.message != null)
            MaterialBanner(
              content: Text(notice.message!),
              actions: [
                TextButton(onPressed: notice.dismiss, child: const Text('Скрыть')),
              ],
            ),
          Expanded(
            child: wide
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: index,
                        onDestinationSelected: (value) => _openSection(context, value),
                        labelType: NavigationRailLabelType.all,
                        destinations: [
                          for (final section in _sections)
                            NavigationRailDestination(
                              icon: Icon(section.icon),
                              selectedIcon: Icon(section.selected),
                              label: Text(section.label),
                            ),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: child),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: child,
                  ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              height: 68,
              selectedIndex: index,
              onDestinationSelected: (value) => _openSection(context, value),
              destinations: [
                for (final section in _sections)
                  NavigationDestination(
                    icon: Icon(section.icon),
                    selectedIcon: Icon(section.selected),
                    label: section.short,
                  ),
              ],
            ),
    );
  }

  Future<void> _openSection(BuildContext context, int index) async {
    final guard = context.read<FormGuard>();
    if (guard.dirty) {
      final ok = await confirmAction(
        context,
        title: 'Есть несохранённые изменения',
        message: 'Уйти со страницы? Введённые данные не сохранятся.',
        confirmLabel: 'Уйти',
        danger: true,
      );
      if (!ok || !context.mounted) return;
      guard.allowProgrammaticLeave();
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!context.mounted) return;
    final path = GoRouterState.of(context).uri.path;
    final target = _sections[index].path;
    if (path != target) context.go(target);
  }
}

class _Section {
  const _Section(this.path, this.label, this.short, this.icon, this.selected);

  final String path;
  final String label;
  final String short;
  final IconData icon;
  final IconData selected;
}

const _sections = <_Section>[
  _Section('/products', 'Товары', 'Товары', Icons.inventory_2_outlined, Icons.inventory_2),
  _Section('/brands', 'Бренды', 'Бренды', Icons.workspace_premium_outlined, Icons.workspace_premium),
  _Section('/categories', 'Категории', 'Катег.', Icons.category_outlined, Icons.category),
  _Section('/disciplines', 'Дисциплины', 'Дисц.', Icons.sports_martial_arts_outlined, Icons.sports_martial_arts),
  _Section('/customers', 'Клиенты', 'Клиенты', Icons.badge_outlined, Icons.badge),
];

int _sectionIndex(String path) {
  for (var i = 0; i < _sections.length; i++) {
    if (path.startsWith(_sections[i].path)) return i;
  }
  return 0;
}
