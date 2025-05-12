import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
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

    final createdProjects =
        await FirebaseFirestore.instance
            .collection('projects')
            .where('clientId', isEqualTo: user!.uid)
            .get();

    final freelancersCount =
        createdProjects.docs
            .where((doc) => doc['freelancerId'] != null)
            .map((doc) => doc['freelancerId'])
            .toSet()
            .length;

    if (!mounted) return;

    setState(() {
      userData = doc.data();
      userData!['projectsCount'] = createdProjects.docs.length;
      userData!['freelancersCount'] = freelancersCount;
      isLoading = false;
    });
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
                            '¡Hola ${userData?['name'] ?? 'Cliente'}! 👋',
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
                                  Icons.folder,
                                  'Proyectos',
                                  '${userData!['projectsCount']}',
                                ),
                                _circleStat(
                                  Icons.group,
                                  'Freelancers',
                                  '${userData!['freelancersCount']}',
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
