import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'driver_dashboard_screen.dart';
import 'route_selection_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController licenseController = TextEditingController();

  String selectedRole = "customer";

  // ✅ REGISTER (ANONYMOUS LOGIN ENABLED)
  Future<void> registerUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      // 🔥 AUTO LOGIN ANONYMOUS
      if (user == null) {
        final userCredential =
            await FirebaseAuth.instance.signInAnonymously();
        user = userCredential.user;
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('name', nameController.text.trim());
      await prefs.setString('role', selectedRole);

      if (selectedRole == "driver") {
        await prefs.setString('license', licenseController.text.trim());
      }

      navigateUser(selectedRole);

    } catch (e) {
      showError(e.toString());
    }
  }

  // ✅ LOGIN
  Future<void> loginUser() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showError("No user found. Please register first.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('role');

    if (role == null) {
      showError("User not registered. Please register.");
      return;
    }

    navigateUser(role);
  }

  // ✅ NAVIGATION
  void navigateUser(String role) {
    if (role == "driver") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DriverDashboardScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const RouteSelectionScreen(),
        ),
      );
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Register / Login"),
        backgroundColor: Colors.green,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              const SizedBox(height: 20),

              // ✅ LOGIN STATUS
              Text(
                user != null ? "Logged in (Anonymous)" : "Not logged in",
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              // ✅ ROLE
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: "customer", child: Text("Customer")),
                  DropdownMenuItem(value: "driver", child: Text("Driver")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
                decoration: const InputDecoration(labelText: "Select Role"),
              ),

              const SizedBox(height: 15),

              // ✅ NAME
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),

              const SizedBox(height: 15),

              // ✅ LICENSE (ONLY FOR DRIVER)
              if (selectedRole == "driver")
                TextField(
                  controller: licenseController,
                  decoration: const InputDecoration(labelText: "License Number"),
                ),

              const SizedBox(height: 30),

              // ✅ BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: registerUser,
                    child: const Text("Register"),
                  ),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: loginUser,
                    child: const Text("Login"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}