import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../data/providers.dart';

/// Feuille de changement de mot de passe : mot de passe actuel + nouveau
/// (min. 8 caractères) + confirmation. Retourne true si le changement a réussi.
class ChangePasswordSheet extends ConsumerStatefulWidget {
  const ChangePasswordSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ChangePasswordSheet(),
    );
  }

  @override
  ConsumerState<ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  String? _apiError;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _apiError = null;
    });
    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() {
        _submitting = false;
        _apiError = e.statusCode == 401
            ? 'Mot de passe actuel incorrect'
            : e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      // Laisse la place au clavier.
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Changer mon mot de passe',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _current,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration:
                  const InputDecoration(labelText: 'Mot de passe actuel'),
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Saisissez votre mot de passe actuel'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _next,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration:
                  const InputDecoration(labelText: 'Nouveau mot de passe'),
              validator: (v) => (v == null || v.length < 8)
                  ? 'Minimum 8 caractères'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe'),
              validator: (v) => v != _next.text
                  ? 'Les mots de passe ne correspondent pas'
                  : null,
            ),
            if (_apiError != null) ...[
              const SizedBox(height: 12),
              Text(
                _apiError!,
                style: TextStyle(color: colors.destructive, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting
                    ? 'Modification…'
                    : 'Modifier le mot de passe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
