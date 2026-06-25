import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/remote/habit_log_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/home_provider.dart';
import '../../../repositories/subtask_repository.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../widgets/habit_list_tile.dart';
import '../widgets/today_progress_card.dart';
import 'placeholder_screens.dart';

/// home_screen.dart
/// Shell screen that owns the 5-tab navigator.
/// The home tab (index 0) renders the dark gamified dashboard
/// matching the beautiful UI design.
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
  int _tabIndex(int navIndex) {
    if (navIndex <= 1) return navIndex;
    return navIndex - 1; // 3→2, 4→3
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14), // Deep dark background from UI
      body: IndexedStack(
        index: _tabIndex(_currentIndex),
        children: _tabs,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        onAddTap: () {
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
    Future.microtask(() => ref.read(homeProvider.notifier).loadToday());
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final user = ref.watch(authProvider).user;

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

    final firstName = user?.name.split(' ').first ?? 'Riyas';
    final streak = user?.currentStreakDays ?? 28;

    // Removed the global SafeArea so the top hero can extend to the very top edge
    return RefreshIndicator(
      color: const Color(0xFFE5A663), // Star/Flame Orange
      backgroundColor: const Color(0xFF1E1A2D),
      onRefresh: () => ref.read(homeProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          // ── Unified Top Hero Section (App Bar + Tree/Home + Streak) ────
          SliverToBoxAdapter(
            child: _TopHeroSection(
              firstName: firstName,
              streakDays: streak,
              hasAvatar: user?.name.isNotEmpty ?? false,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Today's Journey ──────────────────────────────────────────
          if (homeState.status == HomeStatus.loaded && homeState.habits.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TodayProgressCard(
                  habits: homeState.habits,
                  onHabitTap: (_) {}, 
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Star Quote Card ──────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _StarQuoteCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // ── Section header for vertical list (Optional/Scrollable) ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Your Habits',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Vertical Habit List ──────────────────────────────────────
          if (homeState.status == HomeStatus.loading)
            const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
            )
          else if (homeState.habits.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final habit = homeState.habits[index];
                    return _HabitCardWithSubtasks(
                      habit: habit,
                      isLoading: homeState.loadingHabitIds.contains(habit.id),
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

/// ─── New Unified Top Hero Section ────────────────────────────────────────────
class _TopHeroSection extends StatelessWidget {
  final String firstName;
  final int streakDays;
  final bool hasAvatar;

  const _TopHeroSection({
    required this.firstName,
    required this.streakDays,
    required this.hasAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/homeScreen.png'), // <-- YOUR TREE+HOME IMAGE
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay to seamlessly fade the image into the dark background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0D0B14).withOpacity(0.5),
                    const Color(0xFF0D0B14),
                  ],
                  stops: const [0.4, 0.8, 1.0],
                ),
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- App Bar ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundImage: const AssetImage('assets/images/avatar.png'),
                            backgroundColor: const Color(0xFF1E1A2D),
                            child: !hasAvatar ? const Text('R', style: TextStyle(color: Colors.white)) : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 120), // Spacing to show the tree and home
                  
                  // --- Quote & Streak Badge ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Discipline today,\nfreedom tomorrow."',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.3,
                            shadows: [Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 4)],
                          ),
                        ),
                      ),
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
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
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── New Star Quote Card ─────────────────────────────────────────────────────
class _StarQuoteCard extends StatelessWidget {
  const _StarQuoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF161324), // Dark sleek card background
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
        clipBehavior: Clip.none, // Allows the image to safely exceed bounds if needed
        children: [
          // 3D Star Asset aligned to the right, full size, unclipped
          Positioned(
            right: 8, // Tweak this if you want it closer/further from the edge
            top: -15, // Negative margin lets it comfortably take up maximum vertical space 
            bottom: -15,
            child: Image.asset(
              'assets/images/homestar.png', // <-- YOUR STAR IMAGE
              fit: BoxFit.contain, // Ensures the entire image is shown without cutting
            ),
          ),
          
          // Text Content
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

/// ─── Subtask Handling (Unchanged) ────────────────────────────────────────────
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