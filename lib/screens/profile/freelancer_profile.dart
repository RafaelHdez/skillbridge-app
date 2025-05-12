import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FreelancerProfileScreen extends StatefulWidget {
  const FreelancerProfileScreen({super.key});

  @override
  State<FreelancerProfileScreen> createState() =>
      _FreelancerProfileScreenState();
}

class _FreelancerProfileScreenState extends State<FreelancerProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
    final assignedProjects =
        await FirebaseFirestore.instance
            .collection('projects')
            .where('freelancerId', isEqualTo: user!.uid)
            .get();

    final assignedCount = assignedProjects.docs.length;
    final requestsCount = assignedCount;

    setState(() {
      userData = doc.data();
      userData!['requestsCount'] = requestsCount;
      userData!['assignedCount'] = assignedCount;
      userData!['badges'] = _generateBadges(userData!);
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> _generateBadges(Map<String, dynamic> data) {
    final List<Map<String, dynamic>> badges = [];
    final int requests = data['requestsCount'] ?? 0;
    final int assigned = data['assignedCount'] ?? 0;

    if (requests >= 1) {
      badges.add({
        'icon': Icons.rocket_launch,
        'label': 'Primer Proyecto',
        'color': Colors.indigo,
      });
    }
    if (requests >= 5) {
      badges.add({
        'icon': Icons.bolt,
        'label': 'Constante ⚡',
        'color': Colors.deepPurple,
      });
    }
    if (assigned >= 1) {
      badges.add({
        'icon': Icons.schedule_send,
        'label': 'Entrega a Tiempo',
        'color': Colors.teal,
      });
    }

    badges.add({
      'icon': Icons.chat_bubble_outline,
      'label': 'Comunicación 💬',
      'color': Colors.orange,
    });

    return badges;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : Stack(
                children: [
                  _buildCurvedBackground(),
                  SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(height: 12),

                          const Icon(
                            Icons.manage_accounts,
                            size: 72,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),

                          Text(
                            '¡Hola ${userData?['name'] ?? 'Freelancer'}! 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 24),

                          _sectionCard(
                            title: 'Tus estadísticas',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _circleStat(
                                  Icons.assignment,
                                  'Asignados',
                                  '${userData!['assignedCount']}',
                                ),
                                _circleStat(
                                  Icons.send,
                                  'Solicitados',
                                  '${userData!['requestsCount']}',
                                ),
                                _circleStat(
                                  Icons.calendar_today,
                                  'Desde',
                                  userData?['createdAt'] != null
                                      ? (userData!['createdAt'] as Timestamp)
                                          .toDate()
                                          .toLocal()
                                          .toString()
                                          .split(' ')[0]
                                      : 'N/A',
                                ),
                              ],
                            ),
                          ),

                          _sectionCard(
                            title: 'Tus insignias',
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children:
                                  userData!['badges']
                                      .map<Widget>(
                                        (badge) => Chip(
                                          label: Text(badge['label']),
                                          avatar: Icon(badge['icon'], size: 20),
                                          backgroundColor: badge['color']
                                              .withOpacity(0.1),
                                          labelStyle: TextStyle(
                                            color: badge['color'],
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),

                          _sectionCard(
                            title: 'Opciones',
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.lock_outline),
                                  title: const Text('Cambiar contraseña'),
                                  onTap: () {},
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.logout),
                                  title: const Text('Cerrar sesión'),
                                  onTap: () async {
                                    await FirebaseAuth.instance.signOut();
                                    if (!mounted) return;
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/login',
                                      (_) => false,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildCurvedBackground() {
    return Positioned.fill(
      child: ClipPath(
        clipper: _CurvedClipper(),
        child: Container(color: const Color(0xFF0D47A1)),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _circleStat(IconData icon, String label, String value) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.blue[50],
          child: Icon(icon, size: 28, color: Colors.blue[900]),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
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
