import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/remote/friends_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/friends_provider.dart';
import 'package:share_plus/share_plus.dart';

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
    _tab = TabController(length: 3, vsync: this); // 3 Tabs now
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
    final myUserId = ref.watch(authProvider).user?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: state.loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.flameOrange))
            : NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverToBoxAdapter(child: _Header(requestCount: state.incomingRequests.length)),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarDelegate(
                      TabBar(
                        controller: _tab,
                        indicatorColor: AppColors.flameOrange,
                        labelColor: AppColors.flameOrange,
                        unselectedLabelColor: AppColors.darkTextSecondary,
                        tabs: const [Tab(text: 'Leaderboard'), Tab(text: 'Friends'), Tab(text: 'Discover')],
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tab,
                  children: [
                    _LeaderboardTab(leaderboard: state.leaderboard,activity: state.activity, myUserId: myUserId),
                    _FriendsLogTab(friends: state.friends, activity: state.activity, onNudge: (id) => ref.read(friendsProvider.notifier).nudge(id)),
                    _DiscoverTab(
                      suggestions: state.suggestions,
                      searchResults: state.searchResults,
                      searchLoading: state.searchLoading,
                      onSearch: (q) => ref.read(friendsProvider.notifier).search(q),
                      onClearSearch: () => ref.read(friendsProvider.notifier).clearSearch(),
                      onAdd: (id) => ref.read(friendsProvider.notifier).sendRequest(id),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _InviteBar(),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.requestCount});
  final int requestCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          const Text('Friends',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextPrimary)),
          const Spacer(),
          if (requestCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.flameOrange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$requestCount new',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

// ── Leaderboard tab ───────────────────────────────────────────────────────────
class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab({
    required this.leaderboard,
    required this.activity,
    required this.myUserId,
  });
  final List<LeaderboardEntry> leaderboard;
  final List<FriendActivityItem> activity;
  final String myUserId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        // Top 3 — simplified medal rows
        if (leaderboard.isNotEmpty) ...[
          const _SectionLabel(label: 'TOP 3'),
          _Podium(top3: leaderboard.take(3).toList()),
          const SizedBox(height: 16),
        ],
        // Rest of leaderboard — flat list from #4
        if (leaderboard.length > 3) ...[
          const _SectionLabel(label: 'RANKINGS'),
          ...leaderboard.skip(3).map((e) => _LeaderRow(entry: e)),
          const SizedBox(height: 20),
        ],
        // Friend activity feed
        const _SectionLabel(label: 'FRIEND ACTIVITY'),
        if (activity.isNotEmpty)
          ...activity.map((a) => _ActivityTile(item: a))
        else
          const _EmptyActivity(),
      ],
    );
  }
}

// ── Graphical Podium (Top 3) ────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  const _Podium({required this.top3});
  final List<LeaderboardEntry> top3;

  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) return const SizedBox.shrink();
    
    // Order: 2nd, 1st, 3rd (Center is 1st)
    final sorted = top3.length >= 3 ? [top3[1], top3[0], top3[2]] : top3;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(sorted.length, (i) {
          final rank = (i == 1) ? 1 : (i == 0 ? 2 : 3);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _PodiumCard(entry: sorted[i], rank: rank),
          );
        }),
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {

  final LeaderboardEntry entry;
  final int rank; // 1 = Gold, 2 = Silver, 3 = Bronze
  const _PodiumCard({required this.entry, required this.rank});

  @override
  Widget build(BuildContext context) {
    final isGold = rank == 1;
    final isSilver = rank == 2;
    final isBronze = rank == 3;

    // Define colors based on rank
    final gradientColors = isGold
        ? [const Color(0xFFFFD700).withOpacity(0.2), const Color(0xFFB8860B).withOpacity(0.1)]
        : isSilver
            ? [const Color(0xFFE0E0E0).withOpacity(0.1), const Color(0xFFA0A0A0).withOpacity(0.05)]
            : [const Color(0xFFCD7F32).withOpacity(0.1), const Color(0xFF8B4513).withOpacity(0.05)];

    final borderColor = isGold ? const Color(0xFFFFD700) : (isSilver ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));

    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: gradientColors),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.6), width: 2),
      ),
      child: Column(
        children: [
          Text(isGold ? '🥇' : (isSilver ? '🥈' : '🥉'), style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          _MiniAvatar(name: entry.name, color: AppColors.flameOrange, picture: entry.profilePicture, size: 40),
          const SizedBox(height: 8),
          Text(entry.name.split(' ').first, 
               style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          Text('🔥 ${entry.currentStreak}', 
               style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.flameOrange)),
        ],
      ),
    );
  }
}

// ── Friends Log Tab ──────────────────────────────────────────────────────────
class _FriendsLogTab extends StatelessWidget {
  final List<FriendModel> friends;
  final List<FriendActivityItem> activity;
  final ValueChanged<String> onNudge;
  const _FriendsLogTab({required this.friends, required this.activity, required this.onNudge});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('My Friends', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...friends.map((f) => ListTile(
          leading: _MiniAvatar(name: f.name, color: AppColors.welfareBlue),
          title: Text(f.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text('Streak: ${f.currentStreakDays}'),
        )),
        const Divider(color: AppColors.darkBorder),
        // const Text('Activity Logs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        // ...activity.map((a) => _ActivityTile(item: a)),
      ],
    );
  }
}

// ── Friends horizontal scroll row (matching image 2) ────────────────────────
class _FriendsRow extends StatelessWidget {
  const _FriendsRow({
    required this.friends,
    required this.myUserId,
    required this.onNudge,
  });
  final List<FriendModel> friends;
  final String myUserId;
  final ValueChanged<String> onNudge;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text('Friends',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextSecondary)),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: friends.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, i) => _FriendAvatar(
              friend: friends[i],
              onNudge: () => onNudge(friends[i].id),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _FriendAvatar extends StatelessWidget {
  const _FriendAvatar({required this.friend, required this.onNudge});
  final FriendModel friend;
  final VoidCallback onNudge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onNudge,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.flameOrange.withOpacity(0.7),
                      AppColors.xpGold.withOpacity(0.7),
                    ],
                  ),
                  border: Border.all(
                      color: AppColors.flameOrange.withOpacity(0.4),
                      width: 2),
                ),
                child: friend.profilePicture != null
                    ? ClipOval(
                        child: Image.network(friend.profilePicture!,
                            fit: BoxFit.cover))
                    : Center(
                        child: Text(friend.initials,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white))),
              ),
              // Streak badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.darkBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.flameOrange.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥',
                          style: TextStyle(fontSize: 9)),
                      Text('${friend.currentStreakDays}',
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.flameOrange)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            friend.name.split(' ').first,
            style: const TextStyle(
                fontSize: 11, color: AppColors.darkTextPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Incoming requests banner ─────────────────────────────────────────────────
class _RequestsBanner extends StatelessWidget {
  const _RequestsBanner({
    required this.requests,
    required this.onAccept,
    required this.onReject,
  });
  final List<FriendRequestModel> requests;
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.welfareBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.welfareBlue.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${requests.length} Friend Request${requests.length > 1 ? 's' : ''}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextPrimary)),
          const SizedBox(height: 10),
          ...requests.take(3).map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    _MiniAvatar(
                        name: r.sender.name,
                        color: AppColors.welfareBlue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.sender.name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkTextPrimary)),
                          Text(
                              '@${r.sender.username} · 🔥 ${r.sender.currentStreakDays}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.darkTextSecondary)),
                        ],
                      ),
                    ),
                    _SmallBtn(
                        label: '✓',
                        color: AppColors.success,
                        onTap: () => onAccept(r.sender.id)),
                    const SizedBox(width: 6),
                    _SmallBtn(
                        label: '✕',
                        color: AppColors.danger,
                        onTap: () => onReject(r.sender.id)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.entry});
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: entry.isMe
            ? AppColors.flameOrange.withOpacity(0.08)
            : AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.isMe
              ? AppColors.flameOrange.withOpacity(0.35)
              : AppColors.darkBorder,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('#${entry.rank}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: entry.isMe
                        ? AppColors.flameOrange
                        : AppColors.darkTextSecondary)),
          ),
          _MiniAvatar(name: entry.name, color: AppColors.flameOrange,
              picture: entry.profilePicture),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(entry.name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkTextPrimary),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (entry.isMe)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color:
                              AppColors.flameOrange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('You',
                            style: TextStyle(
                                fontSize: 9,
                                color: AppColors.flameOrange)),
                      ),
                  ],
                ),
                Text('@${entry.username} · Lv ${entry.level}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.darkTextSecondary)),
              ],
            ),
          ),
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 2),
              Text('${entry.currentStreak}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.flameOrange)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Activity feed ─────────────────────────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});
  final FriendActivityItem item;

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
          _MiniAvatar(
              name: item.friendName,
              color: AppColors.success,
              picture: item.friendPicture),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkTextPrimary,
                    height: 1.4),
                children: [
                  TextSpan(
                    text: item.friendName.split(' ').first,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' completed '),
                  TextSpan(
                    text: '${item.habitIcon} ${item.habitName}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(item.timeAgo,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.darkTextSecondary)),
        ],
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: const Column(
        children: [
          Text('😴', style: TextStyle(fontSize: 32)),
          SizedBox(height: 8),
          Text('No activity yet today',
              style: TextStyle(color: AppColors.darkTextSecondary)),
          SizedBox(height: 4),
          Text('Your friends haven\'t completed any habits yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11, color: AppColors.darkTextSecondary)),
        ],
      ),
    );
  }
}

// ── Discover tab ──────────────────────────────────────────────────────────────
class _DiscoverTab extends ConsumerStatefulWidget {
  const _DiscoverTab({
    required this.suggestions,
    required this.searchResults,
    required this.searchLoading,
    required this.onSearch,
    required this.onClearSearch,
    required this.onAdd,
  });
  final List<FriendModel> suggestions;
  final List<FriendModel> searchResults;
  final bool searchLoading;
  final ValueChanged<String> onSearch;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onAdd;

  @override
  ConsumerState<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends ConsumerState<_DiscoverTab> {
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showSearchResults = _searchCtrl.text.trim().length >= 2;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(
                color: AppColors.darkTextPrimary, fontSize: 14),
            onChanged: (v) {
              setState(() => _isSearching = v.trim().isNotEmpty);
              widget.onSearch(v);
            },
            decoration: InputDecoration(
              hintText: 'Search by username or name...',
              hintStyle: const TextStyle(
                  color: AppColors.darkTextSecondary, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.darkTextSecondary, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.darkTextSecondary,
                          size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _isSearching = false);
                        widget.onClearSearch();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (widget.searchLoading)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(
                color: AppColors.flameOrange, strokeWidth: 2),
          ))
        else if (showSearchResults) ...[
          const _SectionLabel(label: 'SEARCH RESULTS'),
          if (widget.searchResults.isEmpty)
            const _EmptySearch()
          else
            ...widget.searchResults.map((u) => _SearchResultTile(
                  user: u,
                  onAdd: () => widget.onAdd(u.id),
                )),
        ] else ...[
          const SizedBox(height: 40),
          const Center(
            child: Column(
              children: [
                Text('🔍', style: TextStyle(fontSize: 40)),
                SizedBox(height: 12),
                Text(
                  'Search by username to find friends',
                  style: TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.user, required this.onAdd});
  final FriendModel user;
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
          _MiniAvatar(
              name: user.name,
              color: AppColors.prayerPurple,
              picture: user.profilePicture),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkTextPrimary)),
                Text('@${user.username} · 🔥 ${user.currentStreakDays}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.darkTextSecondary)),
              ],
            ),
          ),
          if (user.isFriend)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.success.withOpacity(0.35)),
              ),
              child: const Text('Friends',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600)),
            )
          else if (user.requestSent)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.darkBorder,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Sent',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.darkTextSecondary)),
            )
          else
            _AddBtn(onAdd: onAdd),
        ],
      ),
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
          _MiniAvatar(
              name: friend.name,
              color: AppColors.success,
              picture: friend.profilePicture),
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
                Text(
                    '@${friend.username} · 🔥 ${friend.currentStreakDays} days',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.darkTextSecondary)),
              ],
            ),
          ),
          _AddBtn(onAdd: onAdd),
        ],
      ),
    );
  }
}

// ── Invite bar ────────────────────────────────────────────────────────────────
class _InviteBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: const Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: GestureDetector(
        onTap: () => _shareInvite(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.success, Color(0xFF17876D)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('+ Invite Friends',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  void _shareInvite(BuildContext context) {
    const appLink = 'https://streakmate.app/invite'; // 🔁 replace with your real link

    Share.share(
      '🔥 I\'ve been building streaks with StreakMate!\n\n'
      'Join me and let\'s keep each other accountable.\n\n'
      'Download the app: $appLink',
      subject: 'Join me on StreakMate!',
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({
    required this.name,
    required this.color,
    this.picture,
    this.size = 38,
  });
  final String name;
  final Color color;
  final String? picture;
  final double size;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: picture != null
          ? ClipOval(
              child: Image.network(picture!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _Initial(
                      initials: _initials, color: color, size: size)))
          : _Initial(initials: _initials, color: color, size: size),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial(
      {required this.initials,
      required this.color,
      required this.size});
  final String initials;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Center(
        child: Text(initials,
            style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w700,
                color: color)),
      );
}

class _AddBtn extends StatelessWidget {
  const _AddBtn({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
    );
  }
}

class _SmallBtn extends StatelessWidget {
  const _SmallBtn(
      {required this.label,
      required this.color,
      required this.onTap});
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
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700)),
        ),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextSecondary,
              letterSpacing: 0.6)),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Text('🔍', style: TextStyle(fontSize: 36)),
            SizedBox(height: 10),
            Text('No users found',
                style:
                    TextStyle(color: AppColors.darkTextSecondary)),
          ],
        ),
      ),
    );
  }
}

class _EmptySuggestions extends StatelessWidget {
  const _EmptySuggestions();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Text('👥', style: TextStyle(fontSize: 36)),
            SizedBox(height: 10),
            Text('No suggestions right now',
                style: TextStyle(color: AppColors.darkTextSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Tab bar persistent header ─────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => 46;
  @override
  double get maxExtent => 46;

  @override
  Widget build(BuildContext context, double shrinkOffset,
      bool overlapsContent) {
    return Container(
      color: AppColors.darkBg,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}
