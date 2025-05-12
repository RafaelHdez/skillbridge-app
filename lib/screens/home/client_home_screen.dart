import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
    setState(() {
      userName = doc['name'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: Column(
        children: [
          // AppBar visual
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
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    offset: const Offset(0, 50),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder:
                        (context) => [
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Panel del Cliente',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/create_project');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Crear nuevo proyecto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
