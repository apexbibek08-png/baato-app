import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'driver_route_screen.dart';

class DriverDashboardScreen extends StatelessWidget {
  const DriverDashboardScreen({super.key});

  // ✅ UPDATE STATUS FUNCTION
  Future<void> updateStatus(
      BuildContext context, String bookingId, String status) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({
      'status': status,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Booking $status ✅")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? driverId = FirebaseAuth.instance.currentUser?.uid;

    if (driverId == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Dashboard"),
        backgroundColor: Colors.green,
      ),

      // ➕ ADD ROUTE BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DriverRouteScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [

          const SizedBox(height: 20),

          const Text(
            "Your Bookings",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // ✅ FIXED (REMOVED orderBy)
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('driverId', isEqualTo: driverId)
                  .snapshots(),

              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading bookings"));
                }

                final bookings = snapshot.data!.docs;

                if (bookings.isEmpty) {
                  return const Center(child: Text("No booking requests"));
                }

                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];

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

                            Text(
                              "${booking['from']} → ${booking['to']}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text("Time: ${booking['time'] ?? 'N/A'}"),
                            Text("Fare: ₹${booking['fare'] ?? 'N/A'}"),
                            Text("Customer ID: ${booking['userId'] ?? 'N/A'}"),

                            const SizedBox(height: 5),

                            Text(
                              "Status: ${booking['status']}",
                              style: TextStyle(
                                color: booking['status'] == 'pending'
                                    ? Colors.orange
                                    : booking['status'] == 'accepted'
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // ✅ ACCEPT / REJECT BUTTONS
                            if (booking['status'] == 'pending')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [

                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    onPressed: () {
                                      updateStatus(
                                          context, booking.id, 'accepted');
                                    },
                                    child: const Text("Accept"),
                                  ),

                                  const SizedBox(width: 10),

                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () {
                                      updateStatus(
                                          context, booking.id, 'rejected');
                                    },
                                    child: const Text("Reject"),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}