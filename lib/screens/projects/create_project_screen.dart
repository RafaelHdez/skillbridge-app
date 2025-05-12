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

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    final docRef = FirebaseFirestore.instance.collection('projects').doc();

    await docRef.set({
      'projectId': docRef.id,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'clientId': user!.uid,
      'freelancerId': null,
      'status': 'activo',
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() => _isLoading = false);

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
                '¡Proyecto creado exitosamente!',
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

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.edit_note_rounded,
                  size: 72,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nuevo Proyecto',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child:
                      _isLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF0D47A1),
                            ),
                          )
                          : Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _titleController,
                                  decoration: InputDecoration(
                                    labelText: 'Título del proyecto',
                                    filled: true,
                                    fillColor: Colors.blue[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value!.isEmpty
                                              ? 'Ingrese un título'
                                              : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    labelText: 'Descripción detallada',
                                    filled: true,
                                    fillColor: Colors.blue[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value!.isEmpty
                                              ? 'Ingrese una descripción'
                                              : null,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _createProject,
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Crear Proyecto'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D47A1),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
