import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverRouteScreen extends StatefulWidget {
  const DriverRouteScreen({super.key});

  @override
  State<DriverRouteScreen> createState() => _DriverRouteScreenState();
}

class _DriverRouteScreenState extends State<DriverRouteScreen> {
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  final TextEditingController seatsController = TextEditingController();
  final TextEditingController fareController = TextEditingController();

  TimeOfDay? selectedTime;

  // ✅ TIME PICKER
  Future<void> pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),

      // 🔥 OPTIONAL: 24-hour format (clean UI)
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  // 🔥 CAPITALIZE FUNCTION
  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // ✅ SAVE ROUTE (FINAL SAFE VERSION)
  Future<void> saveRoute() async {
    if (fromController.text.isEmpty ||
        toController.text.isEmpty ||
        seatsController.text.isEmpty ||
        fareController.text.isEmpty ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields including time")),
      );
      return;
    }

    try {
      // ✅ SAFE USER CHECK
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")),
        );
        return;
      }

      String formattedTime = selectedTime!.format(context);

      await FirebaseFirestore.instance.collection('taxis').add({
        'from': capitalize(fromController.text.trim()),
        'to': capitalize(toController.text.trim()),
        'seats': int.parse(seatsController.text.trim()),
        'fare': int.parse(fareController.text.trim()),
        'time': formattedTime,
        'driverId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Route Added Successfully ✅")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    seatsController.dispose();
    fareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Route"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: fromController,
              decoration: const InputDecoration(labelText: "From"),
            ),

            TextField(
              controller: toController,
              decoration: const InputDecoration(labelText: "To"),
            ),

            TextField(
              controller: seatsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Seats"),
            ),

            TextField(
              controller: fareController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Fare per seat"),
            ),

            const SizedBox(height: 15),

            // ⏰ TIME PICKER BUTTON (SAFE UI)
            ElevatedButton(
              onPressed: () => pickTime(context),
              child: Text(
                selectedTime != null
                    ? "Time: ${selectedTime!.format(context)}"
                    : "Select Time",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: saveRoute,
              child: const Text("Save Route"),
            ),
          ],
        ),
      ),
    );
  }
}