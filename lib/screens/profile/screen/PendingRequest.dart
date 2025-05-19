import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PendingRequestsScreen extends StatelessWidget {
  const PendingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      appBar: AppBar(
        title: const Text('Solicitudes Pendientes'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: FutureBuilder<QuerySnapshot>(
          future:
              FirebaseFirestore.instance
                  .collectionGroup('requests')
                  .where('freelancerId', isEqualTo: uid)
                  .where('status', isEqualTo: 'pending')
                  .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final requests = snapshot.data?.docs ?? [];

            if (requests.isEmpty) {
              return const Center(
                child: Text('No tienes solicitudes pendientes.'),
              );
            }

            return ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                final projectRef = request.reference.parent.parent;
                return FutureBuilder<DocumentSnapshot>(
                  future: projectRef!.get(),
                  builder: (context, projectSnapshot) {
                    if (!projectSnapshot.hasData) {
                      return const ListTile(title: Text('Cargando...'));
                    }

                    final project = projectSnapshot.data!;
                    final title = project['title'] ?? 'Proyecto sin título';
                    final description = project['description'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        title: Text(title),
                        subtitle: Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.hourglass_top_rounded),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
