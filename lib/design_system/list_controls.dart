import 'package:cupertino_ui/cupertino_ui.dart' as c;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as m;

import 'app_root.dart';
import 'theme.dart';
import 'tokens.dart';

enum AppSymbol {
  add(c.CupertinoIcons.add, m.Icons.add),
  search(c.CupertinoIcons.search, m.Icons.search),
  more(c.CupertinoIcons.ellipsis, m.Icons.more_horiz),
  sort(c.CupertinoIcons.sort_down, m.Icons.sort),
  clear(c.CupertinoIcons.clear_circled_solid, m.Icons.cancel_outlined);

  const AppSymbol(this.ios, this.material);
  final IconData ios;
  final IconData material;
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.symbol,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final AppSymbol symbol;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (usesCupertino(context)) {
      return Semantics(
        label: label,
        child: c.CupertinoButton(
          onPressed: onPressed,
          minimumSize: const Size.square(AppTokens.iosTarget),
          padding: EdgeInsets.zero,
          borderRadius: const BorderRadius.all(
            Radius.circular(AppTokens.iosTarget),
          ),
          color: filled ? AppColors.primary(context) : null,
          child: Icon(
            symbol.ios,
            size: symbol == AppSymbol.more ? AppTokens.controlIcon : null,
            color: filled && onPressed != null
                ? c.CupertinoColors.white
                : symbol == AppSymbol.more
                ? AppColors.muted(context)
                : null,
          ),
        ),
      );
    }
    return filled
        ? m.IconButton.filled(
            tooltip: label,
            onPressed: onPressed,
            icon: Icon(symbol.material),
          )
        : m.IconButton(
            tooltip: label,
            onPressed: onPressed,
            icon: Icon(symbol.material),
          );
  }
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onCancel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    const label = 'Поиск по названию';
    final ios = usesCupertino(context);
    final hasText = controller.text.isNotEmpty;
    final clearButton = AppIconButton(
      symbol: AppSymbol.clear,
      label: 'Очистить поиск',
      onPressed: () {
        controller.clear();
        onChanged('');
      },
    );
    return Row(
      children: [
        Expanded(
          child: Semantics(
            identifier: 'task-search',
            child: ios
                ? c.CupertinoSearchTextField(
                    controller: controller,
                    focusNode: focusNode,
                    placeholder: label,
                    placeholderStyle: AppTextStyles.body(context)
                        .copyWith(color: AppColors.muted(context)),
                    itemColor: AppColors.muted(context),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppTokens.space8,
                      AppTokens.space12,
                      AppTokens.space8,
                      AppTokens.space12,
                    ),
                    suffixMode: c.OverlayVisibilityMode.never,
                    onChanged: onChanged,
                    onSubmitted: (_) => focusNode.unfocus(),
                  )
                : m.TextField(
                    controller: controller,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.search,
                    onChanged: onChanged,
                    onSubmitted: (_) => focusNode.unfocus(),
                    decoration: m.InputDecoration(
                      hintText: label,
                      filled: true,
                      fillColor: AppColors.surface(context),
                      border: const m.OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(
                          Radius.circular(AppTokens.radius),
                        ),
                      ),
                      prefixIcon: const Icon(m.Icons.search),
                      suffixIcon: hasText ? clearButton : null,
                    ),
                  ),
          ),
        ),
        if (ios && hasText) clearButton,
        if (focusNode.hasFocus || hasText) ...[
          const SizedBox(width: AppTokens.space4),
          if (ios)
            c.CupertinoButton(
              onPressed: onCancel,
              padding: EdgeInsets.zero,
              child: const Text('Отмена'),
            )
          else
            m.TextButton(onPressed: onCancel, child: const Text('Отмена')),
        ],
      ],
    );
  }
}

class AppChoice<T> {
  const AppChoice(
    this.value,
    this.label, {
    this.selected = false,
    this.destructive = false,
  });
  final T value;
  final String label;
  final bool selected;
  final bool destructive;
}

class AppChoiceMenu<T> extends StatelessWidget {
  const AppChoiceMenu({
    super.key,
    required this.label,
    required this.choices,
    required this.onSelected,
    this.symbol,
  });

  final String label;
  final List<AppChoice<T>> choices;
  final ValueChanged<T> onSelected;
  final AppSymbol? symbol;

  Widget _label(BuildContext context, AppChoice<T> choice) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (choices.any((item) => item.selected)) ...[
        SizedBox(
          width: AppTokens.controlIcon,
          child: choice.selected
              ? Icon(
                  usesCupertino(context)
                      ? c.CupertinoIcons.check_mark
                      : m.Icons.check,
                  size: AppTokens.controlIcon,
                )
              : null,
        ),
        const SizedBox(width: AppTokens.space8),
      ],
      Flexible(
        child: Text(
          choice.label,
          style: choice.destructive && !usesCupertino(context)
              ? TextStyle(color: AppColors.error(context))
              : null,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final ios = usesCupertino(context);
    final icon = symbol;
    final iconOnly = icon == AppSymbol.more;
    if (ios) {
      Future<void> open() async {
        final value = await c.showCupertinoModalPopup<T>(
          context: context,
          semanticsDismissible: true,
          builder: (context) => c.CupertinoActionSheet(
            title: Text(label),
            actions: [
              for (final choice in choices)
                c.CupertinoActionSheetAction(
                  isDestructiveAction: choice.destructive,
                  onPressed: () => Navigator.pop(context, choice.value),
                  child: _label(context, choice),
                ),
            ],
            cancelButton: c.CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
          ),
        );
        if (context.mounted && value != null) onSelected(value);
      }

      if (iconOnly) {
        return AppIconButton(symbol: icon!, label: label, onPressed: open);
      }
      return c.CupertinoButton(
        onPressed: open,
        minimumSize: const Size.square(AppTokens.iosTarget),
        padding: EdgeInsets.zero,
        child: _trigger(context, ios: true),
      );
    }
    return m.PopupMenuButton<T>(
      tooltip: label,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final choice in choices)
          m.PopupMenuItem(value: choice.value, child: _label(context, choice)),
      ],
      icon: iconOnly
          ? Icon(icon!.material, color: AppColors.muted(context))
          : null,
      child: iconOnly
          ? null
          : ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppTokens.materialTarget,
              ),
              child: Center(
                widthFactor: 1,
                child: _trigger(context, ios: false),
              ),
            ),
    );
  }

  Widget _trigger(BuildContext context, {required bool ios}) => Text.rich(
    TextSpan(
      children: [
        if (symbol case final icon?)
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: AppTokens.space8),
              child: Icon(
                ios ? icon.ios : icon.material,
                color: AppColors.primary(context),
                size: AppTokens.controlIcon,
              ),
            ),
          ),
        TextSpan(text: label),
        if (symbol == null)
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              ios ? c.CupertinoIcons.chevron_down : m.Icons.arrow_drop_down,
              color: AppColors.primary(context),
              size: AppTokens.controlIcon,
            ),
          ),
      ],
    ),
    style: AppTextStyles.section(context)
        .copyWith(color: AppColors.primary(context)),
  );
}

class AppSegments<T extends Object> extends StatelessWidget {
  const AppSegments({
    super.key,
    required this.choices,
    required this.value,
    required this.onChanged,
    required this.fallbackLabel,
  });

  final Map<T, String> choices;
  final T value;
  final ValueChanged<T> onChanged;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final ios = usesCupertino(context);
      final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
      if (constraints.maxWidth < AppTokens.segmentedMinWidth * scale) {
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppChoiceMenu(
            label: '$fallbackLabel: ${choices[value]}',
            choices: [
              for (final entry in choices.entries)
                AppChoice(entry.key, entry.value, selected: entry.key == value),
            ],
            onSelected: onChanged,
          ),
        );
      }
      if (ios) {
        return c.CupertinoSlidingSegmentedControl<T>(
          groupValue: value,
          onValueChanged: (next) {
            if (next != null) onChanged(next);
          },
          children: {
            for (final entry in choices.entries)
              entry.key: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppTokens.iosTarget,
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    entry.value,
                    style: AppTextStyles.section(context),
                  ),
                ),
              ),
          },
        );
      }
      return m.SegmentedButton<T>(
        showSelectedIcon: false,
        style: const m.ButtonStyle(
          visualDensity: m.VisualDensity.standard,
          minimumSize: WidgetStatePropertyAll(
            Size(0, AppTokens.materialTarget),
          ),
        ),
        segments: [
          for (final entry in choices.entries)
            m.ButtonSegment(value: entry.key, label: Text(entry.value)),
        ],
        selected: {value},
        onSelectionChanged: (next) => onChanged(next.single),
      );
    },
  );
}

class AppCompletionButton extends StatelessWidget {
  const AppCompletionButton({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    void toggle() => onChanged(!value);

    if (usesCupertino(context)) {
      return Semantics(
        label: label,
        checked: value,
        enabled: true,
        onTap: toggle,
        excludeSemantics: true,
        child: c.CupertinoButton(
          onPressed: toggle,
          minimumSize: const Size.square(AppTokens.iosTarget),
          padding: EdgeInsets.zero,
          child: Icon(
            value
                ? c.CupertinoIcons.check_mark_circled_solid
                : c.CupertinoIcons.circle,
            color: value
                ? AppColors.primary(context)
                : AppColors.muted(context),
            size: AppTokens.completionIcon,
          ),
        ),
      );
    }
    return Semantics(
      label: label,
      child: SizedBox.square(
        dimension: AppTokens.materialTarget,
        child: m.Checkbox(
          value: value,
          onChanged: (_) => toggle(),
          shape: const CircleBorder(),
          visualDensity: m.VisualDensity.standard,
        ),
      ),
    );
  }
}

ScrollPhysics? appListPhysics(BuildContext context) => usesCupertino(context)
    ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
    : null;
