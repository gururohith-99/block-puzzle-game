import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'audio/audio_manager.dart';
import 'core/constants/game_constants.dart';
import 'core/theme/app_theme.dart';
import 'game/state/game_provider.dart';
import 'screens/splash_screen.dart';
import 'storage/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait mode for mobile game experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final storageService = await StorageService.init();
  final audioManager = AudioManager();

  runApp(
    ChangeNotifierProvider(
      create: (_) => GameProvider(
        storageService: storageService,
        audioManager: audioManager,
      ),
      child: const BlockHavenApp(),
    ),
  );
}

class BlockHavenApp extends StatelessWidget {
  const BlockHavenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();

    ThemeMode mode;
    if (gameProvider.themeMode == 'light') {
      mode = ThemeMode.light;
    } else {
      mode = ThemeMode.dark;
    }

    return MaterialApp(
      title: GameConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      home: const SplashScreen(),
    );
  }
}
