import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_models.dart';
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
  String? _selectedClientId;
  String? _selectedScreenId;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    _syncSelections(controller);
    final isCompact = MediaQuery.of(context).size.width < 1080;
    final meta = _metaFor(_section);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: isCompact
          ? AppBar(
              backgroundColor: const Color(0xFFF4F7FB),
              surfaceTintColor: Colors.transparent,
              title: Text(meta.title),
              actions: [
                IconButton(
                  onPressed: () => _showOrganizationDialog(controller.organization),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                ),
                IconButton(
                  onPressed: controller.logout,
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            )
          : null,
      drawer: isCompact
          ? Drawer(
              child: SafeArea(
                child: _DashboardNav(
                  controller: controller,
                  selected: _section,
                  onSelected: (section) {
                    setState(() => _section = section);
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
                  width: 300,
                  child: _DashboardNav(
                    controller: controller,
                    selected: _section,
                    onSelected: (section) => setState(() => _section = section),
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
                      _PageHeader(
                        title: meta.title,
                        subtitle: meta.subtitle,
                        actions: [
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showOrganizationDialog(controller.organization),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Admin Profile'),
                          ),
                          FilledButton.icon(
                            onPressed: controller.logout,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Logout'),
                          ),
                        ],
                      ),
                    if (!isCompact) const SizedBox(height: 20),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: KeyedSubtree(
                          key: ValueKey(_section),
                          child: _buildSection(controller),
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
                  icon: Icon(Icons.dashboard_outlined),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tv_outlined),
                  label: 'Screens',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  label: 'Clients',
                ),
                NavigationDestination(
                  icon: Icon(Icons.playlist_play_rounded),
                  label: 'Player',
                ),
              ],
            )
          : null,
    );
  }

  void _syncSelections(AppController controller) {
    if (controller.clients.isEmpty) {
      _selectedClientId = null;
    } else if (_selectedClientId == null ||
        controller.getClientById(_selectedClientId!) == null) {
      _selectedClientId = controller.clients.first.id;
    }

    if (controller.screens.isEmpty) {
      _selectedScreenId = null;
    } else if (_selectedScreenId == null ||
        controller.getScreenById(_selectedScreenId!) == null) {
      _selectedScreenId = controller.screens.first.id;
    }
  }

  _SectionMeta _metaFor(_AdminSection section) {
    switch (section) {
      case _AdminSection.dashboard:
        return const _SectionMeta(
          'Dashboard',
          'Monitor clients, active screens, and media playback health.',
        );
      case _AdminSection.screens:
        return const _SectionMeta(
          'Screens',
          'Register screen players and track each device playlist status.',
        );
      case _AdminSection.clients:
        return const _SectionMeta(
          'Clients',
          'Create clients and upload the videos and photos that belong to them.',
        );
      case _AdminSection.player:
        return const _SectionMeta(
          'Screen Player',
          'Assign client media to each screen, reorder playlists, and remove items.',
        );
    }
  }

  Widget _buildSection(AppController controller) {
    switch (_section) {
      case _AdminSection.dashboard:
        return _buildDashboard(controller);
      case _AdminSection.screens:
        return _buildScreens(controller);
      case _AdminSection.clients:
        return _buildClients(controller);
      case _AdminSection.player:
        return _buildPlayer(controller);
    }
  }

  Widget _buildDashboard(AppController controller) {
    final totalMediaPlays = controller.playbackStats.fold<int>(
      0,
      (sum, item) => sum + item.playCount,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(
                title: 'Clients',
                value: '${controller.clients.length}',
                detail: 'Accounts with their own media library',
                accent: const Color(0xFF005F73),
              ),
              _StatCard(
                title: 'Uploaded Media',
                value: '${controller.mediaItems.length}',
                detail: 'Videos and photos stored in client sections',
                accent: const Color(0xFF9B2226),
              ),
              _StatCard(
                title: 'Screens',
                value: '${controller.screens.length}',
                detail: 'Registered screen players',
                accent: const Color(0xFF0A9396),
              ),
              _StatCard(
                title: 'Total Plays',
                value: '$totalMediaPlays',
                detail: 'All tracked media play events',
                accent: const Color(0xFFCA6702),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 520,
                child: _SurfacePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PanelHeading(
                        title: 'Admin Profile',
                        subtitle: 'Company and admin settings for this dashboard.',
                      ),
                      const SizedBox(height: 16),
                      _KeyValueRow(
                        label: 'Company',
                        value: controller.organization.companyName.isEmpty
                            ? 'Not set'
                            : controller.organization.companyName,
                      ),
                      _KeyValueRow(
                        label: 'Admin',
                        value: controller.organization.adminName.isEmpty
                            ? 'Not set'
                            : controller.organization.adminName,
                      ),
                      _KeyValueRow(
                        label: 'Email',
                        value: controller.organization.adminEmail.isEmpty
                            ? 'Not set'
                            : controller.organization.adminEmail,
                      ),
                      _KeyValueRow(
                        label: 'Phone',
                        value: controller.organization.phone.isEmpty
                            ? 'Not set'
                            : controller.organization.phone,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: () =>
                              _showOrganizationDialog(controller.organization),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit Admin Profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 520,
                child: _SurfacePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PanelHeading(
                        title: 'Busiest Media',
                        subtitle: 'Top assets based on tracked plays.',
                      ),
                      const SizedBox(height: 16),
                      if (controller.mediaItems.isEmpty)
                        const Text(
                          'No media uploaded yet. Start in the Clients section.',
                          style: TextStyle(color: Color(0xFF5A6B80)),
                        )
                      else
                        for (final item in _topMedia(controller))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MetricListTile(
                              title: item.title,
                              subtitle: _clientName(controller, item.clientId),
                              trailing:
                                  '${controller.totalPlaysForMedia(item.id)} plays',
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 520,
                child: _SurfacePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PanelHeading(
                        title: 'Clients Overview',
                        subtitle: 'Every client owns its own upload library.',
                      ),
                      const SizedBox(height: 16),
                      if (controller.clients.isEmpty)
                        const Text(
                          'No clients yet. Add your first client in the Clients section.',
                          style: TextStyle(color: Color(0xFF5A6B80)),
                        )
                      else
                        for (final client in controller.clients)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MetricListTile(
                              title: client.name,
                              subtitle:
                                  '${controller.mediaForClient(client.id).length} uploaded assets',
                              trailing:
                                  '${_sumClientPlays(controller, client.id)} plays',
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 520,
                child: _SurfacePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PanelHeading(
                        title: 'Screens Overview',
                        subtitle: 'Each screen has its own ordered playlist.',
                      ),
                      const SizedBox(height: 16),
                      if (controller.screens.isEmpty)
                        const Text(
                          'No screens registered yet.',
                          style: TextStyle(color: Color(0xFF5A6B80)),
                        )
                      else
                        for (final screen in controller.screens)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MetricListTile(
                              title: screen.name,
                              subtitle:
                                  '${screen.assignedMediaIds.length} items in playlist',
                              trailing: screen.lastSeenAt == null
                                  ? 'Offline'
                                  : 'Seen ${_formatTimestamp(screen.lastSeenAt)}',
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScreens(AppController controller) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Register screens and monitor device health. Playlist building happens in Screen Player.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF5A6B80),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _showAddScreenDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Screen'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (controller.screens.isEmpty)
            const _EmptyStateCard(
              title: 'No screens registered',
              subtitle: 'Add a screen to create a unique screen player account.',
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final screen in controller.screens)
                  SizedBox(
                    width: 360,
                    child: _SurfacePanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  screen.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              _OnlineBadge(online: screen.lastSeenAt != null),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _KeyValueRow(label: 'Code', value: screen.loginCode),
                          _KeyValueRow(
                            label: 'Location',
                            value:
                                screen.location.isEmpty ? 'Not set' : screen.location,
                          ),
                          _KeyValueRow(
                            label: 'Playlist',
                            value:
                                '${screen.assignedMediaIds.length} assigned items',
                          ),
                          _KeyValueRow(
                            label: 'Plays',
                            value: '${screen.playCount}',
                          ),
                          _KeyValueRow(
                            label: 'Rounds',
                            value: '${screen.completedRounds}',
                          ),
                          _KeyValueRow(
                            label: 'Last playback',
                            value: _formatTimestamp(screen.lastPlaybackAt),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _showEditScreenDialog(screen),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit'),
                              ),
                              if (controller.apkDownloadUrlForScreen(screen) != null)
                                FilledButton.tonalIcon(
                                  onPressed: () => _openUrl(
                                    controller.apkDownloadUrlForScreen(screen)!,
                                  ),
                                  icon: const Icon(Icons.download_rounded),
                                  label: const Text('APK'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildClients(AppController controller) {
    final selectedClient = _selectedClientId == null
        ? null
        : controller.getClientById(_selectedClientId!);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 320,
          child: _SurfacePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: _PanelHeading(
                        title: 'Clients',
                        subtitle: 'Create a client before any media can be uploaded.',
                      ),
                    ),
                    IconButton(
                      onPressed: _showAddClientDialog,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (controller.clients.isEmpty)
                  const _EmptyStateCard(
                    title: 'No clients yet',
                    subtitle: 'Add a client to start uploading videos and photos.',
                    compact: true,
                  )
                else
                  for (final client in controller.clients)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SelectableTile(
                        title: client.name,
                        subtitle:
                            '${controller.mediaForClient(client.id).length} media assets',
                        selected: client.id == _selectedClientId,
                        onTap: () => setState(() => _selectedClientId = client.id),
                      ),
                    ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _showAddClientDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Client'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: selectedClient == null
              ? const _EmptyStateCard(
                  title: 'Select a client',
                  subtitle: 'Pick a client on the left to upload media and review analytics.',
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SurfacePanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedClient.name,
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Only this client section can upload media for ${selectedClient.name}.',
                                        style: const TextStyle(
                                          color: Color(0xFF5A6B80),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _showEditClientDialog(selectedClient),
                                      icon: const Icon(Icons.edit_outlined),
                                      label: const Text('Edit'),
                                    ),
                                    FilledButton.icon(
                                      onPressed: () =>
                                          _showAddMediaDialog(selectedClient),
                                      icon: const Icon(Icons.upload_rounded),
                                      label: const Text('Upload Media'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 18,
                              runSpacing: 12,
                              children: [
                                _ChipSummary(
                                  label: 'Contact',
                                  value: selectedClient.contactName.isEmpty
                                      ? 'Not set'
                                      : selectedClient.contactName,
                                ),
                                _ChipSummary(
                                  label: 'Email',
                                  value: selectedClient.contactEmail.isEmpty
                                      ? 'Not set'
                                      : selectedClient.contactEmail,
                                ),
                                _ChipSummary(
                                  label: 'Phone',
                                  value: selectedClient.phone.isEmpty
                                      ? 'Not set'
                                      : selectedClient.phone,
                                ),
                                _ChipSummary(
                                  label: 'Total Plays',
                                  value:
                                      '${_sumClientPlays(controller, selectedClient.id)}',
                                ),
                              ],
                            ),
                            if (selectedClient.notes.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                selectedClient.notes,
                                style: const TextStyle(color: Color(0xFF425066)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildClientMediaList(controller, selectedClient),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildClientMediaList(
    AppController controller,
    ClientProfile client,
  ) {
    final mediaItems = controller.mediaForClient(client.id);
    if (mediaItems.isEmpty) {
      return const _EmptyStateCard(
        title: 'No media uploaded for this client',
        subtitle: 'Upload photos or videos here. These assets can then be added to screen playlists.',
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final item in mediaItems)
          SizedBox(
            width: 360,
            child: _SurfacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _KindPill(kind: item.kind),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _confirmDeleteMedia(item),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description.isEmpty ? 'No description' : item.description,
                    style: const TextStyle(color: Color(0xFF5A6B80)),
                  ),
                  const SizedBox(height: 14),
                  _KeyValueRow(
                    label: 'Duration',
                    value: item.kind == MediaKind.image
                        ? '${item.durationSeconds}s on screen'
                        : '${item.durationSeconds}s fallback duration',
                  ),
                  _KeyValueRow(
                    label: 'Total plays',
                    value: '${controller.totalPlaysForMedia(item.id)}',
                  ),
                  _KeyValueRow(
                    label: 'Used on screens',
                    value: '${_assignedScreens(controller, item.id).length}',
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Screen breakdown',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10233D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (controller.playbackForMedia(item.id).isEmpty)
                    const Text(
                      'No playback yet.',
                      style: TextStyle(color: Color(0xFF5A6B80)),
                    )
                  else
                    for (final stat in controller.playbackForMedia(item.id))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _MetricListTile(
                          title: controller.getScreenById(stat.screenId)?.name ??
                              'Unknown screen',
                          subtitle: _formatTimestamp(stat.lastPlayedAt),
                          trailing: '${stat.playCount} plays',
                        ),
                      ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlayer(AppController controller) {
    final selectedScreen = _selectedScreenId == null
        ? null
        : controller.getScreenById(_selectedScreenId!);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 320,
          child: _SurfacePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelHeading(
                  title: 'Screens',
                  subtitle: 'Each screen has its own playlist.',
                ),
                const SizedBox(height: 16),
                if (controller.screens.isEmpty)
                  const _EmptyStateCard(
                    title: 'No screens',
                    subtitle: 'Add a screen first before assigning media.',
                    compact: true,
                  )
                else
                  for (final screen in controller.screens)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SelectableTile(
                        title: screen.name,
                        subtitle:
                            '${screen.assignedMediaIds.length} playlist items',
                        selected: screen.id == _selectedScreenId,
                        onTap: () => setState(() => _selectedScreenId = screen.id),
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: selectedScreen == null
              ? const _EmptyStateCard(
                  title: 'Select a screen',
                  subtitle: 'Choose a screen to assign client media and reorder its playlist.',
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final stack = constraints.maxWidth < 900;
                    final left = _buildAvailableMediaPanel(controller, selectedScreen);
                    final right = _buildPlaylistPanel(controller, selectedScreen);
                    if (stack) {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            left,
                            const SizedBox(height: 16),
                            right,
                          ],
                        ),
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: left),
                        const SizedBox(width: 16),
                        Expanded(child: right),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAvailableMediaPanel(
    AppController controller,
    ScreenDevice screen,
  ) {
    return _SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeading(
            title: 'Available Client Media',
            subtitle: 'Add uploaded client media to ${screen.name}.',
          ),
          const SizedBox(height: 16),
          if (controller.mediaItems.isEmpty)
            const _EmptyStateCard(
              title: 'No client media available',
              subtitle: 'Upload media in the Clients section first.',
              compact: true,
            )
          else
            for (final item in controller.mediaItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MetricListTile(
                  title: item.title,
                  subtitle: _clientName(controller, item.clientId),
                  trailingWidget: FilledButton.tonal(
                    onPressed: screen.assignedMediaIds.contains(item.id)
                        ? null
                        : () => _addMediaToScreen(screen, item.id),
                    child: Text(
                      screen.assignedMediaIds.contains(item.id) ? 'Added' : 'Add',
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildPlaylistPanel(
    AppController controller,
    ScreenDevice screen,
  ) {
    final playlist = controller.mediaForScreen(screen.id);
    return _SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeading(
            title: '${screen.name} Playlist',
            subtitle: 'Reorder, remove, and review what this screen will play.',
          ),
          const SizedBox(height: 16),
          if (playlist.isEmpty)
            const _EmptyStateCard(
              title: 'Playlist is empty',
              subtitle: 'Add client media from the left panel.',
              compact: true,
            )
          else
            SizedBox(
              height: 520,
              child: ReorderableListView.builder(
                itemCount: playlist.length,
                onReorder: (oldIndex, newIndex) =>
                    _reorderPlaylist(screen, oldIndex, newIndex),
                itemBuilder: (context, index) {
                  final item = playlist[index];
                  return Container(
                    key: ValueKey(item.id),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FBFD),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFDCE3ED)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F1F1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            item.kind == MediaKind.video
                                ? Icons.videocam_outlined
                                : Icons.image_outlined,
                            color: const Color(0xFF005F73),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF10233D),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _clientName(controller, item.clientId),
                                style: const TextStyle(
                                  color: Color(0xFF5A6B80),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeMediaFromScreen(screen, item.id),
                          icon: const Icon(Icons.close_rounded),
                        ),
                        const Icon(Icons.drag_handle_rounded),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showOrganizationDialog(OrganizationProfile profile) async {
    final companyController = TextEditingController(text: profile.companyName);
    final adminController = TextEditingController(text: profile.adminName);
    final emailController = TextEditingController(text: profile.adminEmail);
    final phoneController = TextEditingController(text: profile.phone);
    final welcomeController = TextEditingController(text: profile.welcomeMessage);
    final apkBaseController = TextEditingController(text: profile.apkBaseUrl);
    final localPathController =
        TextEditingController(text: profile.localProjectPath);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Admin Profile'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DialogField(label: 'Company name', controller: companyController),
                  _DialogField(label: 'Admin name', controller: adminController),
                  _DialogField(label: 'Admin email', controller: emailController),
                  _DialogField(label: 'Phone', controller: phoneController),
                  _DialogField(
                    label: 'Welcome message',
                    controller: welcomeController,
                    maxLines: 3,
                  ),
                  _DialogField(label: 'APK base URL', controller: apkBaseController),
                  _DialogField(
                    label: 'Local project path',
                    controller: localPathController,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved != true) return;

    if (companyController.text.trim().isEmpty ||
        adminController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      _showMessage('Company, admin name, and admin email are required.');
      return;
    }

    await widget.controller.updateOrganization(
      profile.copyWith(
        companyName: companyController.text.trim(),
        adminName: adminController.text.trim(),
        adminEmail: emailController.text.trim(),
        phone: phoneController.text.trim(),
        welcomeMessage: welcomeController.text.trim(),
        apkBaseUrl: apkBaseController.text.trim(),
        localProjectPath: localPathController.text.trim(),
      ),
    );
    _showMessage('Admin profile updated.');
  }

  Future<void> _showAddScreenDialog() async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final passwordController = TextEditingController();
    final locationController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Screen'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(label: 'Screen name', controller: nameController),
              _DialogField(label: 'Login code', controller: codeController),
              _DialogField(label: 'Password', controller: passwordController),
              _DialogField(label: 'Location', controller: locationController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    if (nameController.text.trim().isEmpty ||
        codeController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      _showMessage('Screen name, login code, and password are required.');
      return;
    }

    final error = await widget.controller.addScreen(
      name: nameController.text.trim(),
      loginCode: codeController.text.trim(),
      password: passwordController.text,
      location: locationController.text.trim(),
    );

    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    _showMessage('Screen added.');
  }

  Future<void> _showEditScreenDialog(ScreenDevice screen) async {
    final nameController = TextEditingController(text: screen.name);
    final codeController = TextEditingController(text: screen.loginCode);
    final passwordController = TextEditingController(text: screen.password);
    final locationController = TextEditingController(text: screen.location);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Screen'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(label: 'Screen name', controller: nameController),
              _DialogField(label: 'Login code', controller: codeController),
              _DialogField(label: 'Password', controller: passwordController),
              _DialogField(label: 'Location', controller: locationController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    if (nameController.text.trim().isEmpty ||
        codeController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      _showMessage('Screen name, login code, and password are required.');
      return;
    }

    await widget.controller.updateScreen(
      screen.copyWith(
        name: nameController.text.trim(),
        loginCode: codeController.text.trim(),
        password: passwordController.text,
        location: locationController.text.trim(),
      ),
    );
    _showMessage('Screen updated.');
  }

  Future<void> _showAddClientDialog() async {
    final created = await _showClientForm();
    if (created == null) return;
    if (created.name.isEmpty) {
      _showMessage('Client name is required.');
      return;
    }
    await widget.controller.addClient(
      name: created.name,
      contactName: created.contactName,
      contactEmail: created.contactEmail,
      phone: created.phone,
      notes: created.notes,
    );
    _showMessage('Client added.');
  }

  Future<void> _showEditClientDialog(ClientProfile client) async {
    final updated = await _showClientForm(client: client);
    if (updated == null) return;
    if (updated.name.isEmpty) {
      _showMessage('Client name is required.');
      return;
    }
    await widget.controller.updateClient(client.copyWith(
      name: updated.name,
      contactName: updated.contactName,
      contactEmail: updated.contactEmail,
      phone: updated.phone,
      notes: updated.notes,
    ));
    _showMessage('Client updated.');
  }

  Future<_ClientDraft?> _showClientForm({ClientProfile? client}) async {
    final nameController = TextEditingController(text: client?.name ?? '');
    final contactController =
        TextEditingController(text: client?.contactName ?? '');
    final emailController =
        TextEditingController(text: client?.contactEmail ?? '');
    final phoneController = TextEditingController(text: client?.phone ?? '');
    final notesController = TextEditingController(text: client?.notes ?? '');

    return showDialog<_ClientDraft>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(client == null ? 'Add Client' : 'Edit Client'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(label: 'Client name', controller: nameController),
                _DialogField(label: 'Contact name', controller: contactController),
                _DialogField(label: 'Contact email', controller: emailController),
                _DialogField(label: 'Phone', controller: phoneController),
                _DialogField(
                  label: 'Notes',
                  controller: notesController,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (client != null)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _confirmDeleteClient(client);
              },
              child: const Text('Delete'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(
                _ClientDraft(
                  name: nameController.text.trim(),
                  contactName: contactController.text.trim(),
                  contactEmail: emailController.text.trim(),
                  phone: phoneController.text.trim(),
                  notes: notesController.text.trim(),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddMediaDialog(ClientProfile client) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final durationController = TextEditingController(text: '15');
    final urlController = TextEditingController();
    var selectedKind = MediaKind.video;
    PlatformFile? pickedFile;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Upload Media for ${client.name}'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<MediaKind>(
                    segments: const [
                      ButtonSegment(
                        value: MediaKind.video,
                        label: Text('Video'),
                        icon: Icon(Icons.videocam_outlined),
                      ),
                      ButtonSegment(
                        value: MediaKind.image,
                        label: Text('Photo'),
                        icon: Icon(Icons.image_outlined),
                      ),
                    ],
                    selected: {selectedKind},
                    onSelectionChanged: (value) {
                      setDialogState(() => selectedKind = value.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  _DialogField(label: 'Title', controller: titleController),
                  _DialogField(
                    label: 'Description',
                    controller: descriptionController,
                    maxLines: 3,
                  ),
                  _DialogField(
                    label: selectedKind == MediaKind.image
                        ? 'Display duration in seconds'
                        : 'Fallback duration in seconds',
                    controller: durationController,
                  ),
                  _DialogField(
                    label: 'External URL (optional)',
                    controller: urlController,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: selectedKind == MediaKind.video
                              ? ['mp4', 'mov', 'm4v', 'webm']
                              : ['jpg', 'jpeg', 'png', 'webp'],
                          withData: true,
                        );
                        if (result == null || result.files.isEmpty) return;
                        setDialogState(() => pickedFile = result.files.first);
                      },
                      icon: const Icon(Icons.attach_file_rounded),
                      label: Text(
                        pickedFile == null ? 'Pick File' : pickedFile!.name,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );

    if (shouldSave != true) return;

    if (titleController.text.trim().isEmpty) {
      _showMessage('Media title is required.');
      return;
    }
    if ((pickedFile?.bytes == null || pickedFile!.bytes!.isEmpty) &&
        urlController.text.trim().isEmpty) {
      _showMessage('Choose a file or provide an external URL.');
      return;
    }

    await widget.controller.addMedia(
      clientId: client.id,
      title: titleController.text.trim(),
      kind: selectedKind,
      description: descriptionController.text.trim(),
      durationSeconds: int.tryParse(durationController.text.trim()) ?? 15,
      externalUrl: urlController.text.trim().isEmpty
          ? null
          : urlController.text.trim(),
      fileBytes: pickedFile?.bytes,
      fileName: pickedFile?.name,
    );
    _showMessage('Media uploaded to ${client.name}.');
  }

  Future<void> _confirmDeleteClient(ClientProfile client) async {
    final confirmed = await _confirm(
      title: 'Delete client?',
      message:
          'Deleting ${client.name} will also remove its media, analytics, and screen assignments.',
    );
    if (confirmed != true) return;
    await widget.controller.deleteClient(client.id);
    _showMessage('Client deleted.');
  }

  Future<void> _confirmDeleteMedia(MediaItem item) async {
    final confirmed = await _confirm(
      title: 'Delete media?',
      message:
          'Deleting ${item.title} removes it from all screen playlists and analytics.',
    );
    if (confirmed != true) return;
    await widget.controller.deleteMedia(item.id);
    _showMessage('Media deleted.');
  }

  Future<void> _addMediaToScreen(ScreenDevice screen, String mediaId) async {
    if (screen.assignedMediaIds.contains(mediaId)) return;
    await widget.controller.updateScreen(
      screen.copyWith(assignedMediaIds: [...screen.assignedMediaIds, mediaId]),
    );
  }

  Future<void> _removeMediaFromScreen(ScreenDevice screen, String mediaId) async {
    await widget.controller.updateScreen(
      screen.copyWith(
        assignedMediaIds:
            screen.assignedMediaIds.where((id) => id != mediaId).toList(),
      ),
    );
  }

  Future<void> _reorderPlaylist(
    ScreenDevice screen,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final reordered = [...screen.assignedMediaIds];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    await widget.controller
        .updateScreen(screen.copyWith(assignedMediaIds: reordered));
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) {
      _showMessage('The link is invalid.');
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<MediaItem> _topMedia(AppController controller) {
    final items = [...controller.mediaItems];
    items.sort(
      (left, right) => controller
          .totalPlaysForMedia(right.id)
          .compareTo(controller.totalPlaysForMedia(left.id)),
    );
    return items.take(5).toList();
  }

  List<ScreenDevice> _assignedScreens(AppController controller, String mediaId) {
    return controller.screens
        .where((screen) => screen.assignedMediaIds.contains(mediaId))
        .toList();
  }

  int _sumClientPlays(AppController controller, String clientId) {
    var total = 0;
    for (final item in controller.mediaForClient(clientId)) {
      total += controller.totalPlaysForMedia(item.id);
    }
    return total;
  }

  String _clientName(AppController controller, String clientId) {
    return controller.getClientById(clientId)?.name ?? 'Unknown client';
  }
}

class _SectionMeta {
  const _SectionMeta(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

class _DashboardNav extends StatelessWidget {
  const _DashboardNav({
    required this.controller,
    required this.selected,
    required this.onSelected,
  });

  final AppController controller;
  final _AdminSection selected;
  final ValueChanged<_AdminSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final organization = controller.organization;
    final items = [
      (_AdminSection.dashboard, Icons.dashboard_outlined, 'Dashboard'),
      (_AdminSection.screens, Icons.tv_outlined, 'Screens'),
      (_AdminSection.clients, Icons.groups_outlined, 'Clients'),
      (_AdminSection.player, Icons.playlist_play_rounded, 'Screen Player'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFDCE3ED)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF005F73), Color(0xFF0A9396)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ad Master',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  organization.companyName.isEmpty
                      ? 'Client media control center'
                      : organization.companyName,
                  style: const TextStyle(color: Color(0xFFE3FBFC)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _NavButton(
                icon: item.$2,
                label: item.$3,
                selected: selected == item.$1,
                onTap: () => onSelected(item.$1),
              ),
            ),
          const Spacer(),
          _InfoBlock(
            title: organization.adminName.isEmpty
                ? 'Admin'
                : organization.adminName,
            subtitle: organization.adminEmail.isEmpty
                ? controller.backendLabel
                : organization.adminEmail,
          ),
          const SizedBox(height: 12),
          _InfoBlock(
            title: '${controller.screens.length} screens',
            subtitle:
                '${controller.clients.length} clients / ${controller.mediaItems.length} assets',
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF10233D),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF5A6B80), fontSize: 16),
              ),
            ],
          ),
        ),
        Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    );
  }
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFDCE3ED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C10233D),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PanelHeading extends StatelessWidget {
  const _PanelHeading({required this.title, required this.subtitle});

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
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF10233D),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF5A6B80)),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.accent,
  });

  final String title;
  final String value;
  final String detail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE3ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF5A6B80))),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(detail, style: const TextStyle(color: Color(0xFF5A6B80))),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5A6B80),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF10233D),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricListTile extends StatelessWidget {
  const _MetricListTile({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.trailingWidget,
  });

  final String title;
  final String subtitle;
  final String? trailing;
  final Widget? trailingWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE3ED)),
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
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10233D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF5A6B80)),
                ),
              ],
            ),
          ),
          if (trailingWidget != null) trailingWidget!,
          if (trailingWidget == null && trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                color: Color(0xFF10233D),
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE6F6F6) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10233D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF5A6B80)),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: Color(0xFF0A9396)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE3ED)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: compact ? 34 : 42,
            color: const Color(0xFF7B8CA2),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF10233D),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF5A6B80)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ChipSummary extends StatelessWidget {
  const _ChipSummary({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Color(0xFF10233D)),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _KindPill extends StatelessWidget {
  const _KindPill({required this.kind});

  final MediaKind kind;

  @override
  Widget build(BuildContext context) {
    final isVideo = kind == MediaKind.video;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isVideo ? const Color(0xFFFFF4E8) : const Color(0xFFEAF8F8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isVideo ? 'Video' : 'Photo',
        style: TextStyle(
          color: isVideo ? const Color(0xFFCA6702) : const Color(0xFF005F73),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
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
      color: selected ? const Color(0xFFE6F6F6) : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? const Color(0xFF005F73) : const Color(0xFF6E8097),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF005F73)
                        : const Color(0xFF10233D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE3ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF10233D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF5A6B80)),
          ),
        ],
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: online ? const Color(0xFFE8FAEF) : const Color(0xFFFBECEE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        online ? 'Online' : 'Offline',
        style: TextStyle(
          color: online ? const Color(0xFF1F8A4D) : const Color(0xFFB42318),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ClientDraft {
  const _ClientDraft({
    required this.name,
    required this.contactName,
    required this.contactEmail,
    required this.phone,
    required this.notes,
  });

  final String name;
  final String contactName;
  final String contactEmail;
  final String phone;
  final String notes;
}

String _formatTimestamp(String? value) {
  if (value == null || value.isEmpty) return 'Never';
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return value;
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$month/$day/${date.year} $hour:$minute';
}
