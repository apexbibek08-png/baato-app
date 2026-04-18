import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/registration_screen.dart';
import 'screens/route_selection_screen.dart'; // ✅ ADD THIS

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> checkUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString('name');

    if (name == null) {
      return const RegistrationScreen();
    } else {
      // ✅ GO TO ROUTE SELECTION INSTEAD OF HOMESCREEN
      return const RouteSelectionScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Baato App',
      theme: ThemeData(primarySwatch: Colors.blue),

      home: FutureBuilder<Widget>(
        future: checkUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text('Something went wrong')),
            );
          }

          return snapshot.data ?? const RegistrationScreen();
        },
      ),
    );
  }
}