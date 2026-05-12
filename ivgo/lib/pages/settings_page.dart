import 'package:flutter/material.dart';
import 'package:ivgo/repositories/first_launch_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.firstLaunchRepository,
  });

  final FirstLaunchRepository firstLaunchRepository;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isReplayingWalkthrough = false;

  Future<void> _replayWalkthrough() async {
    setState(() {
      _isReplayingWalkthrough = true;
    });

    await widget.firstLaunchRepository.setHasSeenOnboarding(false);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Walkthrough will show on next app launch'),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          const _SectionHeader(title: 'General'),
          ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: const Text('Replay Walkthrough'),
            subtitle: const Text('Show the onboarding wizard again'),
            trailing: _isReplayingWalkthrough
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _isReplayingWalkthrough ? null : _replayWalkthrough,
          ),
          const Divider(),
          const _SectionHeader(title: 'Appearance'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme (coming soon)'),
            value: false,
            onChanged: null,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}