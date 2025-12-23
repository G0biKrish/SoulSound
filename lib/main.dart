import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/screens/onboarding_screen.dart';
// implicitly used
import 'data/models/playlist_model.dart';
import 'data/models/song_model.dart';
import 'data/repositories/music_repository_impl.dart';
import 'data/services/metadata_scanner.dart';
import 'core/audio/audio_handler.dart';
import 'domain/repositories/music_repository.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/providers/theme_providers.dart';
import 'core/theme/app_theme.dart';

// Dependency Injection via Riverpod
late AudioHandler _audioHandler;
late Isar _isar;

final audioHandlerProvider = Provider<AudioHandler>((ref) => _audioHandler);
final isarProvider = Provider<Isar>((ref) => _isar);
final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return MusicRepositoryImpl(isar, MetadataScanner());
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Isar
  final dir = await getApplicationDocumentsDirectory();
  _isar = await Isar.open([
    SongModelSchema,
    PlaylistModelSchema,
  ], directory: dir.path);

  // 2. Initialize Audio Service
  // We need to create the repository instance early to pass it to the handler
  final musicRepository = MusicRepositoryImpl(_isar, MetadataScanner());

  _audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(musicRepository),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.soundflow.channel.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
    ),
  );

  // 3. Check Onboarding
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = !(prefs.getBool('hasSeenOnboarding') ?? false);

  runApp(ProviderScope(child: SoundFlowApp(showOnboarding: showOnboarding)));
}

class SoundFlowApp extends ConsumerWidget {
  final bool showOnboarding;
  const SoundFlowApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final theme = buildThemeData(themeState);

    return MaterialApp(
      title: 'SoulSound',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.system,
      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}
