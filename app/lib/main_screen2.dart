import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/repository_factory.dart';
import 'state/app_controller.dart';
import 'screens/screen_player_page.dart';
import 'supabase_options.dart';
import 'ui/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseOptions.url,
    anonKey: SupabaseOptions.anonKey,
  );
  final controller = AppController(RepositoryFactory.createSupabase());
  runApp(Screen2App(controller: controller));
}

class Screen2App extends StatefulWidget {
  const Screen2App({super.key, required this.controller});
  final AppController controller;

  @override
  State<Screen2App> createState() => _Screen2AppState();
}

class _Screen2AppState extends State<Screen2App> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await widget.controller.initialize();
    await widget.controller.loginScreen('screen2', '1234');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Screen 2',
      theme: buildAppTheme(),
      home: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (!widget.controller.isReady) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }
          return ScreenPlayerPage(controller: widget.controller);
        },
      ),
    );
  }
}
