import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../providers/music_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo
              Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1E1E1E),
                    image: DecorationImage(
                      image: AssetImage(
                          'assets/images/android/main_screen_logo.png'),
                      fit: BoxFit.cover,
                    )),
              ),
              const SizedBox(height: 40),
              // Title
              const Text(
                'Welcome to SoulSound',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              // Subtitle
              Text(
                'Experience your music like never before. \nOffline, premium, and powerful.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                  height: 1.5,
                ),
              ),
              const Spacer(),
              // Features
              _buildFeatureItem(Icons.music_note, 'Crystal Clear Audio'),
              const SizedBox(height: 12),
              _buildFeatureItem(Icons.offline_bolt, 'Offline Playback'),
              const SizedBox(height: 12),
              _buildFeatureItem(Icons.graphic_eq, 'Powerful Equalizer'),
              const Spacer(),
              // Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.deepPurpleAccent, size: 20),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.grey[300], fontSize: 14)),
      ],
    );
  }

  Future<void> _handleGetStarted() async {
    setState(() => _isLoading = true);

    // 1. Request Permissions
    await _requestPermissions();

    // 2. Initial Scan (attempt)
    // We check if permission actually granted implicitly by calling scan
    await ref.read(scanProvider.notifier).scan();

    // 3. Mark as Seen
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;

    // 4. Navigate
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _requestPermissions() async {
    // We request broad permissions. The scan() method also does checks,
    // but explicit request here improves UX flow.

    // Using a map to request multiple for efficiency
    await [
      Permission.audio,
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

    // We don't block navigation if denied.
    // The user has "seen" onboarding.
    // Inside the app, proper "Permission Denied" states will handle re-requests.
  }
}
