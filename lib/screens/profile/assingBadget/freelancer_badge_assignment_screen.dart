import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba/screens/profile/assingBadget/project_service.dart';
import 'package:prueba/screens/profile/badget/badge_provider.dart';

class FreelancerBadgeAssignmentScreen extends StatefulWidget {
  final String clientId;

  const FreelancerBadgeAssignmentScreen({required this.clientId, super.key});

  @override
  State<FreelancerBadgeAssignmentScreen> createState() =>
      _FreelancerBadgeAssignmentScreenState();
}

class _FreelancerBadgeAssignmentScreenState
    extends State<FreelancerBadgeAssignmentScreen> {
  final ProjectService _projectService = ProjectService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _freelancers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFreelancers();
  }

  Future<void> _loadFreelancers() async {
    try {
      final freelancers = await _projectService.getFreelancersForClient(
        widget.clientId,
      );
      setState(() => _freelancers = freelancers);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _assignBadge(String freelancerId, String badgeId) async {
    try {
      await _firestore.collection('users').doc(freelancerId).update({
        'badgtesId': FieldValue.arrayUnion([badgeId]),
      });
      await _loadFreelancers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Insignia asignada correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: ${e.toString()}')));
    }
  }

  void _showBadgeSelectionDialog(
    String freelancerId,
    List<String> currentBadges,
  ) {
    final badgeProvider = Provider.of<BadgeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Seleccionar Insignia'),
            content: Consumer<BadgeProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Text(provider.error!);
                }

                return SizedBox(
                  width: double.maxFinite,
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                    itemCount: provider.badges.length,
                    itemBuilder: (context, index) {
                      final badge = provider.badges[index];
                      final isAssigned = currentBadges.contains(badge.id);

                      return Card(
                        color:
                            isAssigned
                                ? badge.badgeColor.withOpacity(0.1)
                                : null,
                        child: InkWell(
                          onTap:
                              isAssigned
                                  ? null
                                  : () {
                                    Navigator.pop(context);
                                    _assignBadge(freelancerId, badge.id);
                                  },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.emoji_events,
                                color:
                                    isAssigned ? Colors.grey : badge.badgeColor,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                badge.nombre,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isAssigned ? Colors.grey : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                badge.descripcion,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Freelancers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFreelancers,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_freelancers.isEmpty)
      return const Center(child: Text('No se encontraron freelancers'));

    return ListView.builder(
      itemCount: _freelancers.length,
      itemBuilder:
          (context, index) => _buildFreelancerCard(_freelancers[index]),
    );
  }

  Widget _buildFreelancerCard(Map<String, dynamic> freelancer) {
    final badges = List<String>.from(freelancer['badgtesId'] ?? []);
    print(badges);

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFreelancerHeader(freelancer),
            const SizedBox(height: 12),
            _buildProjectsList(freelancer),
            const SizedBox(height: 12),
            _buildBadgesList(badges),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed:
                  () => _showBadgeSelectionDialog(freelancer['uid'], badges),
              child: const Text('Asignar Insignia'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreelancerHeader(Map<String, dynamic> freelancer) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            freelancer['name'].toString().substring(0, 1),
            style: const TextStyle(fontSize: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                freelancer['name'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(freelancer['email']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsList(Map<String, dynamic> freelancer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Proyectos:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...(freelancer['projects'] as List).map(
          (project) => Text(
            '- ${project['title']} (${project['status']})',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesList(List<String> badges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Insignias:', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children:
              badges.map((badgeId) {
                final badge = Provider.of<BadgeProvider>(
                  context,
                ).getBadgeById(badgeId);
                return Chip(
                  label: Text(badge?.nombre ?? 'Desconocida'),
                  backgroundColor: badge?.badgeColor.withOpacity(0.2),
                );
              }).toList(),
        ),
      ],
    );
  }
}
