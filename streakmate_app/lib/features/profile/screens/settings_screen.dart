import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_profile_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(userProfileProvider.notifier).loadSettings();
      final s = ref.read(userProfileProvider).settings;
      if (mounted) {
        setState(() {
          _notificationsEnabled = s['notificationsEnabled'] as bool? ?? true;
          _soundEnabled = s['reminderSoundEnabled'] as bool? ?? true;
          _loaded = true;
        });
      }
    });
  }

  Future<void> _saveSettings() async {
    await ref.read(userProfileProvider.notifier).updateSettings({
      'notificationsEnabled': _notificationsEnabled,
      'reminderSoundEnabled': _soundEnabled,
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    final user = ref.watch(authProvider).user;

    ref.listen<UserProfileState>(userProfileProvider, (_, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(userProfileProvider.notifier).clearMessages();
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(next.error!),
              backgroundColor: AppColors.danger),
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
        title: const Text('Settings',
            style: TextStyle(
                color: AppColors.darkTextPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
      ),
      body: !_loaded && profileState.loadingSettings
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.flameOrange))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                // ── Account ──────────────────────────────────────
                _SectionLabel(label: 'ACCOUNT'),
                _SettingsCard(children: [
                  _InfoRow(
                      label: 'Name',
                      value: user?.name ?? ''),
                  const _Div(),
                  _InfoRow(
                      label: 'Username',
                      value: '@${user?.username ?? ''}'),
                  const _Div(),
                  _InfoRow(
                      label: 'Email', value: user?.email ?? ''),
                  const _Div(),
                  _InfoRow(
                      label: 'Timezone',
                      value: user?.timezone ?? 'Asia/Kolkata'),
                ]),
                const SizedBox(height: 20),

                // ── Notifications ─────────────────────────────────
                _SectionLabel(label: 'NOTIFICATIONS'),
                _SettingsCard(children: [
                  _ToggleRow(
                    icon: Icons.notifications_outlined,
                    label: 'Push notifications',
                    subtitle: 'Reminders, streaks, milestones',
                    value: _notificationsEnabled,
                    color: AppColors.flameOrange,
                    onChanged: (v) {
                      setState(() => _notificationsEnabled = v);
                      _saveSettings();
                    },
                  ),
                  const _Div(),
                  _ToggleRow(
                    icon: Icons.volume_up_outlined,
                    label: 'Reminder sound',
                    subtitle: 'Play sound with reminders',
                    value: _soundEnabled,
                    color: AppColors.prayerPurple,
                    onChanged: (v) {
                      setState(() => _soundEnabled = v);
                      _saveSettings();
                    },
                  ),
                ]),
                const SizedBox(height: 20),

                // ── App ───────────────────────────────────────────
                _SectionLabel(label: 'APP'),
                _SettingsCard(children: [
                  _NavRow(
                    icon: Icons.info_outline_rounded,
                    label: 'App version',
                    trailing: 'v1.0.0',
                    onTap: () {},
                  ),
                  const _Div(),
                  _NavRow(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy policy',
                    onTap: () {},
                  ),
                  const _Div(),
                  _NavRow(
                    icon: Icons.description_outlined,
                    label: 'Terms of service',
                    onTap: () {},
                  ),
                ]),
                const SizedBox(height: 20),

                // ── Danger zone ───────────────────────────────────
                _SectionLabel(label: 'DANGER ZONE'),
                _SettingsCard(children: [
                  _NavRow(
                    icon: Icons.logout_rounded,
                    label: 'Log out',
                    color: AppColors.warning,
                    onTap: () => _confirmLogout(context),
                  ),
                  const _Div(),
                  _NavRow(
                    icon: Icons.delete_forever_rounded,
                    label: 'Delete account',
                    color: AppColors.danger,
                    onTap: () => _confirmDelete(context),
                  ),
                ]),
              ],
            ),
    );
  }

  void _confirmLogout(BuildContext context) {
    _confirmDialog(
      context,
      title: 'Log out?',
      message: 'You can always log back in.',
      confirmLabel: 'Log out',
      confirmColor: AppColors.warning,
      onConfirm: () => ref.read(authProvider.notifier).logout(),
    );
  }

  void _confirmDelete(BuildContext context) {
    _confirmDialog(
      context,
      title: 'Delete account?',
      message:
          'This is permanent. All your habits, streaks and data will be deleted forever.',
      confirmLabel: 'Delete forever',
      confirmColor: AppColors.danger,
      onConfirm: () =>
          ref.read(userProfileProvider.notifier).deleteAccount(),
    );
  }

  void _confirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(
                color: AppColors.darkTextPrimary,
                fontWeight: FontWeight.w700)),
        content: Text(message,
            style: const TextStyle(
                color: AppColors.darkTextSecondary, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(confirmLabel,
                style: TextStyle(
                    color: confirmColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextSecondary,
              letterSpacing: 0.8)),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.darkTextSecondary)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.darkTextPrimary)),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkTextPrimary)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.darkTextSecondary)),
              ],
            ),
          ),
          Switch(value: value, activeColor: color, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.darkTextPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        color: c,
                        fontWeight: FontWeight.w500))),
            if (trailing != null)
              Text(trailing!,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.darkTextSecondary)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.darkTextSecondary),
          ],
        ),
      ),
    );
  }
}

class _Div extends StatelessWidget {
  const _Div();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.darkBorder, indent: 48);
}