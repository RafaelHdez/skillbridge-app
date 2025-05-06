import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Inicio de sesión con correo y contraseña
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      String message = _handleAuthError(e);
      throw FirebaseAuthException(code: e.code, message: message);
    }
  }

  // Registro de usuarios
  Future<User?> registerWithEmailAndPassword(
      String email,
      String password,
      String name,
      String userType, // 'client' o 'freelancer'
      ) async {
    try {
      // Creación de usuario en Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Guardamos información adicional en Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
        'uid': userCredential.user?.uid,
        'email': email,
        'name': name,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.message}");
      print("Error Code: ${e.code}");

      String message = _handleAuthError(e);
      throw FirebaseAuthException(code: e.code, message: message);
    } catch (e) {
      print("Error: $e");
      throw Exception("Error al registrar. Por favor intente nuevamente.");
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Obtener el usuario actual
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Escuchar cambios en el estado de autenticación
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  // Actualizar el nombre de usuario en Firestore
  Future<void> updateUserName(String uid, String name) async {
    await _firestore.collection('users').doc(uid).update({
      'name': name,
    });
  }

  // Obtener los datos del usuario desde Firestore
  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  // Función para manejar errores de Firebase Auth
  String _handleAuthError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'email-already-in-use':
        message = 'El correo ya está registrado.';
        break;
      case 'invalid-email':
        message = 'El correo no es válido.';
        break;
      case 'wrong-password':
        message = 'La contraseña es incorrecta.';
        break;
      case 'weak-password':
        message = 'La contraseña es muy débil.';
        break;
      default:
        message = 'Error desconocido: ${e.message}';
    }
    return message;
  }
}