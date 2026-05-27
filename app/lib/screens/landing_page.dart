import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({
    super.key,
    required this.hasAdmin,
    required this.backendLabel,
    required this.onAdminSelected,
    required this.onScreenSelected,
  });

  final bool hasAdmin;
  final String backendLabel;
  final VoidCallback onAdminSelected;
  final VoidCallback onScreenSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE7F5EF), Color(0xFFF9FCFB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  SizedBox(
                    width: 864,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Backend mode: $backendLabel',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ),
                  _ModeCard(
                    title: hasAdmin ? 'Admin Login' : 'Create Admin',
                    subtitle:
                        'Manage company profile, screens, and media assignments.',
                    icon: Icons.admin_panel_settings_outlined,
                    actionLabel: hasAdmin ? 'Open Admin' : 'Setup Admin',
                    onPressed: onAdminSelected,
                  ),
                  _ModeCard(
                    title: 'Screen Login',
                    subtitle:
                        'Sign a display in with its own code and show assigned content.',
                    icon: Icons.tv_outlined,
                    actionLabel: 'Open Screen',
                    onPressed: onScreenSelected,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCF0EA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 34, color: const Color(0xFF0F766E)),
              ),
              const SizedBox(height: 24),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(subtitle),
              const SizedBox(height: 24),
              FilledButton(onPressed: onPressed, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
