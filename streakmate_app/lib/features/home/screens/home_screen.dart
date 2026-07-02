import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/remote/habit_log_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/home_provider.dart';
import '../../../repositories/subtask_repository.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../widgets/habit_list_tile.dart';
import '../widgets/streak_banner.dart';
import '../../journey/screens/journey_screen.dart';
import '../../friends/screens/friends_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../shared/widgets/custom_avatar.dart'; 
import '../../calendar/screens/calendar_screen.dart';
import '../../habits/screens/add_habit_screen.dart';
import '../../../providers/freeze_provider.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../../../providers/notification_provider.dart';

// The exact glowing orange color from the Home UI progress and highlights
const Color _uiOrange = Color(0xFFE5C07A);

/// home_screen.dart
/// Shell screen that owns the 5-tab navigator.
/// The home tab (index 0) renders the dark gamified dashboard
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _tabs = const [
    _HomeTab(),
    JourneyScreen(),
    // index 2 is the FAB — no screen
    FriendsScreen(),
    ProfileScreen(),
  ];

  // Maps bottom-nav tap index to _tabs index
  int _tabIndex(int navIndex) {
    if (navIndex <= 1) return navIndex;
    return navIndex - 1; // 3→2, 4→3
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: IndexedStack(
        index: _tabIndex(_currentIndex),
        children: _tabs,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        onAddTap: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddHabitScreen()),
          );
          if (added == true && context.mounted) {
            ref.read(homeProvider.notifier).loadToday();
          }
        },
      ),
    );
  }
}

/// ─── Home Tab Content ────────────────────────────────────────────────────────
class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  @override
void initState() {
  super.initState();
  Future.microtask(() async {
    await ref.read(homeProvider.notifier).loadToday();
    await ref.read(unreadCountProvider.notifier).fetch();
    if (!mounted) return;
    final missed = ref.read(homeProvider).missedYesterdayDate;
    if (missed != null) {
      _showMissedYesterdayDialog(context, ref, missed);
    }
  });
}

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final user = ref.watch(authProvider).user;

    ref.listen<HomeState>(homeProvider, (previous, next) {
  if (next.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.danger),
    );
    ref.read(homeProvider.notifier).clearError();
  }

  if (previous?.missedYesterdayDate == null && next.missedYesterdayDate != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        _showMissedYesterdayDialog(context, ref, next.missedYesterdayDate!);
      }
    });
  }
});

    final firstName = user?.name.split(' ').first ?? 'Riyas';
    final streak = user?.currentStreakDays ?? 28;

    return RefreshIndicator(
      color: _uiOrange,
      backgroundColor: const Color(0xFF1E1A2D),
      onRefresh: () => ref.read(homeProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          // ── Unified Top Hero Section ─────────────────────────
          SliverToBoxAdapter(
            child: _TopHeroSection(
              firstName: firstName,
              streakDays: streak,
              user: user,
              hasAvatar: user?.name.isNotEmpty ?? false,
              habits: homeState.status == HomeStatus.loaded
                  ? homeState.habits
                  : [],
              onStreakTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CalendarScreen()),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Star Quote Card ──────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _StarQuoteCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // ── Section header ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Habits',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (homeState.allDone)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.success.withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 13, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'All done!',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Vertical Habit List ──────────────────────────────
          if (homeState.status == HomeStatus.loading)
            const SliverToBoxAdapter(
              child: Center(
                  child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: _uiOrange),
              )),
            )
          else if (homeState.status == HomeStatus.error)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Text('😕',
                          style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text(
                        homeState.errorMessage ?? 'Something went wrong',
                        style: const TextStyle(
                            color: AppColors.darkTextSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () =>
                            ref.read(homeProvider.notifier).loadToday(),
                        child: const Text('Retry',
                            style: TextStyle(color: _uiOrange)),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (homeState.habits.isEmpty &&
              homeState.status == HomeStatus.loaded)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    'No habits scheduled for today 🎉',
                    style:
                        TextStyle(color: AppColors.darkTextSecondary),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final habit = homeState.habits[index];
                    return _HabitCardWithSubtasks(
                      habit: habit,
                      isLoading:
                          homeState.loadingHabitIds.contains(habit.id),
                      initiallyExpanded: index == 0,
                    );
                  },
                  childCount: homeState.habits.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

void _showMissedYesterdayDialog(
    BuildContext context, WidgetRef ref, String date) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.darkSurface,
      title: const Text('You missed yesterday',
          style: TextStyle(color: AppColors.darkTextPrimary)),
      content: const Text(
        'Want to protect your streak? Choose freeze or cheat day for yesterday, or dismiss to leave it as missed.',
        style: TextStyle(color: AppColors.darkTextSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            ref.read(homeProvider.notifier).dismissMissedYesterdayPrompt();
          },
          child: const Text('Dismiss',
              style: TextStyle(color: AppColors.darkTextSecondary)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await ref.read(freezeProvider.notifier).activateCheatDay(date: date);
            ref.read(homeProvider.notifier).dismissMissedYesterdayPrompt();
          },
          child: const Text('🎭 Cheat Day',
              style: TextStyle(color: AppColors.prayerPurple)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await ref.read(freezeProvider.notifier).activateFreeze(date: date);
            ref.read(homeProvider.notifier).dismissMissedYesterdayPrompt();
          },
          child: const Text('❄️ Freeze',
              style: TextStyle(color: AppColors.welfareBlue)),
        ),
      ],
    ),
  );
}

/// ─── Unified Top Hero Section ─────────────────────────────────────────────
class _TopHeroSection extends StatelessWidget {
  final String firstName;
  final int streakDays;
  final bool hasAvatar;
  final dynamic user;
  final List<TodayHabitModel> habits;
  final VoidCallback onStreakTap; // ← calendar entry point

  const _TopHeroSection({
    required this.firstName,
    required this.streakDays,
    required this.hasAvatar,
    required this.user,
    required this.habits,
    required this.onStreakTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/homeScreen.png'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.darkBg.withOpacity(0.6),
                    AppColors.darkBg,
                  ],
                  stops: const [0.4, 0.85, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. App Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomAvatar(
                            url: user?.profilePicture,
                            name: user?.name ?? '',
                            size: 44,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Good morning, $firstName! 👋',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Let's make today count.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const NotificationBell(),
                    ],
                  ),
                ),

                const SizedBox(height: 140),

                // 2. Quote (left) & Streak circle (right — tappable → Calendar)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '"Discipline today,\nfreedom tomorrow."',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                            shadows: [
                              Shadow(
                                  color:
                                      Colors.black.withOpacity(0.6),
                                  blurRadius: 4)
                            ],
                          ),
                        ),
                      ),
                      // ── Streak circle — tap opens Calendar ──
                      GestureDetector(
                        onTap: onStreakTap,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 2),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05)
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      Colors.black.withOpacity(0.3),
                                  blurRadius: 10),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$streakDays',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'Day Streak',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 70),

                // 3. Today's Journey section
                if (habits.isNotEmpty)
                  _TodayJourneySection(habits: habits),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Today's Journey ──────────────────────────────────────────────────────
class _TodayJourneySection extends StatelessWidget {
  final List<TodayHabitModel> habits;

  const _TodayJourneySection({required this.habits});

  @override
  Widget build(BuildContext context) {
    final int completedCount = habits.where((h) => h.isCompleted).length;
    final double progress =
        habits.isEmpty ? 0 : completedCount / habits.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Journey",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "$completedCount/${habits.length} completed",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF2A263E),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_uiOrange, Color(0xFFFFB67A)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                        color: _uiOrange.withOpacity(0.4),
                        blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 105,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                final isDone = habit.isCompleted; // ← real value, not fake index check

                return Container(
                  width: 72,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161324),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(habit.icon,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 8),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? const Color(0xFF4CAF50)
                              : Colors.transparent,
                          border: Border.all(
                            color: isDone
                                ? Colors.transparent
                                : Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: isDone
                            ? const Icon(Icons.check,
                                size: 12, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Star Quote Card ──────────────────────────────────────────────────────
class _StarQuoteCard extends StatelessWidget {
  const _StarQuoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF161324),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 8,
            top: -15,
            bottom: -15,
            child: Image.asset(
              'assets/images/homestar.png',
              fit: BoxFit.contain,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 100),
              child: Text(
                '"Small steps every day\ncreate big changes."',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Habit Card With Subtasks ─────────────────────────────────────────────
class _HabitCardWithSubtasks extends ConsumerWidget {
  const _HabitCardWithSubtasks({
    required this.habit,
    required this.isLoading,
    this.initiallyExpanded = false,
  });

  final TodayHabitModel habit;
  final bool isLoading;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtasksAsync = ref.watch(subtasksProvider(habit.id));

    return subtasksAsync.when(
      loading: () => HabitListTile(
        habit: habit,
        subtasks: const [],
        onSubtaskToggle: (_, __) {},
        isLoading: true,
        initiallyExpanded: initiallyExpanded,
      ),
      error: (_, __) => HabitListTile(
        habit: habit,
        subtasks: const [],
        onSubtaskToggle: (_, __) {},
        initiallyExpanded: initiallyExpanded,
      ),
      data: (subtasks) => HabitListTile(
        habit: habit,
        subtasks: subtasks,
        isLoading: isLoading,
        initiallyExpanded: initiallyExpanded,
        onSubtaskToggle: (subtaskId, currentValue) {
          ref.read(homeProvider.notifier).toggleSubtask(
                habitId: habit.id,
                subtaskId: subtaskId,
                currentValue: currentValue,
              );
        },
      ),
    );
  }
}
