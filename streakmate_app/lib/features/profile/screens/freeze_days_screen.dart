import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/freeze_provider.dart';

class FreezeDaysScreen extends ConsumerStatefulWidget {
  const FreezeDaysScreen({super.key});

  @override
  ConsumerState<FreezeDaysScreen> createState() => _FreezeDaysScreenState();
}

class _FreezeDaysScreenState extends ConsumerState<FreezeDaysScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(freezeProvider.notifier).loadBalance());
  }

  Future<void> _confirmAndActivate({
    required String title,
    required String message,
    required Future<bool> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(title,
            style: const TextStyle(color: AppColors.darkTextPrimary)),
        content: Text(message,
            style: const TextStyle(color: AppColors.darkTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm',
                style: TextStyle(color: AppColors.flameOrange)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await action();
    }
  }

  @override
  Widget build(BuildContext context) {
    final freezeState = ref.watch(freezeProvider);
    final user = ref.watch(authProvider).user;

    ref.listen<FreezeState>(freezeProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(next.error!),
              backgroundColor: AppColors.danger),
        );
        ref.read(freezeProvider.notifier).clearMessages();
      } else if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: AppColors.success),
        );
        ref.read(freezeProvider.notifier).clearMessages();
      }
    });

    // Prefer freshest balance from freezeProvider; fall back to authProvider user
    final freezesTotal = user?.totalFreezesAlloted ?? 3;
    final freezesUsed =
        freezeState.balance?.freezesUsed ?? user?.freezesUsed ?? 0;
    final freezesLeft =
        freezeState.balance?.freezesRemaining ?? user?.freezesRemaining ?? 3;
    final cheatTotal = user?.cheatDaysAlloted ?? 2;
    final cheatUsed =
        freezeState.balance?.cheatDaysUsed ?? user?.cheatDaysUsed ?? 0;
    final cheatLeft = freezeState.balance?.cheatDaysRemaining ??
        user?.cheatDaysRemaining ??
        2;

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
        title: const Text('Freeze & Cheat Days',
            style: TextStyle(
                color: AppColors.darkTextPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // ── Freeze days card ──────────────────────────────────
          _UsageCard(
            emoji: '❄️',
            title: 'Streak Freeze',
            subtitle: 'Protect your streak when life gets in the way.',
            color: AppColors.welfareBlue,
            used: freezesUsed,
            total: freezesTotal,
            remaining: freezesLeft,
            buttonLabel: 'Freeze Today',
            isLoading: freezeState.activating,
            onActivate: freezesLeft <= 0
                ? null
                : () => _confirmAndActivate(
                      title: 'Freeze today?',
                      message:
                          "This will use 1 of your $freezesTotal monthly freezes to protect today's streak.",
                      action: () =>
                          ref.read(freezeProvider.notifier).activateFreeze(),
                    ),
          ),
          const SizedBox(height: 14),

          // ── Cheat days card ───────────────────────────────────
          _UsageCard(
            emoji: '🎭',
            title: 'Cheat Days',
            subtitle: 'Miss all habits but keep your streak alive.',
            color: AppColors.prayerPurple,
            used: cheatUsed,
            total: cheatTotal,
            remaining: cheatLeft,
            buttonLabel: 'Use Cheat Day',
            isLoading: freezeState.activating,
            onActivate: cheatLeft <= 0
                ? null
                : () => _confirmAndActivate(
                      title: 'Use a cheat day?',
                      message:
                          "This will use 1 of your $cheatTotal monthly cheat days for today.",
                      action: () => ref
                          .read(freezeProvider.notifier)
                          .activateCheatDay(),
                    ),
          ),
          const SizedBox(height: 24),

          // ── How it works ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How it works',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkTextPrimary)),
                const SizedBox(height: 14),
                _HowItWorksRow(
                  emoji: '❄️',
                  title: 'Freeze Day',
                  description:
                      'Activate manually to protect today, or it can be applied automatically when you miss a day. Your streak stays alive but the day is marked frozen.',
                  color: AppColors.welfareBlue,
                ),
                const SizedBox(height: 12),
                _HowItWorksRow(
                  emoji: '🎭',
                  title: 'Cheat Day',
                  description:
                      'You manually activate a cheat day. Habits are skipped for the day and streak is protected.',
                  color: AppColors.prayerPurple,
                ),
                const SizedBox(height: 12),
                _HowItWorksRow(
                  emoji: '🔄',
                  title: 'Monthly Reset',
                  description:
                      'Freeze and cheat day counts reset on the 1st of every month.',
                  color: AppColors.flameOrange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Reset date info ───────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.flameOrange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.flameOrange.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Text('📅', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Next reset',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkTextPrimary)),
                      Text(
                        _nextReset(),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.darkTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _nextReset() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month + 1, 1);
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '1 ${months[next.month]} ${next.year}';
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.used,
    required this.total,
    required this.remaining,
    required this.buttonLabel,
    required this.isLoading,
    required this.onActivate,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final int used;
  final int total;
  final int remaining;
  final String buttonLabel;
  final bool isLoading;
  final Future<void> Function()? onActivate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkTextPrimary)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.darkTextSecondary)),
                  ],
                ),
              ),
              // Remaining badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: remaining > 0
                      ? color.withOpacity(0.2)
                      : AppColors.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: remaining > 0
                        ? color.withOpacity(0.4)
                        : AppColors.danger.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  '$remaining left',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: remaining > 0 ? color : AppColors.danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Dot indicators
          Row(
            children: List.generate(total, (i) {
              final isUsed = i < used;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  height: 10,
                  decoration: BoxDecoration(
                    color: isUsed
                        ? color.withOpacity(0.5)
                        : color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isUsed
                          ? color.withOpacity(0.7)
                          : color.withOpacity(0.2),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            '$used of $total used this month',
            style: const TextStyle(
                fontSize: 12, color: AppColors.darkTextSecondary),
          ),
          const SizedBox(height: 16),
          // ── Activate button ──────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: (onActivate == null || isLoading)
                  ? null
                  : () => onActivate!(),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                disabledBackgroundColor: color.withOpacity(0.25),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      remaining <= 0 ? 'None remaining' : buttonLabel,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksRow extends StatelessWidget {
  const _HowItWorksRow({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });

  final String emoji;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color)),
              const SizedBox(height: 2),
              Text(description,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.darkTextSecondary,
                      height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}