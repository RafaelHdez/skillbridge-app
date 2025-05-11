import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    final docRef = FirebaseFirestore.instance.collection('projects').doc();

    await docRef.set({
      'projectId': docRef.id,
      'title': _titleController.text,
      'description': _descriptionController.text,
      'clientId': user!.uid,
      'freelancerId': null,
      'status': 'activo',
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proyecto creado exitosamente')),
    );

    Navigator.pop(context); // Regresa a la pantalla anterior
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Proyecto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) =>
                value!.isEmpty ? 'Ingrese un título' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration:
                const InputDecoration(labelText: 'Descripción'),
                validator: (value) =>
                value!.isEmpty ? 'Ingrese una descripción' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createProject,
                child: const Text('Crear Proyecto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
