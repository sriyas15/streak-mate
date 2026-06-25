import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/remote/friends_model.dart';
import '../../../providers/friends_provider.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    Future.microtask(() => ref.read(friendsProvider.notifier).loadAll());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsProvider);

    ref.listen<FriendsState>(friendsProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.danger),
        );
        ref.read(friendsProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text('Friends',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkTextPrimary)),
                  const Spacer(),
                  if (state.incomingRequests.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.flameOrange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${state.incomingRequests.length} new',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Tabs ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: AppColors.flameOrange.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.flameOrange.withOpacity(0.5)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.flameOrange,
                unselectedLabelColor: AppColors.darkTextSecondary,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Leaderboard'),
                  Tab(text: 'Friends'),
                  Tab(text: 'Discover'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Tab views ─────────────────────────────────────────
            Expanded(
              child: state.loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.flameOrange))
                  : TabBarView(
                      controller: _tab,
                      children: [
                        _LeaderboardTab(entries: state.leaderboard),
                        _FriendsTab(
                          friends: state.friends,
                          requests: state.incomingRequests,
                          onAccept: (id) => ref.read(friendsProvider.notifier).acceptRequest(id),
                          onReject: (id) => ref.read(friendsProvider.notifier).rejectRequest(id),
                          onNudge: (id) async {
                            await ref.read(friendsProvider.notifier).nudge(id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Nudge sent 👊')),
                              );
                            }
                          },
                        ),
                        _DiscoverTab(
                          suggestions: state.suggestions,
                          onAdd: (id) => ref.read(friendsProvider.notifier).sendRequest(id),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Leaderboard tab ──────────────────────────────────────────────────────────
class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab({required this.entries});
  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyState(
        emoji: '🏆',
        message: 'Add friends to see the leaderboard!',
      );
    }

    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        // Podium
        if (top3.length >= 1) _Podium(top3: top3),
        const SizedBox(height: 20),
        // Remaining entries
        ...rest.map((e) => _LeaderboardRow(entry: e)),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.top3});
  final List<LeaderboardEntry> top3;

  @override
  Widget build(BuildContext context) {
    // Arrange: 2nd | 1st | 3rd
    final ordered = [
      if (top3.length > 1) top3[1],
      top3[0],
      if (top3.length > 2) top3[2],
    ];
    final heights = [90.0, 110.0, 70.0];
    final crowns = ['🥈', '🥇', '🥉'];
    final colors = [
      Colors.grey.shade400,
      AppColors.xpGold,
      const Color(0xFFCD7F32),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(ordered.length, (i) {
        final entry = ordered[i];
        return Expanded(
          child: Column(
            children: [
              Text(crowns[i], style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              CircleAvatar(
                radius: i == 1 ? 28 : 22,
                backgroundColor: colors[i].withOpacity(0.2),
                child: Text(
                  entry.initials,
                  style: TextStyle(
                    fontSize: i == 1 ? 18 : 14,
                    fontWeight: FontWeight.w700,
                    color: colors[i],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.name.split(' ').first,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkTextPrimary),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '🔥 ${entry.currentStreak}',
                style: TextStyle(fontSize: 11, color: colors[i]),
              ),
              const SizedBox(height: 4),
              Container(
                height: heights[i],
                decoration: BoxDecoration(
                  color: colors[i].withOpacity(0.15),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border.all(color: colors[i].withOpacity(0.4)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry});
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isMe
            ? AppColors.flameOrange.withOpacity(0.1)
            : AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.isMe
              ? AppColors.flameOrange.withOpacity(0.4)
              : AppColors.darkBorder,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: entry.isMe
                    ? AppColors.flameOrange
                    : AppColors.darkTextSecondary,
              ),
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.darkSurfaceElevated,
            child: Text(entry.initials,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.flameOrange)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkTextPrimary),
                    ),
                    if (entry.isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.flameOrange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('You',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.flameOrange)),
                      ),
                    ]
                  ],
                ),
                Text('@${entry.username}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.darkTextSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 2),
                  Text(
                    '${entry.currentStreak} days',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.flameOrange),
                  ),
                ],
              ),
              Text('Lv ${entry.level}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.darkTextSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Friends tab ───────────────────────────────────────────────────────────────
class _FriendsTab extends StatelessWidget {
  const _FriendsTab({
    required this.friends,
    required this.requests,
    required this.onAccept,
    required this.onReject,
    required this.onNudge,
  });

  final List<FriendModel> friends;
  final List<FriendRequestModel> requests;
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onReject;
  final ValueChanged<String> onNudge;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty && requests.isEmpty) {
      return const _EmptyState(
        emoji: '👥',
        message: 'No friends yet.\nHead to Discover to find people!',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        if (requests.isNotEmpty) ...[
          _SectionHeader(
              title: 'Friend Requests', badge: requests.length.toString()),
          ...requests.map((r) => _RequestTile(
                request: r,
                onAccept: () => onAccept(r.sender.id),
                onReject: () => onReject(r.sender.id),
              )),
          const SizedBox(height: 16),
        ],
        if (friends.isNotEmpty) ...[
          const _SectionHeader(title: 'My Friends'),
          ...friends.map((f) => _FriendTile(
                friend: f,
                onNudge: () => onNudge(f.id),
              )),
        ],
      ],
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile(
      {required this.request, required this.onAccept, required this.onReject});
  final FriendRequestModel request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final s = request.sender;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.welfareBlue.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.welfareBlue.withOpacity(0.2),
            child: Text(s.initials,
                style: const TextStyle(
                    color: AppColors.welfareBlue, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkTextPrimary)),
                Text('@${s.username}  •  🔥 ${s.currentStreakDays} days',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.darkTextSecondary)),
              ],
            ),
          ),
          Row(
            children: [
              _SmallButton(
                label: '✓',
                color: AppColors.success,
                onTap: onAccept,
              ),
              const SizedBox(width: 6),
              _SmallButton(
                label: '✕',
                color: AppColors.danger,
                onTap: onReject,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend, required this.onNudge});
  final FriendModel friend;
  final VoidCallback onNudge;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.flameOrange.withOpacity(0.15),
            child: Text(friend.initials,
                style: const TextStyle(
                    color: AppColors.flameOrange, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkTextPrimary)),
                Text('@${friend.username}  •  Lv ${friend.level}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.darkTextSecondary)),
              ],
            ),
          ),
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 3),
              Text('${friend.currentStreakDays}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.flameOrange)),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onNudge,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: const Text('👊',
                      style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Discover tab ─────────────────────────────────────────────────────────────
class _DiscoverTab extends StatelessWidget {
  const _DiscoverTab({required this.suggestions, required this.onAdd});
  final List<FriendModel> suggestions;
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const _EmptyState(
          emoji: '🔍', message: 'No suggestions right now.\nCheck back later!');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        const _SectionHeader(title: 'People you may know'),
        ...suggestions.map((s) => _SuggestionTile(
              friend: s,
              onAdd: () => onAdd(s.id),
            )),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.friend, required this.onAdd});
  final FriendModel friend;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.success.withOpacity(0.15),
            child: Text(friend.initials,
                style: const TextStyle(
                    color: AppColors.success, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkTextPrimary)),
                Text('@${friend.username}  •  🔥 ${friend.currentStreakDays}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.darkTextSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFF2A33D), Color(0xFFE8762B)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('+ Add',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.badge});
  final String title;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextPrimary)),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.flameOrange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(badge!,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.emoji, required this.message});
  final String emoji;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.darkTextSecondary, height: 1.5)),
        ],
      ),
    );
  }
}