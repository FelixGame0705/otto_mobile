import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/services/storage_service.dart';
import 'package:ottobit/utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<_OnbItem> _items = const [
    _OnbItem(
      titleKey: 'onb.title1',
      descKey: 'onb.desc1',
      imageAsset: 'assets/images/robot-4.png',
    ),
    _OnbItem(
      titleKey: 'onb.title2',
      descKey: 'onb.desc2',
      imageAsset: 'assets/images/IconOttobit.png',
    ),
    _OnbItem(
      titleKey: 'onb.title3',
      descKey: 'onb.desc3',
      imageAsset: 'assets/images/LogoOttobit.png',
    ),
  ];

  Future<void> _finish() async {
    await StorageService.saveValue(AppConstants.onboardingSeenKey, true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDFCF2),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text('common.skip'.tr()),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _items.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final it = _items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 220,
                          child: Image.asset(
                            it.imageAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 120),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          it.titleKey.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF2D3748)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          it.descKey.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Color(0xFF718096)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _items.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.all(4),
                  width: _index == i ? 16 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _index == i ? const Color(0xFF00ba4a) : const Color(0xFFCBD5E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_index < _items.length - 1) {
                      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    } else {
                      _finish();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ba4a),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(_index < _items.length - 1 ? 'common.next'.tr() : 'common.getStarted'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _OnbItem {
  final String titleKey;
  final String descKey;
  final String imageAsset;
  const _OnbItem({required this.titleKey, required this.descKey, required this.imageAsset});
}


