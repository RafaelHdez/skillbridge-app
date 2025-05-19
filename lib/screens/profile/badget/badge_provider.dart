import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prueba/screens/profile/badget/badge_model.dart';
import 'package:prueba/screens/profile/badget/badge_repository.dart';
import 'package:prueba/screens/profile/badget/badge_service.dart';
import 'package:flutter/material.dart';

class BadgeProvider with ChangeNotifier {
  List<UserBadge> _badges = [];
  bool _isLoading = false;
  String? _error;

  List<UserBadge> get badges => _badges;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBadges() async {
    try {
      _startLoading();
      _badges = await BadgeService().getAllBadges();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _badges = [];
    } finally {
      _stopLoading();
    }
  }

  UserBadge? getBadgeById(String id) {
    try {
      return _badges.firstWhere((badge) => badge.id == id);
    } catch (e) {
      print("No Encontre badget");
      return null;
    }
  }

  void _startLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void _stopLoading() {
    _isLoading = false;
    notifyListeners();
  }
}
