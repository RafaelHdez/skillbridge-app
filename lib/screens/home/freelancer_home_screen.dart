import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FreelancerHomeScreen extends StatefulWidget {
  const FreelancerHomeScreen({super.key});

  @override
  State<FreelancerHomeScreen> createState() => _FreelancerHomeScreenState();
}

class _FreelancerHomeScreenState extends State<FreelancerHomeScreen>
    with TickerProviderStateMixin {  // Cambiado a TickerProviderStateMixin
  final User? user = FirebaseAuth.instance.currentUser;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  String userName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _loadUserName();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
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
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
        ),
        duration: const Duration(seconds: 2),
        content: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Color(0xFF0D47A1)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '¡Solicitud enviada exitosamente!',
                style: TextStyle(
                  color: Color(0xFF0D47A1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(DocumentSnapshot project, {VoidCallback? onRequest}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project['title'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            project['description'],
            style: const TextStyle(fontSize: 15),
          ),
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
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
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
            // Encabezado superior
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SkillBridge',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      cardColor: Colors.white.withOpacity(0.95),
                      shadowColor: Colors.black26,
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      offset: const Offset(0, 50),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: const [
                              Icon(
                                Icons.person_outline,
                                color: Color(0xFF0D47A1),
                              ),
                              SizedBox(width: 10),
                              Text('Ver perfil'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: const [
                              Icon(Icons.logout, color: Color(0xFF0D47A1)),
                              SizedBox(width: 10),
                              Text('Cerrar sesión'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'profile') {
                          Navigator.pushNamed(context, '/profile');
                        } else if (value == 'logout') {
                          FirebaseAuth.instance.signOut();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Saludo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(
                    'Hola, ${userName.isNotEmpty ? userName : 'Freelancer'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido blanco con pestañas
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF0D47A1),
                        indicatorColor: const Color(0xFF0D47A1),
                        indicator: const BoxDecoration(),
                        tabs: const [
                          Tab(text: 'Disponibles'),
                          Tab(text: 'Solicitados'),
                          Tab(text: 'Aprobados'),
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
                                return RefreshIndicator(
                                  onRefresh: () async {
                                    setState(() {});
                                  },
                                  child: ListView(
                                    padding: const EdgeInsets.all(16),
                                    children: projects
                                        .map((p) => _buildProjectCard(p,
                                        onRequest: () => requestProject(p.id)))
                                        .toList(),
                                  ),
                                );
                              },
                            ),

                            // Solicitados
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collectionGroup('requests')
                                  .where('freelancerId', isEqualTo: user!.uid)
                                  .where('status', isEqualTo: 'pending') // Filtrar solo pendientes
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

                            // Aprobados
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

                                return RefreshIndicator(
                                  onRefresh: () async {
                                    setState(() {});
                                  },
                                  child: ListView(
                                    padding: const EdgeInsets.all(16),
                                    children: projects
                                        .map((p) => _buildProjectCard(p))
                                        .toList(),
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}