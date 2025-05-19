import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getClientProjects(String clientId) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('projects')
              .where('clientId', isEqualTo: clientId)
              .get();

      return snapshot.docs.map((doc) {
        return {...doc.data() as Map<String, dynamic>, 'projectId': doc.id};
      }).toList();
    } catch (e) {
      print('🔴 Error en getClientProjects: $e');
      throw Exception('Error al obtener proyectos: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFreelancersForClient(
    String clientId,
  ) async {
    try {
      final projects = await getClientProjects(clientId);
      if (projects.isEmpty) return [];

      final freelancerIds =
          projects
              .map((p) => p['freelancerId']?.toString())
              .where((id) => id != null && id.isNotEmpty)
              .toSet()
              .toList();

      if (freelancerIds.isEmpty) return [];

      final List<Map<String, dynamic>> allFreelancers = [];
      for (var i = 0; i < freelancerIds.length; i += 10) {
        final chunk = freelancerIds.sublist(
          i,
          i + 10 > freelancerIds.length ? freelancerIds.length : i + 10,
        );

        final snapshot =
            await _firestore
                .collection('users')
                .where('uid', whereIn: chunk)
                .where('userType', isEqualTo: 'freelancer')
                .get();

        allFreelancers.addAll(
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              ...data,
              'uid': doc.id,
              'projects':
                  projects.where((p) => p['freelancerId'] == doc.id).toList(),
            };
          }),
        );
      }

      return allFreelancers;
    } catch (e) {
      print('🔴 Error en getFreelancersForClient: $e');
      throw Exception('Error al obtener freelancers: $e');
    }
  }
}
