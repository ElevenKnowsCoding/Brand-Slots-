import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_models.dart';
import '../services/local_apk_builder.dart';
import '../state/app_controller.dart';

enum _AdminSection { dashboard, screens, clients, player }

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  _AdminSection _section = _AdminSection.dashboard;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 960;
    final sectionMeta = _sectionMeta(_section);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1E8),
      appBar: isCompact
          ? AppBar(
              backgroundColor: const Color(0xFFF4F1E8),
              foregroundColor: const Color(0xFF1E2D2A),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sectionMeta.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    sectionMeta.subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF687672)),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: widget.controller.logout,
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            )
          : null,
      drawer: isCompact
          ? Drawer(
              child: SafeArea(
                child: _SidebarNavigation(
                  controller: widget.controller,
                  selected: _section,
                  onSelected: (value) {
                    setState(() => _section = value);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!isCompact)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
                child: SizedBox(
                  width: 280,
                  child: _SidebarNavigation(
                    controller: widget.controller,
                    selected: _section,
                    onSelected: (value) => setState(() => _section = value),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(isCompact ? 16 : 24, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCompact)
                      _TopHeader(
                        title: sectionMeta.title,
                        subtitle: sectionMeta.subtitle,
                        controller: widget.controller,
                      ),
                    if (!isCompact) const SizedBox(height: 20),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: KeyedSubtree(
                          key: ValueKey<_AdminSection>(_section),
                          child: _SectionBody(
                            section: _section,
                            controller: widget.controller,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isCompact
          ? NavigationBar(
              selectedIndex: _AdminSection.values.indexOf(_section),
              onDestinationSelected: (index) {
                setState(() => _section = _AdminSection.values[index]);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.space_dashboard_rounded),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tv_rounded),
                  label: 'Screens',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_rounded),
                  label: 'Clients',
                ),
                NavigationDestination(
                  icon: Icon(Icons.play_circle_rounded),
                  label: 'Player',
                ),
              ],
            )
          : null,
    );
  }
}

class _SectionMeta {
  const _SectionMeta(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

_SectionMeta _sectionMeta(_AdminSection section) {
  switch (section) {
    case _AdminSection.dashboard:
      return const _SectionMeta(
        'Dashboard',
        'Overview of screens, playback, and media health.',
      );
    case _AdminSection.screens:
      return const _SectionMeta(
        'Screens',
        'Register screens, generate APKs, and monitor activity.',
      );
    case _AdminSection.clients:
      return const _SectionMeta(
        'Clients',
        'Manage the client profile, branding, and deployment links.',
      );
    case _AdminSection.player:
      return const _SectionMeta(
        'Screen Player',
        'Track playback counts and manage the media lineup.',
      );
  }
}

class _SidebarNavigation extends StatelessWidget {
  const _SidebarNavigation({
    required this.controller,
    required this.selected,
    required this.onSelected,
  });

  final AppController controller;
  final _AdminSection selected;
  final ValueChanged<_AdminSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final profile = controller.organization;
    final items = [
      (
        section: _AdminSection.dashboard,
        icon: Icons.space_dashboard_rounded,
        label: 'Dashboard',
      ),
      (
        section: _AdminSection.screens,
        icon: Icons.tv_rounded,
        label: 'Screens',
      ),
      (
        section: _AdminSection.clients,
        icon: Icons.groups_rounded,
        label: 'Clients',
      ),
      (
        section: _AdminSection.player,
        icon: Icons.play_circle_rounded,
        label: 'Screen Player',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F3A37),
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF274744),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ad Master',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profile.companyName.isEmpty
                      ? 'Client profile not configured'
                      : profile.companyName,
                  style: const TextStyle(
                    color: Color(0xFFD6E5E0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  controller.backendLabel,
                  style: const TextStyle(
                    color: Color(0xFF99B5AF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SidebarButton(
                icon: item.icon,
                label: item.label,
                selected: selected == item.section,
                onTap: () => onSelected(item.section),
              ),
            ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF274744),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deployment',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${controller.screens.length} screens linked',
                  style: const TextStyle(color: Color(0xFFD6E5E0)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF0C15D) : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? const Color(0xFF1F3A37) : Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: selected ? const Color(0xFF1F3A37) : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.title,
    required this.subtitle,
    required this.controller,
  });

  final String title;
  final String subtitle;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBF5E9), Color(0xFFF5E7C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E2D2A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF5E6A67),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: controller.logout,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1F3A37),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({required this.section, required this.controller});

  final _AdminSection section;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case _AdminSection.dashboard:
        return _DashboardSection(controller: controller);
      case _AdminSection.screens:
        return _ScreensSection(controller: controller);
      case _AdminSection.clients:
        return _ClientsSection(controller: controller);
      case _AdminSection.player:
        return _PlayerSection(controller: controller);
    }
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final screens = controller.screens;
    final mediaItems = controller.mediaItems;
    final totalPlays = screens.fold<int>(0, (sum, item) => sum + item.playCount);
    final totalRounds = screens.fold<int>(
      0,
      (sum, item) => sum + item.completedRounds,
    );

    return ListView(
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _HeroStatCard(
              title: 'Screens Live',
              value: '${screens.length}',
              note: '${screens.where((s) => s.lastSeenAt != null).length} checked in',
              color: const Color(0xFF1F3A37),
              icon: Icons.tv_rounded,
            ),
            _HeroStatCard(
              title: 'Media Library',
              value: '${mediaItems.length}',
              note: 'Videos and image creatives',
              color: const Color(0xFFC66A3D),
              icon: Icons.video_collection_rounded,
            ),
            _HeroStatCard(
              title: 'Play Count',
              value: '$totalPlays',
              note: 'Total tracked item completions',
              color: const Color(0xFF4B6A9B),
              icon: Icons.play_circle_fill_rounded,
            ),
            _HeroStatCard(
              title: 'Completed Rounds',
              value: '$totalRounds',
              note: 'Full playlist cycles',
              color: const Color(0xFF6D8A3B),
              icon: Icons.sync_rounded,
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 900;
            if (stacked) {
              return Column(
                children: [
                  _SoftPanel(
                    child: _RecentScreensPanel(controller: controller),
                  ),
                  const SizedBox(height: 16),
                  _SoftPanel(
                    child: _PlaybackHighlightsPanel(controller: controller),
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SoftPanel(
                    child: _RecentScreensPanel(controller: controller),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SoftPanel(
                    child: _PlaybackHighlightsPanel(controller: controller),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RecentScreensPanel extends StatelessWidget {
  const _RecentScreensPanel({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final screens = [...controller.screens]
      ..sort((a, b) => (b.lastSeenAt ?? '').compareTo(a.lastSeenAt ?? ''));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          title: 'Recent Screens',
          subtitle: 'Quick visibility into device health and engagement.',
        ),
        const SizedBox(height: 16),
        if (screens.isEmpty)
          const Text('No screens registered yet.')
        else
          for (final screen in screens.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ScreenSummaryTile(screen: screen),
            ),
      ],
    );
  }
}

class _PlaybackHighlightsPanel extends StatelessWidget {
  const _PlaybackHighlightsPanel({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final screens = controller.screens;
    final sortedScreens = [...screens]
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    final best = sortedScreens.isEmpty ? null : sortedScreens.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          title: 'Playback Snapshot',
          subtitle: 'What the screen fleet is actually doing right now.',
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF5E7C7),
            borderRadius: BorderRadius.circular(24),
          ),
          child: best == null
              ? const Text('Playback data will appear after screens start looping media.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top Screen',
                      style: TextStyle(
                        color: Color(0xFF7B6340),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      best.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E2D2A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Played ${best.playCount} items'),
                    Text('Completed ${best.completedRounds} full rounds'),
                    Text(
                      'Last playback: ${_formatTimestamp(best.lastPlaybackAt)}',
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ScreensSection extends StatefulWidget {
  const _ScreensSection({required this.controller});

  final AppController controller;

  @override
  State<_ScreensSection> createState() => _ScreensSectionState();
}

class _ScreensSectionState extends State<_ScreensSection> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _locationController = TextEditingController();
  late final LocalApkBuilder _apkBuilder;

  @override
  void initState() {
    super.initState();
    _apkBuilder = createLocalApkBuilder();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _addScreen() async {
    final message = await widget.controller.addScreen(
      name: _nameController.text,
      loginCode: _codeController.text,
      password: _passwordController.text,
      location: _locationController.text,
    );
    if (!mounted) return;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    _nameController.clear();
    _codeController.clear();
    _passwordController.clear();
    _locationController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Screen created successfully.')));
  }

  Future<void> _showApkCommand(ScreenDevice screen) async {
    final command =
        '.\\scripts\\build_screen_apk.ps1 -ScreenCode "${screen.loginCode}" '
        '-ScreenPassword "${screen.password}" '
        '-ScreenName "${screen.name}"';
    final downloadUrl = widget.controller.apkDownloadUrlForScreen(screen);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('APK build for ${screen.name}'),
        content: SelectableText(
          'Asset: ${screen.apkAssetFileName}\n'
          '${downloadUrl == null ? '' : 'Download URL: $downloadUrl\n\n'}'
          'Build command:\n$command',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: command));
              if (!mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('APK build command copied.')),
              );
            },
            child: const Text('Copy Command'),
          ),
          if (downloadUrl != null)
            TextButton(
              onPressed: () async {
                final uri = Uri.tryParse(downloadUrl);
                if (uri != null) await launchUrl(uri);
              },
              child: const Text('Download APK'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _buildApkLocally(ScreenDevice screen) async {
    final projectPath = widget.controller.organization.localProjectPath;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: SizedBox(
          width: 260,
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text('Building APK locally...')),
            ],
          ),
        ),
      ),
    );

    final result = await _apkBuilder.buildScreenApk(
      projectPath: projectPath,
      screen: screen,
    );

    if (!mounted) return;
    Navigator.of(context).pop();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.success ? 'APK Build Complete' : 'APK Build Failed'),
        content: SelectableText(
          [
            result.message,
            if (result.apkPath != null) 'APK Path: ${result.apkPath}',
            if (result.log != null && result.log!.isNotEmpty) '',
            if (result.log != null && result.log!.isNotEmpty) result.log!,
          ].join('\n'),
        ),
        actions: [
          if (result.apkPath != null)
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: result.apkPath!));
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('APK path copied.')),
                );
              },
              child: const Text('Copy Path'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = widget.controller.screens;
    final apkBaseUrl = widget.controller.organization.apkBaseUrl;

    return ListView(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 980;
            if (stacked) {
              return Column(
                children: [
                  _SoftPanel(child: _buildForm()),
                  const SizedBox(height: 16),
                  _SoftPanel(child: _buildGrid(screens, apkBaseUrl)),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 360, child: _SoftPanel(child: _buildForm())),
                const SizedBox(width: 16),
                Expanded(child: _SoftPanel(child: _buildGrid(screens, apkBaseUrl))),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          title: 'Register Screen',
          subtitle: 'Create a new screen endpoint with credentials and location.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Screen name'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _locationController,
          decoration: const InputDecoration(labelText: 'Location'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _codeController,
          decoration: const InputDecoration(labelText: 'Login code'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Login password'),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _addScreen,
            child: const Text('Add Screen'),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(List<ScreenDevice> screens, String apkBaseUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          title: 'Screen Fleet',
          subtitle: 'Each card shows playback health, APK access, and device state.',
        ),
        const SizedBox(height: 16),
        if (screens.isEmpty)
          const Text('No screens registered yet.')
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 1200
                  ? 3
                  : width > 760
                  ? 2
                  : 1;
              final childAspectRatio = width > 1200
                  ? 1.18
                  : width > 760
                  ? 1.0
                  : 0.86;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: screens.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemBuilder: (context, index) {
                  final screen = screens[index];
                  final downloadUrl = apkBaseUrl.trim().isEmpty
                      ? null
                      : widget.controller.apkDownloadUrlForScreen(screen);
                  return _ScreenCard(
                    screen: screen,
                    downloadUrl: downloadUrl,
                    onApkBuild: () => _showApkCommand(screen),
                    onLocalBuild: _apkBuilder.isSupported
                        ? () => _buildApkLocally(screen)
                        : null,
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class _ClientsSection extends StatefulWidget {
  const _ClientsSection({required this.controller});

  final AppController controller;

  @override
  State<_ClientsSection> createState() => _ClientsSectionState();
}

class _ClientsSectionState extends State<_ClientsSection> {
  late final TextEditingController _companyController;
  late final TextEditingController _adminController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _welcomeController;
  late final TextEditingController _logoController;
  late final TextEditingController _colorController;
  late final TextEditingController _apkBaseUrlController;
  late final TextEditingController _localProjectPathController;

  @override
  void initState() {
    super.initState();
    final profile = widget.controller.organization;
    _companyController = TextEditingController(text: profile.companyName);
    _adminController = TextEditingController(text: profile.adminName);
    _emailController = TextEditingController(text: profile.adminEmail);
    _phoneController = TextEditingController(text: profile.phone);
    _welcomeController = TextEditingController(text: profile.welcomeMessage);
    _logoController = TextEditingController(text: profile.logoUrl);
    _colorController = TextEditingController(text: profile.accentColorHex);
    _apkBaseUrlController = TextEditingController(text: profile.apkBaseUrl);
    _localProjectPathController = TextEditingController(
      text: profile.localProjectPath,
    );
  }

  @override
  void dispose() {
    _companyController.dispose();
    _adminController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _welcomeController.dispose();
    _logoController.dispose();
    _colorController.dispose();
    _apkBaseUrlController.dispose();
    _localProjectPathController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.controller.updateOrganization(
      OrganizationProfile(
        companyName: _companyController.text.trim(),
        adminName: _adminController.text.trim(),
        adminEmail: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        welcomeMessage: _welcomeController.text.trim(),
        logoUrl: _logoController.text.trim(),
        accentColorHex: _colorController.text.trim().isEmpty
            ? '#0F766E'
            : _colorController.text.trim(),
        apkBaseUrl: _apkBaseUrlController.text.trim(),
        localProjectPath: _localProjectPathController.text.trim(),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Client profile saved.')),
    );
  }

  Future<void> _pickLocalProjectPath() async {
    final picked = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select the Flutter app folder',
    );
    if (picked == null || picked.isEmpty) return;
    _localProjectPathController.text = picked;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 980;
            final profileCard = _SoftPanel(child: _buildProfileForm());
            final brandCard = _SoftPanel(child: _buildBrandSummary());
            if (stacked) {
              return Column(
                children: [
                  profileCard,
                  const SizedBox(height: 16),
                  brandCard,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: profileCard),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: brandCard),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          title: 'Client Profile',
          subtitle: 'Keep the admin owner, branding, and deployment links organized.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _companyController,
          decoration: const InputDecoration(labelText: 'Company name'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _adminController,
          decoration: const InputDecoration(labelText: 'Admin name'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Admin email'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Phone'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _welcomeController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Welcome message'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _logoController,
          decoration: const InputDecoration(labelText: 'Logo URL'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _colorController,
          decoration: const InputDecoration(labelText: 'Accent color hex'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _apkBaseUrlController,
          decoration: const InputDecoration(labelText: 'APK base URL'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _localProjectPathController,
          decoration: InputDecoration(
            labelText: 'Local Flutter project path',
            suffixIcon: IconButton(
              onPressed: _pickLocalProjectPath,
              icon: const Icon(Icons.folder_open_rounded),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: _save,
            child: const Text('Save Client Profile'),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandSummary() {
    final profile = widget.controller.organization;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          title: 'Brand Summary',
          subtitle: 'A quick snapshot for the client-facing system settings.',
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1F3A37),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.companyName.isEmpty ? 'No Company Name' : profile.companyName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                profile.welcomeMessage.isEmpty
                    ? 'No welcome message configured.'
                    : profile.welcomeMessage,
                style: const TextStyle(color: Color(0xFFD6E5E0)),
              ),
              const SizedBox(height: 16),
              _SummaryChip(
                label: 'Accent',
                value: profile.accentColorHex,
              ),
              const SizedBox(height: 10),
              _SummaryChip(
                label: 'APK Link',
                value: profile.apkBaseUrl.isEmpty ? 'Not set' : profile.apkBaseUrl,
              ),
              const SizedBox(height: 10),
              _SummaryChip(
                label: 'Local Build Path',
                value: profile.localProjectPath.isEmpty
                    ? 'Not set'
                    : profile.localProjectPath,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayerSection extends StatefulWidget {
  const _PlayerSection({required this.controller});

  final AppController controller;

  @override
  State<_PlayerSection> createState() => _PlayerSectionState();
}

class _PlayerSectionState extends State<_PlayerSection> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '15');
  final Set<String> _selectedScreenIds = <String>{};
  MediaKind _kind = MediaKind.video;
  Uint8List? _selectedBytes;
  String? _selectedFileName;

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _addMedia() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a media title first.')));
      return;
    }
    if (_urlController.text.trim().isEmpty && _selectedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provide a public URL or upload a file first.')),
      );
      return;
    }
    final duration = int.tryParse(_durationController.text.trim()) ?? 15;
    await widget.controller.addMedia(
      title: _titleController.text,
      kind: _kind,
      description: _descriptionController.text,
      durationSeconds: duration,
      screenIds: _selectedScreenIds.toList(),
      externalUrl: _urlController.text.trim().isEmpty ? null : _urlController.text,
      fileBytes: _selectedBytes,
      fileName: _selectedFileName,
    );
    if (!mounted) return;
    _titleController.clear();
    _urlController.clear();
    _descriptionController.clear();
    _durationController.text = '15';
    _selectedScreenIds.clear();
    _selectedBytes = null;
    _selectedFileName = null;
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Media added to the lineup.')));
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: _kind == MediaKind.video ? FileType.video : FileType.image,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _selectedBytes = file.bytes;
      _selectedFileName = file.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = widget.controller.screens;
    final mediaItems = widget.controller.mediaItems;

    return ListView(
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: screens
              .map(
                (screen) => SizedBox(
                  width: 260,
                  child: _MiniMetricCard(
                    title: screen.name,
                    lines: [
                      'Items played: ${screen.playCount}',
                      'Full rounds: ${screen.completedRounds}',
                      'Last playback: ${_formatTimestamp(screen.lastPlaybackAt)}',
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 1000;
            final editor = _SoftPanel(child: _buildMediaEditor(screens));
            final library = _SoftPanel(child: _buildMediaLibrary(mediaItems));
            if (stacked) {
              return Column(
                children: [
                  editor,
                  const SizedBox(height: 16),
                  library,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: editor),
                const SizedBox(width: 16),
                Expanded(flex: 6, child: library),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMediaEditor(List<ScreenDevice> screens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          title: 'Media Lineup',
          subtitle: 'Upload, assign, and schedule player content.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<MediaKind>(
          value: _kind,
          decoration: const InputDecoration(labelText: 'Media type'),
          items: const [
            DropdownMenuItem(value: MediaKind.video, child: Text('Video')),
            DropdownMenuItem(value: MediaKind.image, child: Text('Image')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _kind = value);
          },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _urlController,
          decoration: InputDecoration(
            labelText: _kind == MediaKind.video ? 'Video URL' : 'Image URL',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _durationController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Display duration (seconds)'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _descriptionController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: screens.map((screen) {
            final selected = _selectedScreenIds.contains(screen.id);
            return FilterChip(
              selected: selected,
              label: Text(screen.name),
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _selectedScreenIds.add(screen.id);
                  } else {
                    _selectedScreenIds.remove(screen.id);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(
                _selectedFileName == null ? 'Upload File' : _selectedFileName!,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'The screen player now uses these media assignments for analytics and offline caching.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _addMedia,
          child: const Text('Save Media'),
        ),
      ],
    );
  }

  Widget _buildMediaLibrary(List<MediaItem> mediaItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          title: 'Player Library',
          subtitle: 'Content already available to the screen fleet.',
        ),
        const SizedBox(height: 16),
        if (mediaItems.isEmpty)
          const Text('No media has been added yet.')
        else
          for (final item in mediaItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFE0E5D7),
                      child: Icon(
                        item.kind == MediaKind.video
                            ? Icons.play_arrow_rounded
                            : Icons.image_rounded,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.kind.name} | ${item.durationSeconds}s',
                            style: const TextStyle(color: Color(0xFF6B7773)),
                          ),
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(item.description),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => widget.controller.deleteMedia(item.id),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  const _HeroStatCard({
    required this.title,
    required this.value,
    required this.note,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final String note;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(color: Color(0xFFD5E6E1), fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(note, style: const TextStyle(color: Color(0xFFD5E6E1))),
        ],
      ),
    );
  }
}

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E2D2A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF6C7672)),
        ),
      ],
    );
  }
}

class _ScreenSummaryTile extends StatelessWidget {
  const _ScreenSummaryTile({required this.screen});

  final ScreenDevice screen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE2E8E1),
            child: Icon(Icons.tv_rounded),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  screen.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text('${screen.location} • ${screen.assignedMediaIds.length} assigned'),
              ],
            ),
          ),
          Text(
            _formatTimestamp(screen.lastSeenAt),
            style: const TextStyle(color: Color(0xFF6C7672)),
          ),
        ],
      ),
    );
  }
}

class _ScreenCard extends StatelessWidget {
  const _ScreenCard({
    required this.screen,
    required this.downloadUrl,
    required this.onApkBuild,
    required this.onLocalBuild,
  });

  final ScreenDevice screen;
  final String? downloadUrl;
  final VoidCallback onApkBuild;
  final VoidCallback? onLocalBuild;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE1E8DF),
                child: Icon(Icons.tv_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  screen.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryChip(label: 'Code', value: screen.loginCode),
          const SizedBox(height: 8),
          _SummaryChip(label: 'Location', value: screen.location),
          const SizedBox(height: 8),
          _SummaryChip(label: 'APK', value: screen.apkAssetFileName),
          const Spacer(),
          Text('Items played: ${screen.playCount}'),
          Text('Completed rounds: ${screen.completedRounds}'),
          Text('Last seen: ${_formatTimestamp(screen.lastSeenAt)}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: onApkBuild,
                child: const Text('APK Build'),
              ),
              if (onLocalBuild != null)
                FilledButton.tonal(
                  onPressed: onLocalBuild,
                  child: const Text('Build Local'),
                ),
              if (downloadUrl != null)
                FilledButton(
                  onPressed: () async {
                    final uri = Uri.tryParse(downloadUrl!);
                    if (uri != null) await launchUrl(uri);
                  },
                  child: const Text('Download'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2ED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Color(0xFF25322F)),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: value.isEmpty ? 'Not set' : value),
          ],
        ),
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line),
            ),
        ],
      ),
    );
  }
}

String _formatTimestamp(String? value) {
  if (value == null || value.isEmpty) return 'Never';
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return value;
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  final hh = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');
  return '$mm/$dd ${date.year} $hh:$min';
}
