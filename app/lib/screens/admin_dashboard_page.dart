import 'dart:math' as math;

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
      backgroundColor: const Color(0xFFF6F8FC),
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
                padding: EdgeInsets.fromLTRB(isCompact ? 16 : 24, 18, 20, 20),
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
                  label: 'Devices',
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

Future<void> _openExternalUrl(BuildContext context, String url) async {
  final trimmed = url.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('The download link is invalid.')),
    );
    return;
  }

  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (launched) return;
  } catch (_) {}

  await Clipboard.setData(ClipboardData(text: trimmed));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Could not open the link. The download URL was copied instead.',
      ),
    ),
  );
}

_SectionMeta _sectionMeta(_AdminSection section) {
  switch (section) {
    case _AdminSection.dashboard:
      return const _SectionMeta(
        'Dashboard',
        'Overview of your advertising network and live screen health.',
      );
    case _AdminSection.screens:
      return const _SectionMeta(
        'Devices',
        'Manage screens, APK access, and deployment readiness.',
      );
    case _AdminSection.clients:
      return const _SectionMeta(
        'Clients',
        'Design the client profile, billing setup, and brand delivery links.',
      );
    case _AdminSection.player:
      return const _SectionMeta(
        'Screen Player',
        'Program the media lineup and screen playback schedule.',
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
        label: 'Devices',
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
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE6EBF4)),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A163152),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5A5FF0), Color(0xFF7A4DFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: const Color(0x1FFFFFFF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.desktop_windows_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ad',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.companyName.isEmpty
                            ? 'Digital Advertising'
                            : profile.companyName,
                        style: const TextStyle(
                          color: Color(0xFFEDEBFF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
              color: const Color(0xFFF5F7FD),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE3E9F4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.wifi_tethering_rounded,
                      size: 18,
                      color: Color(0xFF23A55A),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Connected',
                      style: TextStyle(
                        color: Color(0xFF14233B),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${controller.screens.length} devices linked',
                  style: const TextStyle(
                    color: Color(0xFF6D7B93),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  controller.backendLabel,
                  style: const TextStyle(
                    color: Color(0xFF97A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE6EBF4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.adminName.isEmpty ? 'Super Admin' : profile.adminName,
                  style: TextStyle(
                    color: const Color(0xFF14233B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.adminEmail.isEmpty
                      ? 'Admin access ready'
                      : profile.adminEmail,
                  style: const TextStyle(color: Color(0xFF74839C)),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: controller.logout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Logout'),
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
      color: selected ? const Color(0xFFEFF2FF) : Colors.transparent,
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
                color: selected ? const Color(0xFF3268F5) : const Color(0xFF7E8BA3),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: selected ? const Color(0xFF2154DD) : const Color(0xFF22324A),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (selected)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF3268F5),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ad  >  $title',
                  style: const TextStyle(
                    color: Color(0xFF72819A),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111C32),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF60718D),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAFBF0),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_rounded,
                          size: 18,
                          color: Color(0xFF20A25A),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Connected',
                          style: TextStyle(
                            color: Color(0xFF17894A),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F3)),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.notifications_none_rounded),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        top: -4,
                        child: Container(
                          height: 22,
                          width: 22,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF44F5A),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${math.max(1, controller.screens.length)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: controller.logout,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF171B22),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Logout'),
              ),
            ],
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
    final onlineScreens = screens.where((s) => s.lastSeenAt != null).length;

    return ListView(
      children: [
        Row(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAFBF0),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 10, color: Color(0xFF66D18F)),
                  SizedBox(width: 10),
                  Text(
                    'Live Updates',
                    style: TextStyle(
                      color: Color(0xFF148A4A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F3)),
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _HeroStatCard(
              title: 'Total Screens',
              value: '${screens.length}',
              note: '$onlineScreens online',
              accent: const Color(0xFF2F67F6),
              surface: const Color(0xFFF7FAFF),
              icon: Icons.desktop_windows_rounded,
            ),
            _HeroStatCard(
              title: 'Active Campaigns',
              value: '${mediaItems.isEmpty ? 0 : 1}',
              note: '${mediaItems.length} media assets',
              accent: const Color(0xFF9155F6),
              surface: const Color(0xFFFBF7FF),
              icon: Icons.play_circle_outline_rounded,
            ),
            _HeroStatCard(
              title: "Today's Impressions",
              value: '$totalPlays',
              note: totalPlays == 0 ? 'Waiting for playback' : '+12.5% vs yesterday',
              accent: const Color(0xFF22B45B),
              surface: const Color(0xFFF5FFF8),
              icon: Icons.groups_2_rounded,
            ),
            _HeroStatCard(
              title: "Today's Revenue",
              value: '₹${totalRounds * 87}',
              note: totalRounds == 0 ? 'Add campaigns to start billing' : '+8.3% vs yesterday',
              accent: const Color(0xFFE6A100),
              surface: const Color(0xFFFFF9E9),
              icon: Icons.attach_money_rounded,
            ),
          ],
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 1120;
            final analytics = _SoftPanel(
              child: _PerformanceOverviewPanel(
                totalPlays: totalPlays,
                totalRounds: totalRounds,
              ),
            );
            final insights = _SoftPanel(
              child: _OperationsSnapshotPanel(controller: controller),
            );
            if (stacked) {
              return Column(
                children: [
                  analytics,
                  const SizedBox(height: 16),
                  insights,
                  const SizedBox(height: 16),
                  _SoftPanel(child: _RecentScreensPanel(controller: controller)),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: analytics),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: insights),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _SoftPanel(child: _RecentScreensPanel(controller: controller)),
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
          title: 'Recent Devices',
          subtitle: 'Quick visibility into field health, activity, and assigned content.',
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

class _PerformanceOverviewPanel extends StatelessWidget {
  const _PerformanceOverviewPanel({
    required this.totalPlays,
    required this.totalRounds,
  });

  final int totalPlays;
  final int totalRounds;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          title: 'Performance Overview',
          subtitle: 'Impressions, plays, and revenue rhythm across the network.',
        ),
        const SizedBox(height: 18),
        Container(
          height: 280,
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFDFEFF), Color(0xFFF4F8FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFE6ECF7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MetricTag(
                    label: 'Plays',
                    value: '$totalPlays',
                    color: const Color(0xFF2F67F6),
                  ),
                  const SizedBox(width: 10),
                  _MetricTag(
                    label: 'Rounds',
                    value: '$totalRounds',
                    color: const Color(0xFF22B45B),
                  ),
                  const SizedBox(width: 10),
                  _MetricTag(
                    label: 'Revenue',
                    value: '₹${totalRounds * 87}',
                    color: const Color(0xFFE6A100),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: CustomPaint(
                  painter: _TrendPainter(
                    points: totalPlays == 0
                        ? const [52, 38, 31, 30, 44, 35, 42]
                        : [
                            math.max(18, totalPlays + 12).toDouble(),
                            math.max(12, totalPlays * 0.72).toDouble(),
                            math.max(10, totalPlays * 0.55).toDouble(),
                            math.max(10, totalPlays * 0.58).toDouble(),
                            math.max(16, totalPlays * 0.9).toDouble(),
                            math.max(14, totalPlays * 0.68).toDouble(),
                            math.max(16, totalPlays * 0.86).toDouble(),
                          ],
                  ),
                  child: Container(),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

class _OperationsSnapshotPanel extends StatelessWidget {
  const _OperationsSnapshotPanel({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final screens = controller.screens;
    final sortedScreens = [...screens]
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    final best = sortedScreens.isEmpty ? null : sortedScreens.first;
    final mediaItems = controller.mediaItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          title: 'Operations Snapshot',
          subtitle: 'A quick read on the most important live system signals.',
        ),
        const SizedBox(height: 16),
        _InsightCard(
          title: 'Top Screen',
          value: best?.name ?? 'No devices yet',
          detail: best == null
              ? 'Register a device to start tracking playback.'
              : 'Played ${best.playCount} items and completed ${best.completedRounds} rounds.',
          icon: Icons.devices_other_rounded,
          accent: const Color(0xFF2F67F6),
        ),
        const SizedBox(height: 12),
        _InsightCard(
          title: 'Media Library',
          value: '$mediaItems assets',
          detail: mediaItems == 0
              ? 'Upload videos or images to power campaigns.'
              : 'Ready to deliver content across the connected fleet.',
          icon: Icons.video_collection_outlined,
          accent: const Color(0xFF8C56F7),
        ),
        const SizedBox(height: 12),
        _InsightCard(
          title: 'System Health',
          value: '${screens.where((s) => s.lastSeenAt != null).length}/${screens.length}',
          detail: 'Devices checked in recently and reporting activity.',
          icon: Icons.health_and_safety_outlined,
          accent: const Color(0xFF20A25A),
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
  final _searchController = TextEditingController();
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
    _searchController.dispose();
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
                await _openExternalUrl(context, downloadUrl);
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
    final filteredScreens = screens.where((screen) {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) return true;
      return screen.name.toLowerCase().contains(query) ||
          screen.location.toLowerCase().contains(query) ||
          screen.loginCode.toLowerCase().contains(query);
    }).toList();
    final onlineCount = screens.where((screen) => screen.lastSeenAt != null).length;
    final downloadReady = screens.where((screen) => apkBaseUrl.trim().isNotEmpty).length;

    return ListView(
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _HeroStatCard(
              title: 'Total',
              value: '${screens.length}',
              note: 'Registered screens',
              accent: const Color(0xFF2F67F6),
              surface: const Color(0xFFF7FAFF),
              icon: Icons.desktop_windows_rounded,
            ),
            _HeroStatCard(
              title: 'Online',
              value: '$onlineCount',
              note: 'Checked in recently',
              accent: const Color(0xFF22B45B),
              surface: const Color(0xFFF5FFF8),
              icon: Icons.wifi_rounded,
            ),
            _HeroStatCard(
              title: 'Offline',
              value: '${screens.length - onlineCount}',
              note: 'Needs attention',
              accent: const Color(0xFFF04C5A),
              surface: const Color(0xFFFFF7F8),
              icon: Icons.wifi_off_rounded,
            ),
            _HeroStatCard(
              title: 'Download Ready',
              value: '$downloadReady',
              note: apkBaseUrl.trim().isEmpty ? 'Set APK base URL' : 'GitHub release linked',
              accent: const Color(0xFF8C56F7),
              surface: const Color(0xFFFBF7FF),
              icon: Icons.download_rounded,
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Search devices by name, location, or login code...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 980;
            if (stacked) {
              return Column(
                children: [
                  _SoftPanel(child: _buildForm()),
                  const SizedBox(height: 16),
                  _SoftPanel(child: _buildGrid(filteredScreens, apkBaseUrl)),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 360, child: _SoftPanel(child: _buildForm())),
                const SizedBox(width: 16),
                Expanded(
                  child: _SoftPanel(child: _buildGrid(filteredScreens, apkBaseUrl)),
                ),
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
          title: 'Add Device',
          subtitle: 'Register a new screen endpoint with credentials and deployment metadata.',
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
            child: const Text('Add Device'),
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
          title: 'Device Management',
          subtitle: 'Monitor live status, playback activity, and APK delivery readiness.',
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
              final mainAxisExtent = width > 1200
                  ? 430.0
                  : width > 760
                  ? 450.0
                  : 500.0;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: screens.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisExtent: mainAxisExtent,
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
  final _searchController = TextEditingController();

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
    _searchController.dispose();
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
    final profile = widget.controller.organization;
    final fieldsCompleted = [
      _companyController.text,
      _adminController.text,
      _emailController.text,
      _phoneController.text,
      _apkBaseUrlController.text,
    ].where((value) => value.trim().isNotEmpty).length;
    final completeness = ((fieldsCompleted / 5) * 100).round();

    return ListView(
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _HeroStatCard(
              title: 'Profile Score',
              value: '$completeness%',
              note: 'Core setup completed',
              accent: const Color(0xFF2F67F6),
              surface: const Color(0xFFF7FAFF),
              icon: Icons.badge_outlined,
            ),
            _HeroStatCard(
              title: 'Deployment',
              value: profile.apkBaseUrl.trim().isEmpty ? 'Pending' : 'Ready',
              note: profile.apkBaseUrl.trim().isEmpty
                  ? 'Link GitHub release downloads'
                  : 'APK download base is connected',
              accent: const Color(0xFF22B45B),
              surface: const Color(0xFFF5FFF8),
              icon: Icons.cloud_done_outlined,
            ),
            _HeroStatCard(
              title: 'Brand Assets',
              value: profile.logoUrl.trim().isEmpty ? '0' : '1',
              note: profile.logoUrl.trim().isEmpty ? 'Logo missing' : 'Logo URL saved',
              accent: const Color(0xFF8C56F7),
              surface: const Color(0xFFFBF7FF),
              icon: Icons.palette_outlined,
            ),
            _HeroStatCard(
              title: 'Local Build',
              value: profile.localProjectPath.trim().isEmpty ? 'Not set' : 'Ready',
              note: profile.localProjectPath.trim().isEmpty
                  ? 'Desktop build path required'
                  : 'Desktop APK build path configured',
              accent: const Color(0xFFE6A100),
              surface: const Color(0xFFFFF9E9),
              icon: Icons.developer_mode_rounded,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: const [
            _SectionTab(label: 'Clients', selected: true),
            SizedBox(width: 10),
            _SectionTab(label: 'Branding'),
            SizedBox(width: 10),
            _SectionTab(label: 'Deployment'),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search profile fields, contacts, or deployment links...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 18),
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
          title: 'Client & Billing Management',
          subtitle: 'Shape the client profile, contacts, branding, and APK delivery setup.',
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 760;
            final left = [
              _FormFieldBlock(
                label: 'Company name',
                child: TextField(
                  controller: _companyController,
                  decoration: const InputDecoration(hintText: 'Brand Slots'),
                ),
              ),
              _FormFieldBlock(
                label: 'Admin name',
                child: TextField(
                  controller: _adminController,
                  decoration: const InputDecoration(hintText: 'Super Admin'),
                ),
              ),
              _FormFieldBlock(
                label: 'Admin email',
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(hintText: 'admin@brandslots.com'),
                ),
              ),
              _FormFieldBlock(
                label: 'Phone',
                child: TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(hintText: '+91 98765 43210'),
                ),
              ),
            ];
            final right = [
              _FormFieldBlock(
                label: 'Welcome message',
                child: TextField(
                  controller: _welcomeController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Welcome to the brand network',
                  ),
                ),
              ),
              _FormFieldBlock(
                label: 'Logo URL',
                child: TextField(
                  controller: _logoController,
                  decoration: const InputDecoration(hintText: 'https://...'),
                ),
              ),
              _FormFieldBlock(
                label: 'Accent color',
                child: TextField(
                  controller: _colorController,
                  decoration: const InputDecoration(hintText: '#0F766E'),
                ),
              ),
              _FormFieldBlock(
                label: 'APK base URL',
                child: TextField(
                  controller: _apkBaseUrlController,
                  decoration: const InputDecoration(
                    hintText: 'https://github.com/OWNER/REPO/releases/download/screen-apks',
                  ),
                ),
              ),
              _FormFieldBlock(
                label: 'Local Flutter project path',
                child: TextField(
                  controller: _localProjectPathController,
                  decoration: InputDecoration(
                    hintText: 'C:\\path\\to\\app',
                    suffixIcon: IconButton(
                      onPressed: _pickLocalProjectPath,
                      icon: const Icon(Icons.folder_open_rounded),
                    ),
                  ),
                ),
              ),
            ];

            if (!wide) {
              return Column(
                children: [
                  ...left.expand((block) => [block, const SizedBox(height: 14)]),
                  ...right.expand((block) => [block, const SizedBox(height: 14)]),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      for (final block in left) ...[
                        block,
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    children: [
                      for (final block in right) ...[
                        block,
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Client Profile'),
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
          title: 'Client Preview',
          subtitle: 'A polished snapshot of the brand, rollout state, and delivery channels.',
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5B60F4), Color(0xFF6E49EE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: const Color(0x26FFFFFF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Brand Profile',
                      style: TextStyle(
                        color: Color(0xFFE8E9FF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                profile.companyName.isEmpty ? 'No Company Name' : profile.companyName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
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
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  profile.adminEmail.isEmpty
                      ? 'Admin contact not configured yet.'
                      : 'Primary contact: ${profile.adminName} • ${profile.adminEmail}',
                  style: const TextStyle(
                    color: Color(0xFFF4F5FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
          initialValue: _kind,
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
    required this.accent,
    required this.surface,
    required this.icon,
  });

  final String title;
  final String value;
  final String note;
  final Color accent;
  final Color surface;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 278,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5EBF5)),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08132038),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF60718D),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: accent, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111C32),
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
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
        border: Border.all(color: const Color(0xFFE5EBF5)),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08132038),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
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
            color: Color(0xFF111C32),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF6C7B95)),
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
        color: const Color(0xFFF9FBFF),
        border: Border.all(color: const Color(0xFFE5EBF5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.desktop_windows_rounded,
              color: Color(0xFF2F67F6),
            ),
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
                Text(
                  '${screen.location} • ${screen.assignedMediaIds.length} assigned',
                  style: const TextStyle(color: Color(0xFF73829C)),
                ),
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
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5EBF5)),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08132038),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.desktop_windows_rounded,
                  color: Color(0xFF2F67F6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  screen.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(
                label: screen.lastSeenAt == null ? 'Offline' : 'Online',
                color: screen.lastSeenAt == null
                    ? const Color(0xFFF04C5A)
                    : const Color(0xFF22B45B),
              ),
              _StatusPill(
                label: screen.playCount > 0 ? 'Playing' : 'Idle',
                color: screen.playCount > 0
                    ? const Color(0xFF2F67F6)
                    : const Color(0xFF95A2B9),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SummaryChip(label: 'Code', value: screen.loginCode),
          const SizedBox(height: 8),
          _SummaryChip(label: 'Location', value: screen.location),
          const SizedBox(height: 8),
          _SummaryChip(label: 'APK', value: screen.apkAssetFileName),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _CompactMetric(label: 'Plays', value: '${screen.playCount}'),
              ),
              Expanded(
                child: _CompactMetric(
                  label: 'Rounds',
                  value: '${screen.completedRounds}',
                ),
              ),
            ],
          ),
          Text(
            'Last seen: ${_formatTimestamp(screen.lastSeenAt)}',
            style: const TextStyle(color: Color(0xFF73829C)),
          ),
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
                    await _openExternalUrl(context, downloadUrl!);
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
        color: const Color(0xFFF7F9FE),
        border: Border.all(color: const Color(0xFFE5EBF5)),
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

class _SectionTab extends StatelessWidget {
  const _SectionTab({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? Colors.white : const Color(0xFFF0F4FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? const Color(0xFFE5EBF5) : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFF111C32) : const Color(0xFF6A7A93),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FormFieldBlock extends StatelessWidget {
  const _FormFieldBlock({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF324057),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF73829C))),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111C32),
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTag extends StatelessWidget {
  const _MetricTag({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111C32),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5EBF5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: accent.withAlpha(31),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF697A95),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF111C32),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  detail,
                  style: const TextStyle(color: Color(0xFF73829C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({required this.points});

  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final maxValue = points.reduce(math.max);
    final minValue = points.reduce(math.min);
    final range = math.max(1.0, maxValue - minValue);

    final guide = Paint()
      ..color = const Color(0xFFE4EBF7)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guide);
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height - ((points[i] - minValue) / range) * (size.height - 10);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = size.width * (i - 1) / (points.length - 1);
        final prevY = size.height -
            ((points[i - 1] - minValue) / range) * (size.height - 10);
        final controlX = (prevX + x) / 2;
        path.cubicTo(controlX, prevY, controlX, y, x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x553267F6), Color(0x113267F6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF3267F6)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points;
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
