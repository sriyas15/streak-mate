import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../shared/widgets/custom_avatar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String? _nameError;
  String? _usernameError;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameCtrl.text = user?.name ?? '';
    _usernameCtrl.text = user?.username ?? '';
    _bioCtrl.text = user?.bio ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _nameError = Validators.name(_nameCtrl.text);
      _usernameError = Validators.username(_usernameCtrl.text);
    });
    return _nameError == null && _usernameError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final success = await ref.read(userProfileProvider.notifier).updateProfile(
          name: _nameCtrl.text.trim(),
          username: _usernameCtrl.text.trim().toLowerCase(),
          bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        );
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProfileProvider);
    final user = ref.watch(authProvider).user;

    ref.listen<UserProfileState>(userProfileProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.danger),
        );
        ref.read(userProfileProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.darkTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile',
            style: TextStyle(
                color: AppColors.darkTextPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: state.saving ? null : _save,
            child: state.saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.flameOrange))
                : const Text('Save',
                    style: TextStyle(
                        color: AppColors.flameOrange,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Avatar section ─────────────────────────────────
            Center(
              child: Stack(
                children: [
                  CustomAvatar(
                    url: user?.profilePicture,
                    name: user?.name ?? '',
                    size: 88,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.flameOrange,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.darkBg, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 15, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Change photo',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.flameOrange.withOpacity(0.8))),
            const SizedBox(height: 28),

            // ── Fields ─────────────────────────────────────────
            _Field(
              label: 'FULL NAME',
              controller: _nameCtrl,
              errorText: _nameError,
              icon: Icons.person_outline_rounded,
              onChanged: (_) {
                setState(() => _dirty = true);
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 16),
            _Field(
              label: 'USERNAME',
              controller: _usernameCtrl,
              errorText: _usernameError,
              icon: Icons.alternate_email_rounded,
              prefix: '@',
              onChanged: (_) {
                setState(() => _dirty = true);
                if (_usernameError != null) setState(() => _usernameError = null);
              },
            ),
            const SizedBox(height: 16),
            _Field(
              label: 'BIO',
              controller: _bioCtrl,
              icon: Icons.edit_note_rounded,
              maxLines: 3,
              hint: 'Building better habits...',
              onChanged: (_) => setState(() => _dirty = true),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_bioCtrl.text.length}/150',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.darkTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url, String name) {
    final initials = () {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      return name.isNotEmpty ? name[0].toUpperCase() : '?';
    }();

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.flameOrange.withOpacity(0.8),
            AppColors.xpGold.withOpacity(0.8),
          ],
        ),
        border: Border.all(color: AppColors.flameOrange, width: 2),
      ),
      child: url != null && url.isNotEmpty
          ? ClipOval(child: Image.network(url, fit: BoxFit.cover))
          : Center(
              child: Text(initials,
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.errorText,
    this.maxLines = 1,
    this.hint,
    this.prefix,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? errorText;
  final int maxLines;
  final String? hint;
  final String? prefix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.darkTextSecondary,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError
                  ? AppColors.danger
                  : AppColors.darkBorder,
              width: hasError ? 1.2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            onChanged: onChanged,
            style: const TextStyle(
                color: AppColors.darkTextPrimary, fontSize: 14),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              prefixIcon: Icon(icon,
                  size: 18, color: AppColors.darkTextSecondary),
              prefixText: prefix,
              prefixStyle: const TextStyle(color: AppColors.darkTextSecondary),
              hintText: hint,
              hintStyle: const TextStyle(
                  color: AppColors.darkTextSecondary, fontSize: 13),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(errorText!,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.danger)),
        ],
      ],
    );
  }
}