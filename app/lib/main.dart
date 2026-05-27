import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/admin_dashboard_page.dart';
import 'screens/admin_login_page.dart';
import 'screens/landing_page.dart';
import 'screens/screen_login_page.dart';
import 'screens/screen_player_page.dart';
import 'services/repository_factory.dart';
import 'state/app_controller.dart';
import 'supabase_options.dart';
import 'ui/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Always initialize Supabase for TV functionality
  await Supabase.initialize(
    url: SupabaseOptions.url,
    anonKey: SupabaseOptions.anonKey,
  );
  
  final controller = AppController(RepositoryFactory.createSupabase());
  runApp(AdMasterApp(controller: controller));
}

enum RouteStep { landing, admin, screen }

class AdMasterApp extends StatefulWidget {
  const AdMasterApp({super.key, required this.controller});

  final AppController controller;

  @override
  State<AdMasterApp> createState() => _AdMasterAppState();
}

class _AdMasterAppState extends State<AdMasterApp> {
  RouteStep _routeStep = RouteStep.landing;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChange);
    widget.controller.initialize();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ad Master Flutter',
      theme: buildAppTheme(),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    final controller = widget.controller;

    if (!controller.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (controller.sessionMode == SessionMode.admin) {
      return AdminDashboardPage(controller: controller);
    }

    if (controller.sessionMode == SessionMode.screen) {
      return ScreenPlayerPage(controller: controller);
    }

    switch (_routeStep) {
      case RouteStep.admin:
        return AdminLoginPage(
          controller: controller,
          onBack: () => setState(() => _routeStep = RouteStep.landing),
        );
      case RouteStep.screen:
        return ScreenLoginPage(
          controller: controller,
          onBack: () => setState(() => _routeStep = RouteStep.landing),
        );
      case RouteStep.landing:
        return LandingPage(
          hasAdmin: controller.hasAdmin,
          backendLabel: controller.backendLabel,
          onAdminSelected: () => setState(() => _routeStep = RouteStep.admin),
          onScreenSelected: () => setState(() => _routeStep = RouteStep.screen),
        );
    }
  }
}
