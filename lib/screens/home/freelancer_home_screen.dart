import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FreelancerHomeScreen extends StatefulWidget {
  const FreelancerHomeScreen({super.key});

  @override
  State<FreelancerHomeScreen> createState() => _FreelancerHomeScreenState();
}

class _FreelancerHomeScreenState extends State<FreelancerHomeScreen>
    with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  late TabController _tabController;
  String userName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    setState(() {
      userName = doc['name'] ?? '';
    });
  }

  Future<void> requestProject(String projectId) async {
    final requestRef = FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('requests')
        .doc(user!.uid);

    await requestRef.set({
      'freelancerId': user!.uid,
      'requestedAt': Timestamp.now(),
      'status': 'pending',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('¡Solicitud enviada exitosamente!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildProjectCard(DocumentSnapshot project,
      {VoidCallback? onRequest}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project['title'],
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(project['description']),
            if (onRequest != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton.icon(
                  onPressed: onRequest,
                  icon: const Icon(Icons.send),
                  label: const Text('Solicitar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SkillBridge',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'profile') {
                        Navigator.pushNamed(context, '/profile');
                      } else if (value == 'logout') {
                        FirebaseAuth.instance.signOut();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: Text('Ver perfil'),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Text('Cerrar sesión'),
                      ),
                    ],
                  )
                ],
              ),
            ),
            // Saludo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Hola, ${userName.isNotEmpty ? userName : 'Freelancer'}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contenido blanco
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF0D47A1),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF0D47A1),
                      tabs: const [
                        Tab(text: 'Disponibles'),
                        Tab(text: 'Solicitados'),
                        Tab(text: 'Asignados'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Disponibles
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('projects')
                                .where('status', isEqualTo: 'activo')
                                .where('freelancerId', isNull: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              final projects = snapshot.data!.docs;
                              if (projects.isEmpty) {
                                return const Center(
                                    child: Text('No hay proyectos disponibles.'));
                              }
                              return ListView(
                                padding: const EdgeInsets.all(16),
                                children: projects
                                    .map((p) => _buildProjectCard(p,
                                    onRequest: () => requestProject(p.id)))
                                    .toList(),
                              );
                            },
                          ),

                          // Solicitados
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collectionGroup('requests')
                                .where('freelancerId', isEqualTo: user!.uid)
                                .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Center(child: Text('Error: ${snapshot.error}'));
                                }
                                if (!snapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final requests = snapshot.data!.docs;
                                if (requests.isEmpty) {
                                  return const Center(child: Text('No has solicitado proyectos.'));
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: requests.length,
                                  itemBuilder: (context, index) {
                                    final request = requests[index];
                                    final parent = request.reference.parent.parent;
                                    if (parent == null) {
                                      return const Text('Error: Proyecto no encontrado');
                                    }

                                    final projectId = parent.id;
                                    return FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('projects')
                                          .doc(projectId)
                                          .get(),
                                      builder: (context, projectSnapshot) {
                                        if (projectSnapshot.hasError) {
                                          return Text('Error: ${projectSnapshot.error}');
                                        }
                                        if (!projectSnapshot.hasData) {
                                          return const SizedBox.shrink();
                                        }

                                        final project = projectSnapshot.data!;
                                        return _buildProjectCard(project);
                                      },
                                    );
                                  },
                                );
                              },
                          ),

                          // Asignados
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('projects')
                                .where('freelancerId', isEqualTo: user!.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              final projects = snapshot.data!.docs;
                              if (projects.isEmpty) {
                                return const Center(
                                    child: Text('No tienes proyectos asignados.'));
                              }

                              return ListView(
                                padding: const EdgeInsets.all(16),
                                children:
                                projects.map((p) => _buildProjectCard(p)).toList(),
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
      ),
    );
  }
}
