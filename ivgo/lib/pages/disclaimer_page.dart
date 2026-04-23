import 'package:flutter/material.dart';

class DisclaimerPage extends StatefulWidget {
  const DisclaimerPage({
    super.key,
    required this.onAccepted,
  });

  final Future<void> Function() onAccepted;

  @override
  State<DisclaimerPage> createState() => _DisclaimerPageState();
}

class _DisclaimerPageState extends State<DisclaimerPage> {
  bool _hasConfirmed = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Before you begin',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'IVGo is a job aid for tracking infusion progress when automated systems are unavailable or unsuitable. It does not control infusion delivery.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You remain responsible for clinical decisions, equipment checks, and active monitoring throughout each infusion.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _hasConfirmed,
                    onChanged: _isSaving
                        ? null
                        : (bool? value) {
                            setState(() {
                              _hasConfirmed = value ?? false;
                            });
                          },
                    title: const Text(
                      'I understand that IVGo is a job aid and not an automated infusion controller, and that I remain responsible for clinical decisions, equipment checks, and active monitoring.',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _hasConfirmed && !_isSaving ? _acceptDisclaimer : null,
                    child: Text(_isSaving ? 'Saving...' : 'Accept and continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _acceptDisclaimer() async {
    setState(() {
      _isSaving = true;
    });

    await widget.onAccepted();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });
  }
}