import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  final String from;
  final String to;

  const HomeScreen({super.key, required this.from, required this.to});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // ✅ GET REAL USER ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // ✅ BOOKING FUNCTION (FINAL SAFE VERSION)
  Future<void> bookRide(QueryDocumentSnapshot taxi) async {

    if (taxi['seats'] <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No seats available")),
      );
      return;
    }

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    // 🔥 VERY IMPORTANT CHECK
    if (!taxi.data().toString().contains('driverId') ||
        taxi['driverId'] == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Driver info missing ❌")),
      );
      return;
    }

    final docId = taxi.id;

    try {
      // 🔽 DEBUG PRINTS (VERY IMPORTANT)
      print("Taxi driverId: ${taxi['driverId']}");
      print("Current userId: $currentUserId");

      // 🔽 Reduce seat count
      await FirebaseFirestore.instance
          .collection('taxis')
          .doc(docId)
          .update({
        'seats': taxi['seats'] - 1,
      });

      // 🔽 SAVE BOOKING
      await FirebaseFirestore.instance.collection('bookings').add({
        'driverId': taxi['driverId'], // ✅ MUST MATCH DRIVER UID
        'from': widget.from,
        'to': widget.to,
        'time': taxi['time'] ?? '',
        'fare': taxi['fare'] ?? 0,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': currentUserId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking Confirmed ✅")),
      );

    } catch (e) {
      print("Booking error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking Failed ❌")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.from} → ${widget.to}"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('taxis')
            .where('from', isEqualTo: widget.from)
            .where('to', isEqualTo: widget.to)
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          final taxis = snapshot.data!.docs;

          if (taxis.isEmpty) {
            return const Center(child: Text("No taxis available"));
          }

          return ListView.builder(
            itemCount: taxis.length,
            itemBuilder: (context, index) {
              final taxi = taxis[index];

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(12),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const SizedBox(height: 8),

                      Text("Time: ${taxi['time'] ?? 'N/A'}"),
                      Text("Seats Available: ${taxi['seats']}"),
                      Text("Fare: ₹${taxi['fare']} per seat"),

                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: taxi['seats'] > 0
                              ? () async {
                                  await bookRide(taxi);
                                }
                              : null,
                          child: const Text("Book"),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}