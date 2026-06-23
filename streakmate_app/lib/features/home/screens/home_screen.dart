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
import '../widgets/today_progress_card.dart';
import 'placeholder_screens.dart';

/// home_screen.dart
/// Shell screen that owns the 5-tab navigator.
/// The home tab (index 0) renders the dark gamified dashboard
/// matching image 2.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  static const _tabs = [
    _HomeTab(),
    JourneyScreen(),
    // index 2 is the FAB — no screen
    FriendsScreen(),
    ProfileScreen(),
  ];

  // Maps bottom-nav tap index to _tabs index
  // (FAB at index 2 is intercepted before here)
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
        onAddTap: () {
          // TODO: Navigate to add-habit screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add habit — coming soon')),
          );
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
    // Load today's habits once on mount
    Future.microtask(() => ref.read(homeProvider.notifier).loadToday());
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final user = ref.watch(authProvider).user;

    // Surface errors
    ref.listen<HomeState>(homeProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.danger,
          ),
        );
        ref.read(homeProvider.notifier).clearError();
      }
    });

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.flameOrange,
        backgroundColor: AppColors.darkSurface,
        onRefresh: () => ref.read(homeProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            // ── App bar row ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'StreakMate',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkTextPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Row(
                      children: [
                        // Notification bell
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_none_rounded,
                                  color: AppColors.darkTextSecondary),
                              onPressed: () {},
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.flameOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Avatar
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.darkSurfaceElevated,
                          child: Text(
                            (user?.name.isNotEmpty == true)
                                ? user!.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.flameOrange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Streak banner + XP bar ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreakBanner(
                  userName: user?.name.split(' ').first ?? 'there',
                  streakDays: user?.currentStreakDays ?? 0,
                  level: user?.level ?? 1,
                  xpPoints: user?.xpPoints ?? 0,
                  xpToNextLevel: user?.xpToNextLevel ?? 100,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Today's Journey progress card ─────────────────────
            if (homeState.status == HomeStatus.loaded &&
                homeState.habits.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TodayProgressCard(
                    habits: homeState.habits,
                    onHabitTap: (_) {}, // scrolls to that habit card
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

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
                        color: AppColors.darkTextPrimary,
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

            // ── Habit cards ──────────────────────────────────────
            if (homeState.status == HomeStatus.loading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                      color: AppColors.flameOrange,
                    ),
                  ),
                ),
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
                              style:
                                  TextStyle(color: AppColors.flameOrange)),
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
                      style: TextStyle(color: AppColors.darkTextSecondary),
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
      ),
    );
  }
}

/// Fetches subtasks for a single habit then renders HabitListTile
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
