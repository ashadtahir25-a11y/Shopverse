import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLanguageKey = 'app_language';

enum AppLanguage { english, urdu }

extension AppLanguageX on AppLanguage {
  String get label => this == AppLanguage.english ? 'English' : 'اردو (Urdu)';
  Locale get locale => this == AppLanguage.english ? const Locale('en') : const Locale('ur');
  TextDirection get textDirection => this == AppLanguage.urdu ? TextDirection.rtl : TextDirection.ltr;
}

class AppLanguageNotifier extends StateNotifier<AppLanguage> {
  AppLanguageNotifier() : super(AppLanguage.english) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLanguageKey);
    state = saved == 'ur' ? AppLanguage.urdu : AppLanguage.english;
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageKey, language == AppLanguage.urdu ? 'ur' : 'en');
  }
}

final appLanguageProvider = StateNotifierProvider<AppLanguageNotifier, AppLanguage>((ref) => AppLanguageNotifier());
