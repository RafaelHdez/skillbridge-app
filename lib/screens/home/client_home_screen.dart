import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba/screens/chat/chat_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen>
    with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  String userName = '';
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadUserName() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    setState(() {
      userName = doc['name'] ?? '';
    });
  }

  Widget _buildChatButton(String projectId, String freelancerId) {
    return IconButton(
      icon: const Icon(Icons.chat, color: Color(0xFF0D47A1)),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              projectId: projectId,
              otherUserId: freelancerId,
              isClient: true,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: Column(
        children: [
          // AppBar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
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
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: ListTile(
                          leading: Icon(
                            Icons.person_outline,
                            color: Color(0xFF0D47A1),
                          ),
                          title: Text('Ver perfil'),
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: ListTile(
                          leading: Icon(
                            Icons.logout,
                            color: Color(0xFF0D47A1),
                          ),
                          title: Text('Cerrar sesión'),
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'profile') {
                        Navigator.pushNamed(context, '/clientProfile');
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
                  'Hola, ${userName.isNotEmpty ? userName : 'Cliente'}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Botón de crear proyecto
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/create_project');
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear nuevo proyecto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                foregroundColor: const Color(0xFF0D47A1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contenido blanco
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('projects')
                      .where('clientId', isEqualTo: user!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final projects = snapshot.data?.docs ?? [];

                    final activeProjects =
                    projects.where((p) => p['freelancerId'] == null).toList();
                    final inProgressProjects =
                    projects.where((p) => p['freelancerId'] != null).toList();

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sectionHeader('Proyectos Activos'),
                          if (activeProjects.isEmpty)
                            noDataText('No tienes proyectos activos'),
                          ...activeProjects
                              .map((doc) => _buildProjectCard(doc, true))
                              .toList(),
                          const SizedBox(height: 24),
                          sectionHeader('Proyectos en Proceso'),
                          if (inProgressProjects.isEmpty)
                            noDataText('No tienes proyectos en proceso'),
                          ...inProgressProjects
                              .map((doc) => _buildProjectCard(doc, false))
                              .toList(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0D47A1),
        ),
      ),
    );
  }

  Widget noDataText(String msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(msg, style: const TextStyle(color: Colors.grey)),
    );
  }

  Widget _buildProjectCard(DocumentSnapshot project, bool isPending) {
    final title = project['title'] ?? 'Sin título';
    final description = project['description'] ?? '';
    final projectId = project.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: const Icon(Icons.folder_open, color: Color(0xFF0D47A1)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Text(
          isPending
              ? 'Toca para ver freelancers que han solicitado'
              : 'Este proyecto ya está en proceso',
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        children: [
          if (isPending)
            _buildFreelancerRequestList(projectId)
          else
            _buildAssignedFreelancerInfo(projectId, project['freelancerId']),
        ],
      ),
    );
  }

  Widget _buildFreelancerRequestList(String projectId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('requests')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, requestSnapshot) {
        if (requestSnapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        final requests = requestSnapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '❗ Aún no hay freelancers que hayan solicitado este proyecto.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          children: requests.map((doc) {
            final freelancerId = doc['freelancerId'];
            final requestedAt = doc['requestedAt']?.toDate();

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(freelancerId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(
                    title: Text('Cargando freelancer...'),
                  );
                }

                final freelancer = userSnapshot.data!;
                final name = freelancer['name'] ?? 'Freelancer';

                return ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(name),
                  subtitle: requestedAt != null
                      ? Text(
                    'Solicitado el: ${requestedAt.toLocal().toString().split(' ')[0]}',
                  )
                      : null,
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('projects')
                          .doc(projectId)
                          .collection('requests')
                          .doc(freelancerId)
                          .update({'status': 'accepted'});

                      await FirebaseFirestore.instance
                          .collection('projects')
                          .doc(projectId)
                          .update({'freelancerId': freelancerId});

                      final allRequests = await FirebaseFirestore.instance
                          .collection('projects')
                          .doc(projectId)
                          .collection('requests')
                          .get();

                      for (var doc in allRequests.docs) {
                        if (doc.id != freelancerId) {
                          await doc.reference.update({
                            'status': 'rejected',
                          });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Aprobar'),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAssignedFreelancerInfo(String projectId, String freelancerId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(freelancerId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        final data = snapshot.data!;
        final name = data['name'] ?? 'Freelancer';
        final email = data['email'] ?? '';

        return ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text(name),
          subtitle: Text(email),
          trailing: _buildChatButton(projectId, freelancerId),
        );
      },
    );
  }
}