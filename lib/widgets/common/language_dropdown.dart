import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class LanguageDropdown extends StatelessWidget {
  final void Function(Locale)? onLocaleChanged;
  const LanguageDropdown({super.key, this.onLocaleChanged});

  Locale _normalizeLocale(Locale locale) {
    if (locale.languageCode == 'vi') return const Locale('vi');
    if (locale.languageCode == 'en') return const Locale('en');
    return const Locale('en');
  }

  @override
  Widget build(BuildContext context) {
    final Locale current = _normalizeLocale(context.locale);

    return DropdownButtonFormField<Locale>(
      value: current,
      isDense: true,
      decoration: InputDecoration(
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: <DropdownMenuItem<Locale>>[
        DropdownMenuItem<Locale>(
          value: const Locale('vi'),
          child: Row(
            children: [
              const Text('🇻🇳', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('profile.vi'.tr()),
            ],
          ),
        ),
        DropdownMenuItem<Locale>(
          value: const Locale('en'),
          child: Row(
            children: [
              const Text('🇬🇧', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('profile.en'.tr()),
            ],
          ),
        ),
      ],
      onChanged: (Locale? locale) async {
        if (locale == null) return;
        await context.setLocale(locale);
        // Update locale in ApiErrorMapper
        ApiErrorMapper.updateLocale(locale);
        if (onLocaleChanged != null) {
          onLocaleChanged!(locale);
        }
      },
    );
  }
}


