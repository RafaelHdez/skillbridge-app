import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba/screens/profile/badget/badge_model.dart';

class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'badgets';

  Future<List<UserBadge>> getAllBadges() async {
    try {
      print('🟡 Iniciando carga de insignias');
      QuerySnapshot snapshot = await _firestore.collection('badgets').get();
      print('🟢 Insignias encontradas: ${snapshot.docs.length}');
      return snapshot.docs.map((doc) => UserBadge.fromFirestore(doc)).toList();
    } catch (e) {
      print('🔴 Error en getAllBadges: $e');
      throw Exception('Error al obtener insignias: $e');
    }
  }

  Future<UserBadge> getBadgeById(String badgeId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collectionName).doc(badgeId).get();
      if (!doc.exists) throw Exception('Insignia no encontrada');
      return UserBadge.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirebaseError(e);
    }
  }

  Stream<List<UserBadge>> get badgesStream {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => UserBadge.fromFirestore(doc)).toList(),
        );
  }

  Future<void> assignBadgeToUser(String userId, String badgeId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'badgtesId': FieldValue.arrayUnion([badgeId]),
      });
    } on FirebaseException catch (e) {
      throw _handleFirebaseError(e);
    }
  }

  Exception _handleFirebaseError(FirebaseException e) {
    print('Firestore Error [${e.code}]: ${e.message}');
    return Exception('Error de Firebase: ${e.message}');
  }
}
