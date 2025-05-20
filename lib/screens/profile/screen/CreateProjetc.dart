import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientProjects1Screen extends StatefulWidget {
  const ClientProjects1Screen({super.key});

  @override
  State<ClientProjects1Screen> createState() => _ClientProjects1ScreenState();
}

class _ClientProjects1ScreenState extends State<ClientProjects1Screen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  bool isLoading = true;
  List<DocumentSnapshot> _projects = [];

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('projects')
              .where('clientId', isEqualTo: userId)
              .get();

      setState(() {
        _projects = query.docs;
        isLoading = false;
      });
    } catch (e) {
      print('Error al cargar proyectos: $e');
      setState(() => isLoading = false);
    }
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
                        'Mis Proyectos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child:
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _projects.isEmpty
                            ? const Center(
                              child: Text('No se encontraron proyectos.'),
                            )
                            : ListView.builder(
                              itemCount: _projects.length,
                              itemBuilder: (context, index) {
                                final project =
                                    _projects[index].data()
                                        as Map<String, dynamic>;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    title: Text(
                                      project['title'] ?? 'Sin título',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      project['description'] ??
                                          'Sin descripción',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Chip(
                                      label: Text(
                                        project['status'] ?? 'Desconocido',
                                      ),
                                      backgroundColor: Colors.blue[50],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ),
              ],
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
