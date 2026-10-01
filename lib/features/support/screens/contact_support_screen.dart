import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../profile/providers/user_profile_provider.dart';
import '../models/ticket_model.dart';
import '../providers/support_provider.dart';

class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  ConsumerState<ContactSupportScreen> createState() =>
      _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitted = false;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final profile = ref.read(userProfileProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final ticket = SupportTicket(
      id: 'TCK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      userId: uid,
      customerName: profile.name,
      customerEmail: profile.email,
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(supportTicketsProvider.notifier).submit(ticket);
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit ticket. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Contact Support')),
      body: SafeArea(child: _submitted ? _buildSuccess(context) : _buildForm()),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How can we help?', style: AppTextStyles.h4),
            const SizedBox(height: 4),
            Text(
              'Describe your issue and our team will get back to you.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            AppTextField(
              label: 'Subject',
              hint: 'e.g. Issue with my recent order',
              controller: _subjectController,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppDimens.md),
            AppTextField(
              label: 'Message',
              hint: 'Describe your issue in detail...',
              controller: _messageController,
              maxLines: 6,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppDimens.xl),
            PrimaryButton(
              label: 'Submit Ticket',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            Text('Ticket Submitted', style: AppTextStyles.h4),
            const SizedBox(height: 6),
            Text(
              'We\u2019ll respond to your ticket within 24 hours.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimens.xl),
            PrimaryButton(
              label: 'View My Tickets',
              onPressed: () => context.pushReplacement('/help-support/tickets'),
            ),
          ],
        ),
      ),
    );
  }
}
