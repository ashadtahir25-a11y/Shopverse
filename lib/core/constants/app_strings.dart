/// Centralized user-facing strings.
/// This indirection is what allows swapping in flutter_localizations /
/// .arb files later without touching UI code (English/Urdu per PRD section 64).
class AppStrings {
  AppStrings._();

  static const appName = 'ShopVerse';
  static const tagline = 'Shop Smart. Live Better.';

  // Onboarding
  static const onboardTitle1 = 'Discover Products';
  static const onboardDesc1 = 'Explore thousands of products across every category, curated just for you.';

  static const onboardTitle2 = 'Easy Shopping';
  static const onboardDesc2 = 'Add to cart, compare, and checkout in just a few taps — no hassle.';

  static const onboardTitle3 = 'Secure Payment';
  static const onboardDesc3 = 'Pay safely with cards, wallets, or cash on delivery. Your data stays protected.';

  static const onboardTitle4 = 'Fast Delivery';
  static const onboardDesc4 = 'Track your order in real time, from packing to your doorstep.';

  static const skip = 'Skip';
  static const next = 'Next';
  static const getStarted = 'Get Started';

  // Auth
  static const login = 'Login';
  static const createAccount = 'Create Account';
  static const welcomeBack = 'Welcome back';
  static const loginSubtitle = 'Login to continue shopping';
  static const registerTitle = 'Create your account';
  static const registerSubtitle = 'Join ShopVerse and start shopping today';
  static const fullName = 'Full Name';
  static const email = 'Email';
  static const phone = 'Phone Number';
  static const password = 'Password';
  static const confirmPassword = 'Confirm Password';
  static const forgotPassword = 'Forgot Password?';
  static const dontHaveAccount = "Don't have an account? ";
  static const alreadyHaveAccount = 'Already have an account? ';
  static const orContinueWith = 'Or continue with';
  static const rememberMe = 'Remember me';
}
