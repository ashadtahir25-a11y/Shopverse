import '../routes/app_router.dart';

/// When true, the intro screens (Next → Next → Get Started) are shown
/// EVERY time someone is about to log in — at app start while logged
/// out, and after tapping Logout — not just on the very first launch.
///
/// Set to false to go back to "intro only once, then straight to Login".
const bool kShowOnboardingBeforeLogin = true;

/// The screen that starts the login process.
///
/// [onboardingSeen] is only consulted when [kShowOnboardingBeforeLogin]
/// is false; logout handlers can leave it at its default because someone
/// who is logged in has necessarily been through the intro already.
String loggedOutRoute({bool onboardingSeen = true}) {
  return (kShowOnboardingBeforeLogin || !onboardingSeen)
      ? AppRoutes.onboarding
      : AppRoutes.login;
}
