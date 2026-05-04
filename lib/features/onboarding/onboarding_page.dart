import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/routes.dart';
import '../../l10n/app_localizations.dart';

class OnboardingPage extends StatefulWidget {
  /// [isGuide] = true quando aperta dalle Impostazioni (guida manuale).
  /// [isGuide] = false (default) quando è il flusso di primo avvio.
  final bool isGuide;

  const OnboardingPage({super.key, this.isGuide = false});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;

  static const int _totalPages = 4;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    if (_dontShowAgain) {
      await prefs.setBool('onboarding_completed', true);
    }
    if (!mounted) return;
    if (widget.isGuide) {
      // Aperta dalle Impostazioni: torna indietro
      Navigator.of(context).pop();
    } else {
      // Primo avvio: vai alla home sostituendo lo stack
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _totalPages,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? Colors.blue : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _step(int number, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: (color ?? Colors.blue).withOpacity(0.12),
            child: Text(
              '$number',
              style: TextStyle(
                  color: color ?? Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text, style: const TextStyle(fontSize: 14.5, height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, {Color color = Colors.blue}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _infoBox(String text, {IconData icon = Icons.info_outline, Color color = Colors.blue}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: color.withOpacity(0.9), height: 1.4)),
          ),
        ],
      ),
    );
  }

  // ─── SLIDE 1 ─── Salvare un link ────────────────────────────────────────────
  Widget _buildSlide1() {
    final loc = AppLocalizations.of(context)!;
    final isAndroid = Platform.isAndroid;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Text(loc.guideSlide1Title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),

            // Metodo manuale
            _sectionLabel(loc.guideManualMethodLabel, color: Colors.black87),
            _step(1, loc.guideSlide1Step1),
            _step(2, loc.guideSlide1Step2),
            _step(3, loc.guideSlide1Step3),
            _step(4, loc.guideSlide1Step4),
            _step(5, loc.guideSlide1Step5),
            _step(6, loc.guideSlide1Step6),

            const SizedBox(height: 20),

            // Metodo condivisione
            _sectionLabel(
              isAndroid ? loc.guideShareAndroidLabel : loc.guideShareiOSLabel,
              color: Colors.green,
            ),
            if (isAndroid) ...[
              _step(1, loc.guideSlide1AndroidStep1, color: Colors.green),
              _step(2, loc.guideSlide1AndroidStep2, color: Colors.green),
              _step(3, loc.guideSlide1AndroidStep3, color: Colors.green),
              _step(4, loc.guideSlide1AndroidStep4, color: Colors.green),
              _step(5, loc.guideSlide1AndroidStep5, color: Colors.green),
              const SizedBox(height: 10),
              _infoBox(
                loc.guideSlide1AndroidInfo,
                icon: Icons.android,
                color: Colors.green,
              ),
            ] else ...[
              _step(1, loc.guideSlide1iOSStep1, color: Colors.green),
              _step(2, loc.guideSlide1iOSStep2, color: Colors.green),
              _step(3, loc.guideSlide1iOSStep3, color: Colors.green),
              _step(4, loc.guideSlide1iOSStep4, color: Colors.green),
              _step(5, loc.guideSlide1iOSStep5, color: Colors.green),
              _step(6, loc.guideSlide1iOSStep6, color: Colors.green),
              const SizedBox(height: 10),
              _infoBox(
                loc.guideSlide1iOSInfo,
                icon: Icons.phone_iphone,
                color: Colors.green,
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── SLIDE 2 ─── Archivio file ───────────────────────────────────────────
  Widget _buildSlide2() {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Text(loc.guideSlide2Title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                loc.guideSlide2Subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 20),

            _sectionLabel(loc.guideArchiveHowLabel),
            _step(1, loc.guideSlide2Step1),
            _step(2, loc.guideSlide2Step2),
            _step(3, loc.guideSlide2Step3),
            _step(4, loc.guideSlide2Step4),
            _step(5, loc.guideSlide2Step5),
            _step(6, loc.guideSlide2Step6),

            const SizedBox(height: 16),

            _sectionLabel(loc.guideFormatsLabel, color: Colors.blueGrey),
            Text(
              loc.guideFormatsText,
              style: const TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.5),
            ),

            const SizedBox(height: 20),

            // Box spiegazione copia vs link
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.folder_copy_outlined, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(loc.guideCopyBoxTitle,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.amber)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.guideCopyBoxText,
                    style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _infoBox(
              loc.guideOpenFileInfo,
              icon: Icons.touch_app_outlined,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── SLIDE 3 ─── Organizzazione ─────────────────────────────────────────
  Widget _buildSlide3() {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Text(loc.guideSlide3Title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),

            _sectionLabel(loc.guideCategoriesLabel),
            _step(1, loc.guideSlide3CatStep1),
            _step(2, loc.guideSlide3CatStep2),
            _step(3, loc.guideSlide3CatStep3),
            _step(4, loc.guideSlide3CatStep4),

            const SizedBox(height: 16),

            _sectionLabel(loc.guideHashtagLabel, color: Colors.blue),
            _step(1, loc.guideSlide3HashStep1, color: Colors.blue),
            _step(2, loc.guideSlide3HashStep2, color: Colors.blue),
            _step(3, loc.guideSlide3HashStep3, color: Colors.blue),
            _step(4, loc.guideSlide3HashStep4, color: Colors.blue),

            const SizedBox(height: 16),

            _sectionLabel(loc.guideSearchSectionLabel, color: Colors.purple),
            _step(1, loc.guideSlide3SearchStep1, color: Colors.purple),
            _step(2, loc.guideSlide3SearchStep2, color: Colors.purple),
            _step(3, loc.guideSlide3SearchStep3, color: Colors.purple),

            const SizedBox(height: 16),

            _sectionLabel(loc.guideHideShareLabel, color: Colors.grey.shade700),
            _step(1, loc.guideSlide3HideStep1, color: Colors.grey.shade700),
            _step(2, loc.guideSlide3HideStep2, color: Colors.grey.shade700),
            _step(3, loc.guideSlide3HideStep3, color: Colors.grey.shade700),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── SLIDE 4 ─── Consigli finali ────────────────────────────────────────
  Widget _buildSlide4() {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(loc.guideSlide4Title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          _infoBox(
            loc.guideSlide4Tip1,
            icon: Icons.tag,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _infoBox(
            loc.guideSlide4Tip2,
            icon: Icons.stars_rounded,
            color: Colors.amber.shade800,
          ),
          const SizedBox(height: 12),
          _infoBox(
            loc.guideSlide4Tip3,
            icon: Icons.backup_outlined,
            color: Colors.green,
          ),

          const SizedBox(height: 32),

          Row(
            children: [
              Checkbox(
                value: _dontShowAgain,
                onChanged: (val) {
                  setState(() => _dontShowAgain = val ?? false);
                },
              ),
              Expanded(
                child: Text(loc.dontShowAgain,
                    style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _finish,
              child: Text(loc.guideStartButton,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Image.asset('assets/app_icon.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MemoLink',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(loc.helpGuideTitle,
                          style: const TextStyle(fontSize: 13, color: Colors.black45)),
                    ],
                  ),
                  const Spacer(),
                  // Freccia avanti (tranne ultima slide)
                  if (_currentPage < _totalPages - 1)
                    TextButton(
                      onPressed: _nextPage,
                      child: Text(loc.guideNext,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 0),
            const SizedBox(height: 8),

            // Dots
            _buildDots(),
            const SizedBox(height: 12),

            // PageView
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildSlide1(),
                  _buildSlide2(),
                  _buildSlide3(),
                  _buildSlide4(),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
