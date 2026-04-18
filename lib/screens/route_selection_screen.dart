import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 ADD THIS
import 'home_screen.dart';

class RouteSelectionScreen extends StatefulWidget {
  const RouteSelectionScreen({super.key});

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  String? from;
  String? to;

  List<String> fromList = [];
  List<String> toList = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRoutes();

    // 🔥 OPTIONAL AUTO TEST
    testAuth();
  }

  // 🔥 FIREBASE AUTH TEST FUNCTION
  Future<void> testAuth() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      print("USER UID: ${FirebaseAuth.instance.currentUser?.uid}");
    } catch (e) {
      print("Auth Error: $e");
    }
  }

  // 🔥 LOAD ROUTES FROM FIRESTORE
  Future<void> loadRoutes() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection("taxis").get();

      Set<String> fromSet = {};
      Set<String> toSet = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();

        if (data["from"] != null && data["from"].toString().isNotEmpty) {
          fromSet.add(data["from"]);
        }

        if (data["to"] != null && data["to"].toString().isNotEmpty) {
          toSet.add(data["to"]);
        }
      }

      setState(() {
        fromList = fromSet.toList();
        toList = toSet.toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Route load error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Route")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : (fromList.isEmpty || toList.isEmpty)
                ? const Center(
                    child: Text(
                      "No routes available.\nAdd taxis from admin panel.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : Column(
                    children: [
                      // FROM
                      DropdownButtonFormField<String>(
                        hint: const Text("From"),
                        initialValue: from,
                        items: fromList.map((loc) {
                          return DropdownMenuItem(
                            value: loc,
                            child: Text(loc),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            from = value;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      // TO
                      DropdownButtonFormField<String>(
                        hint: const Text("To"),
                        initialValue: to,
                        items: toList.map((loc) {
                          return DropdownMenuItem(
                            value: loc,
                            child: Text(loc),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            to = value;
                          });
                        },
                      ),

                      const SizedBox(height: 30),

                      // 🔥 SEARCH BUTTON
                      ElevatedButton(
                        onPressed: () {
                          if (from == null || to == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("Please select both locations"),
                              ),
                            );
                            return;
                          }

                          if (from == to) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("From and To cannot be same"),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeScreen(
                                from: from!,
                                to: to!,
                              ),
                            ),
                          );
                        },
                        child: const Text("Search Taxis"),
                      ),

                      const SizedBox(height: 20),

                      // 🔥 MANUAL AUTH TEST BUTTON (SAFE)
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signInAnonymously();

                          print(
                              "USER UID: ${FirebaseAuth.instance.currentUser?.uid}");

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Auth Success! Check console"),
                            ),
                          );
                        },
                        child: const Text("Test Auth"),
                      ),
                    ],
                  ),
      ),
    );
  }
}