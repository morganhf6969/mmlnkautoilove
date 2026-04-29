import 'dart:io';
import 'package:flutter/material.dart';
import 'package:memolink/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/routes.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    if (_dontShowAgain) {
      await prefs.setBool('onboarding_completed', true);
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        4,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? Colors.blue
                : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _step(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Text(
              "$number",
              style: const TextStyle(
                  color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 16)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = Platform.isAndroid;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),

            SizedBox(
              height: 200,
              child: Image.asset(
                'assets/app_icon.png',
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "MemoLink",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 30),

            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  // SLIDE 1
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          loc.onboardingSlide1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),

                  // SLIDE 2
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text(
                            isAndroid
                                ? loc.onboardingSlide2Android
                                : loc.onboardingSlide2iOS,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (isAndroid) ...[
                            _step(1, loc.onboardingStep6Android),
                            _step(2, loc.onboardingStep7Android),
                            _step(3, loc.onboardingStep8Android),
                            _step(4, loc.onboardingStep9Android),
                            _step(5, loc.onboardingStep10Android),
                          ] else ...[
                            _step(1, loc.onboardingStep6iOS),
                            _step(2, loc.onboardingStep7iOS),
                            _step(3, loc.onboardingStep8iOS),
                            _step(4, loc.onboardingStep9iOS),
                            _step(5, loc.onboardingStep10iOS),
                            _step(6, loc.onboardingStep11iOS),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // SLIDE 3 — Condividi & Nascondi
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              loc.onboardingSlide4Title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            loc.onboardingSlide4ShareLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _step(1, loc.onboardingSlide4ShareStep1),
                          _step(2, loc.onboardingSlide4ShareStep2),
                          _step(3, loc.onboardingSlide4ShareStep3),
                          _step(4, loc.onboardingSlide4ShareStep4),
                          const SizedBox(height: 20),
                          Text(
                            loc.onboardingSlide4HideLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _step(1, loc.onboardingSlide4HideStep1),
                          _step(2, loc.onboardingSlide4HideStep2),
                          _step(3, loc.onboardingSlide4HideStep3),
                          _step(4, loc.onboardingSlide4HideStep4),
                          _step(5, loc.onboardingSlide4HideStep5),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // SLIDE 4
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          loc.onboardingSlide3Title,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          loc.onboardingSlide3Message,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Checkbox(
                              value: _dontShowAgain,
                              onChanged: (val) {
                                setState(() {
                                  _dontShowAgain = val ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(loc.dontShowAgain),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            onPressed: _finish,
                            child: Text(loc.start),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            _buildDots(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
