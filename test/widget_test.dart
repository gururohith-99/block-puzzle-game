import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:block_haven/main.dart';
import 'package:block_haven/storage/storage_service.dart';
import 'package:block_haven/audio/audio_manager.dart';
import 'package:block_haven/game/state/game_provider.dart';

void main() {
  testWidgets('App launches and displays Splash Screen title', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();
    final audioManager = AudioManager();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GameProvider(
          storageService: storageService,
          audioManager: audioManager,
        ),
        child: const BlockHavenApp(),
      ),
    );

    expect(find.text('BLOCK HAVEN'), findsOneWidget);

    // Pump timer for SplashScreen navigation
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
