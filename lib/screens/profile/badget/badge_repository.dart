import 'package:prueba/screens/profile/badget/badge_model.dart';
import 'package:prueba/screens/profile/badget/badge_service.dart';

class BadgeRepository {
  final BadgeService _badgeService;
  List<UserBadge> _cachedBadges = [];
  DateTime? _lastFetchTime;

  BadgeRepository({BadgeService? service})
    : _badgeService = service ?? BadgeService();

  Future<void> loadAllBadges({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!) < const Duration(minutes: 5)) {
      return;
    }

    try {
      _cachedBadges = await _badgeService.getAllBadges();
      _lastFetchTime = now;
    } catch (e) {
      print('Error loading badges: $e');
      rethrow;
    }
  }

  List<UserBadge> getAllBadges() => List.from(_cachedBadges);

  UserBadge? getBadgeById(String id) {
    try {
      return _cachedBadges.firstWhere((badge) => badge.id == id);
    } catch (e) {
      return null;
    }
  }

  List<UserBadge> searchBadges(String query) {
    if (query.isEmpty) return getAllBadges();
    return _cachedBadges
        .where(
          (badge) =>
              badge.nombre.toLowerCase().contains(query.toLowerCase()) ||
              badge.descripcion.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  Future<void> assignBadgeToUser(String userId, String badgeId) async {
    await _badgeService.assignBadgeToUser(userId, badgeId);
  }

  Stream<List<UserBadge>> get realTimeBadges => _badgeService.badgesStream;
}
