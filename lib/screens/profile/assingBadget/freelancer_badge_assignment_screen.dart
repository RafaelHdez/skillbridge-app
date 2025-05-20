import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba/screens/profile/assingBadget/project_service.dart';
import 'package:prueba/screens/profile/badget/badge_model.dart';
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
    final badgeProvider = Provider.of<BadgeProvider>(context, listen: false);
    badgeProvider.loadBadges(); // ✅ Carga inicial única
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
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.all(24),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Seleccionar Insignia',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<BadgeProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (provider.error != null) {
                        return Text(provider.error!);
                      }

                      return SizedBox(
                        height: 320,
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.9,
                              ),
                          itemCount: provider.badges.length,
                          itemBuilder: (context, index) {
                            final badge = provider.badges[index];
                            final isAssigned = currentBadges.contains(badge.id);

                            return InkWell(
                              onTap:
                                  isAssigned
                                      ? null
                                      : () {
                                        Navigator.pop(context);
                                        _assignBadge(freelancerId, badge.id);
                                      },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      isAssigned
                                          ? Colors.grey.shade100
                                          : badge.badgeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        isAssigned
                                            ? Colors.grey.shade300
                                            : badge.badgeColor,
                                    width: 1.5,
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.emoji_events,
                                      color:
                                          isAssigned
                                              ? Colors.grey
                                              : badge.badgeColor,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      badge.nombre,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color:
                                            isAssigned
                                                ? Colors.grey
                                                : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      badge.descripcion,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: Stack(
        children: [
          _buildCurvedBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Mis Freelancers',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadFreelancers,
                      ),
                    ],
                  ),
                ),

                // Cuerpo con curva blanca
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFreelancerHeader(freelancer),
            const SizedBox(height: 12),
            _buildProjectsList(freelancer),
            const SizedBox(height: 12),
            _buildBadgesList(badges),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton.icon(
                onPressed:
                    () => _showBadgeSelectionDialog(freelancer['uid'], badges),
                icon: const Icon(Icons.emoji_events),
                label: const Text('Asignar Insignia'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
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
          backgroundColor: Colors.indigo.shade100,
          radius: 28,
          child: Text(
            freelancer['name'].toString().substring(0, 1).toUpperCase(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              freelancer['name'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              freelancer['email'],
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectsList(Map<String, dynamic> freelancer) {
    final projects = freelancer['projects'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Proyectos:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ...projects.map(
          (project) => ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.work_outline, size: 18),
            title: Text(project['title'], style: const TextStyle(fontSize: 14)),
            trailing: Chip(
              label: Text(
                project['status'],
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: Colors.blue[50],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesList(List<String> badges) {
    return Consumer<BadgeProvider>(
      builder: (context, provider, _) {
        // ✅ Carga inicial única desde el initState del widget padre
        if (provider.badges.isEmpty && !provider.isLoading) {
          provider.loadBadges();
        }

        if (provider.isLoading) {
          return const CircularProgressIndicator();
        }

        if (provider.error != null) {
          return Text(provider.error!);
        }

        // 🔥 Filtrado optimizado usando Set para O(1) en búsquedas
        final badgeIds = badges.toSet();
        final displayedBadges =
            provider.badges
                .where((badge) => badgeIds.contains(badge.id))
                .toList();

        if (displayedBadges.isEmpty) {
          return const Text('No hay insignias asignadas.');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Insignias:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  displayedBadges.map((UserBadge badge) {
                    return Chip(
                      avatar: const Icon(Icons.emoji_events, size: 16),
                      label: Text(badge.nombre),
                      backgroundColor: badge.badgeColor.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: badge.badgeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurvedBackground() {
    return Positioned.fill(
      child: ClipPath(
        clipper: _CurvedClipper(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }
}

class _CurvedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.25);
    path.quadraticBezierTo(
      size.width / 2,
      size.height * 0.35,
      size.width,
      size.height * 0.25,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
