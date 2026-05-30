import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/storage_service.dart';
import 'services/audio_manager.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/store_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait mode for mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Hide status bar for immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize services
  final storage = StorageService();
  await storage.init();

  final audio = AudioManager(storage);

  runApp(FruitMergeApp(
    storage: storage,
    audio: audio,
  ));
}

class FruitMergeApp extends StatelessWidget {
  final StorageService storage;
  final AudioManager audio;

  const FruitMergeApp({
    super.key,
    required this.storage,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fruit Merge Puzzle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7043),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/loading',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/loading':
            return MaterialPageRoute(
              builder: (_) => const LoadingScreen(nextRoute: '/'),
            );
          case '/':
            return MaterialPageRoute(
              builder: (_) => HomeScreen(storage: storage),
            );
          case '/game':
          case '/gameplay':
            return MaterialPageRoute(
              builder: (_) => GameScreen(
                storage: storage,
                audio: audio,
              ),
            );
          case '/settings':
            return MaterialPageRoute(
              builder: (_) => SettingsScreen(
                storage: storage,
                audio: audio,
              ),
            );
          case '/store':
            return MaterialPageRoute(
              builder: (_) => StoreScreen(storage: storage),
            );
          case '/profile':
            return MaterialPageRoute(
              builder: (_) => ProfileScreen(storage: storage),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => HomeScreen(storage: storage),
            );
        }
      },
    );
  }
}
