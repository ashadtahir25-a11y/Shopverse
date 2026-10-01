/// Cloudinary credentials for uploading images (avatars, review photos,
/// and — once the admin dashboard exists in Phase 7 — product photos).
///
/// HOW TO SET THIS UP (you'll need your own free Cloudinary account):
/// 1. Sign up at https://cloudinary.com (free tier, no credit card).
/// 2. Your "Cloud Name" is shown on the Cloudinary Dashboard homepage.
/// 3. Create an UNSIGNED upload preset: Settings -> Upload -> Upload
///    presets -> Add upload preset -> Signing Mode: "Unsigned" -> Save.
///    (Unsigned presets are safe to ship in a mobile app — they can only
///    upload, never delete or modify existing assets, and Cloudinary lets
///    you restrict allowed formats/folder/size on the preset itself.)
/// 4. Run the app with both values, e.g.:
///    flutter run --dart-define=CLOUDINARY_CLOUD_NAME=your-cloud-name
///                 --dart-define=CLOUDINARY_UPLOAD_PRESET=your-preset-name
class CloudinaryConfig {
  CloudinaryConfig._();

  static const String cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'YOUR-CLOUD-NAME',
  );

  static const String uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'YOUR-UPLOAD-PRESET',
  );

  static bool get isConfigured => !cloudName.contains('YOUR-CLOUD-NAME') && !uploadPreset.contains('YOUR-UPLOAD-PRESET');
}
