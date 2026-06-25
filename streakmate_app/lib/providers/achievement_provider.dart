import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/remote/achievement_model.dart';
import '../repositories/achievement_repository.dart';

final achievementRepositoryProvider =
    Provider<AchievementRepository>((ref) => AchievementRepository());

final achievementsProvider =
    FutureProvider<List<AchievementModel>>((ref) async {
  return ref.watch(achievementRepositoryProvider).getAllAchievements();
});