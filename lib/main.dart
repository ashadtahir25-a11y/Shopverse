import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/config/firebase_config.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Attempts to connect to Firebase. Until `flutterfire configure` has been
  // run for every platform you test on (see firebase/FIREBASE_SETUP.md),
  // this will throw for that platform — in that case we simply keep
  // running on local/mock data so nothing breaks during development.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseStatus.isInitialized = true;
  } catch (_) {
    FirebaseStatus.isInitialized = false;
  }

  runApp(const ProviderScope(child: ShopVerseApp()));
}

class ShopVerseApp extends ConsumerWidget {
  const ShopVerseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    GoogleFonts.config.allowRuntimeFetching = true;

    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(appLanguageProvider);

    return MaterialApp.router(
      title: 'ShopVerse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        // Applies RTL layout when Urdu is selected (PRD §64: multi-language
        // architecture). Full string translation is a separate, larger
        // localization pass — this wires the toggle to a real, visible
        // layout change today.
        return _ThemeSync(
          isDark: Theme.of(context).brightness == Brightness.dark,
          child: Directionality(
            textDirection: language.textDirection,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// Keeps [AppColors] in step with the active theme.
///
/// The neutral colours (surface, text, border...) are read through
/// `AppColors`, which has no BuildContext — so it needs to be told whether
/// dark mode is on. This widget does that BEFORE its children build. When
/// the mode flips (user picks Dark, or the phone switches while on "Match
/// System"), widgets that never look at the Theme would otherwise keep their
/// old colours, so every element is marked dirty once to repaint the whole
/// tree. State and navigation are untouched (same as a hot reload).
class _ThemeSync extends StatefulWidget {
  final bool isDark;
  final Widget child;
  const _ThemeSync({required this.isDark, required this.child});

  @override
  State<_ThemeSync> createState() => _ThemeSyncState();
}

class _ThemeSyncState extends State<_ThemeSync> {
  @override
  void didUpdateWidget(covariant _ThemeSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        void rebuild(Element element) {
          element.markNeedsBuild();
          element.visitChildren(rebuild);
        }

        (context as Element).visitChildren(rebuild);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppColors.isDark = widget.isDark;
    return widget.child;
  }
}
