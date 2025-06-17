import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:retrowave/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _onIntroEnd(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MusicHomePage()));
  }

  Widget _buildPageContent({
    required String lottieAsset,
    required String title,
    required String body,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          height: 450, // fix height for Lottie animation
          child: Lottie.asset(lottieAsset, fit: BoxFit.contain),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: IntroductionScreen(
          globalBackgroundColor: Colors.white,
          pages: [
            PageViewModel(
              titleWidget:
                  const SizedBox.shrink(), // We are using bodyWidget only
              bodyWidget: _buildPageContent(
                lottieAsset: 'assets/lottie/music_wave.json',
                title: "Welcome to MELO",
                body: "Your personal music companion with soul & rhythm.",
              ),
              decoration: const PageDecoration(pageColor: Colors.transparent),
            ),
            PageViewModel(
              titleWidget: const SizedBox.shrink(),
              bodyWidget: _buildPageContent(
                lottieAsset: 'assets/lottie/playlist_animation.json',
                title: "Favorites & Playlists",
                body:
                    "Create your vibe with custom playlists & heart your favourites.",
              ),
              decoration: const PageDecoration(pageColor: Colors.transparent),
            ),
            PageViewModel(
              titleWidget: const SizedBox.shrink(),
              bodyWidget: _buildPageContent(
                lottieAsset: 'assets/lottie/sleep_timer.json',
                title: "Sleep Timer",
                body: "Set a timer, sleep tight — MELO fades out with you.",
              ),
              decoration: const PageDecoration(pageColor: Colors.transparent),
            ),
          ],
          onDone: () => _onIntroEnd(context),
          showSkipButton: true,
          skip: Text(
            "Skip",
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          next: Icon(Icons.arrow_forward_ios, color: Colors.grey[800]),
          done: Text(
            "Get Started",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
          dotsDecorator: DotsDecorator(
            activeColor: Colors.black87,
            color: Colors.grey.shade400,
            size: const Size(8.0, 8.0),
            activeSize: const Size(20.0, 8.0),
            activeShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          curve: Curves.easeInOut,
        ),
      ),
    );
  }
}
