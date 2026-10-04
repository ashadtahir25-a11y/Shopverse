import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/cloudinary_config.dart';
import '../../../core/config/firebase_config.dart';
import '../../../core/data/cloudinary_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/user_avatar.dart';
import '../providers/user_profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: profile.name);
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Lets the user choose gallery or camera, then uploads the picked
  /// photo. Previously the camera badge was purely decorative (no
  /// onTap at all) and the avatar was a random picsum.photos stock
  /// image seeded from the user id — so nothing could be selected and
  /// an unrelated picture showed instead of the user's own.
  Future<void> _chooseAvatarSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXl),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    await _pickAndUploadAvatar(source);
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    if (!CloudinaryConfig.isConfigured) {
      _showMessage('Image upload isn\u2019t set up yet.');
      return;
    }

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await cloudinaryService.uploadImageBytes(
        bytes,
        fileName: picked.name,
        folder: 'avatars',
      );

      // Save right away (not only on "Save Changes") so picking a photo
      // and leaving the screen doesn't silently discard it.
      if (FirebaseStatus.isInitialized) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'avatarUrl': url,
          });
        }
      }
      ref.read(userProfileProvider.notifier).update(avatarUrl: url);
      _showMessage('Profile photo updated');
    } catch (_) {
      _showMessage('Couldn\u2019t upload the photo. Please try again.');
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    try {
      if (FirebaseStatus.isInitialized) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          // Persist to Firestore so the change survives logout/login and
          // shows up correctly in the Firebase Console.
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'fullName': name,
            'phone': phone,
          });
        }
      }

      ref
          .read(userProfileProvider.notifier)
          .update(name: name, email: email, phone: phone);

      if (!mounted) return;
      _showMessage('Profile updated');
      context.pop();
    } catch (e) {
      _showMessage('Could not save changes. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _isUploadingAvatar ? null : _chooseAvatarSource,
                    child: Stack(
                      children: [
                        UserAvatar(
                          avatarUrl: profile.avatarUrl,
                          name: profile.name,
                          size: 96,
                        ),
                        if (_isUploadingAvatar)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.xl),
                AppTextField(
                  label: 'Full Name',
                  hint: 'Your name',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppDimens.md),
                AppTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _emailController,
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppDimens.md),
                AppTextField(
                  label: 'Phone',
                  hint: '03XX-XXXXXXX',
                  controller: _phoneController,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppDimens.xl),
                PrimaryButton(
                  label: 'Save Changes',
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
