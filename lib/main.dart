// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prueba/screens/home/client_home_screen.dart';
import 'package:prueba/screens/home/freelancer_home_screen.dart';
import 'package:prueba/screens/profile/client_profile.dart';
import 'package:prueba/screens/profile/freelancer_profile.dart';
import 'package:prueba/screens/projects/create_project_screen.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Freelance App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.blue),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: Colors.blue),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Mientras se verifica el estado de autenticación
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          // Si el usuario está autenticado
          if (snapshot.hasData) {
            return FutureBuilder(
              future: AuthService().getUserData(snapshot.data!.uid),
              builder: (context, AsyncSnapshot userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const SplashScreen();
                }

                if (userSnapshot.hasData && userSnapshot.data != null) {
                  final userType = userSnapshot.data['userType'];
                  if (userType == 'freelancer') {
                    return const FreelancerHomeScreen();
                  } else {
                    return const ClientHomeScreen();
                  }
                }

                return const LoginScreen(); // fallback por si algo falla
              },
            );
          }

          // Si el usuario no está autenticado
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(), // Añade esta ruta
        '/freelancerHome': (context) => const FreelancerHomeScreen(),
        '/clientHome': (context) => const ClientHomeScreen(),
        '/create_project': (context) => const CreateProjectScreen(),
        '/profile': (context) => const FreelancerProfileScreen(),
        '/clientProfile': (context) => const ClientProfileScreen(),
      },
    );
  }
}
