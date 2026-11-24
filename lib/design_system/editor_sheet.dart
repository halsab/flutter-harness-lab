import 'package:cupertino_ui/cupertino_ui.dart' as c;
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as m;

import 'app_root.dart';
import 'components.dart';
import 'theme.dart';
import 'tokens.dart';

Future<bool?> showTitleEditor(
  BuildContext context, {
  required String title,
  required String initialValue,
  required String confirmLabel,
  required Future<bool> Function(String) onSave,
}) {
  Widget builder(BuildContext context) => _TitleEditor(
    title: title,
    initialValue: initialValue,
    confirmLabel: confirmLabel,
    onSave: onSave,
  );

  return usesCupertino(context)
      ? c.showCupertinoModalPopup<bool>(
          context: context,
          barrierDismissible: false,
          builder: builder,
        )
      : m.showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          useSafeArea: true,
          backgroundColor: m.Colors.transparent,
          builder: builder,
        );
}

class _TitleEditor extends StatefulWidget {
  const _TitleEditor({
    required this.title,
    required this.initialValue,
    required this.confirmLabel,
    required this.onSave,
  });

  final String title;
  final String initialValue;
  final String confirmLabel;
  final Future<bool> Function(String) onSave;

  @override
  State<_TitleEditor> createState() => _TitleEditorState();
}

class _TitleEditorState extends State<_TitleEditor> {
  late final _controller = TextEditingController(text: widget.initialValue);
  var _saving = false;
  var _failed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    final saved = await widget.onSave(title);
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AnimatedPadding(
      duration: AppTokens.disclosureDuration,
      padding: MediaQuery.viewInsetsOf(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTokens.editorWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTokens.groupRadius),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: AppTokens.pagePadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.title, style: AppTextStyles.heading(context)),
                  const SizedBox(height: AppTokens.space12),
                  Semantics(
                    identifier: 'task-input',
                    child: AppTextField(
                      label: 'Название задачи',
                      controller: _controller,
                      autofocus: true,
                      enabled: !_saving,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  if (_failed)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTokens.space8),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          'Не удалось сохранить задачи',
                          style: AppTextStyles.body(context)
                              .copyWith(color: AppColors.error(context)),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppTokens.space8),
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppTokens.space8,
                    children: [
                      if (_saving) const AppProgress(),
                      AppButton(
                        label: 'Отмена',
                        primary: false,
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                      ),
                      AppButton(
                        label: widget.confirmLabel,
                        onPressed: _saving || _controller.text.trim().isEmpty
                            ? null
                            : _submit,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
