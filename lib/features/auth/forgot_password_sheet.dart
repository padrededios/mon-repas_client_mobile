import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/providers.dart';

/// Feuille « mot de passe oublié » : demande l'envoi d'un lien de
/// réinitialisation. La confirmation est volontairement neutre (l'API ne
/// révèle pas si l'email correspond à un compte).
class ForgotPasswordSheet extends ConsumerStatefulWidget {
  const ForgotPasswordSheet({super.key, this.initialEmail = ''});

  final String initialEmail;

  static Future<void> show(BuildContext context, {String initialEmail = ''}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ForgotPasswordSheet(initialEmail: initialEmail),
    );
  }

  @override
  ConsumerState<ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _submitting = false;
  String? _sentTo;
  String? _apiError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text.trim();
    setState(() {
      _submitting = true;
      _apiError = null;
    });
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email);
      if (mounted) setState(() => _sentTo = email);
    } on ApiException catch (e) {
      if (mounted) setState(() => _apiError = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final title = Text(
      'Mot de passe oublié',
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );

    return Padding(
      // Laisse la place au clavier.
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _sentTo != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 12),
                Text(
                  'Si un compte actif correspond à $_sentTo, un lien de '
                  'réinitialisation vient d’être envoyé. Il est valable 1 heure.',
                  style: TextStyle(color: colors.mutedForeground),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Retour à la connexion'),
                  ),
                ),
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 8),
                  Text(
                    'Indiquez votre email : nous vous enverrons un lien pour '
                    'choisir un nouveau mot de passe.',
                    style: TextStyle(color: colors.mutedForeground),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: validateEmail,
                    onFieldSubmitted: (_) => _submit(),
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
                      child: Text(
                          _submitting ? 'Envoi…' : 'Recevoir le lien'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
