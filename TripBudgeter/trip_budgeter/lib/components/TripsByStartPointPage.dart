import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trip_budgeter/components/BookingPage.dart';

class TripsByStartPointPage extends StatelessWidget {
  final String startPoint;
  const TripsByStartPointPage({super.key, required this.startPoint});

  @override
  Widget build(BuildContext context) {
    final tripsRef = FirebaseFirestore.instance.collection("upcoming_trips");

    return Scaffold(
      appBar: AppBar(
        title: Text("$startPoint Trips"),
        backgroundColor: const Color(0xFF38B6FF),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: tripsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final trips = snapshot.data!.docs;

          // Filter trips locally with at least 5 matching characters
          final filteredTrips = trips.where((tripDoc) {
            final trip = tripDoc.data() as Map<String, dynamic>;
            final tripStartPoint = trip["startPoint"] ?? "";

            return _hasMatchingChars(startPoint, tripStartPoint, 5);
          }).toList();

          if (filteredTrips.isEmpty) return Center(child: Text("No trips found from $startPoint."));

          return ListView.builder(
            itemCount: filteredTrips.length,
            itemBuilder: (context, index) {
              final trip = filteredTrips[index].data() as Map<String, dynamic>;
              final firstImage = (trip["images"] as List).isNotEmpty ? trip["images"][0] : null;

              return Card(
                margin: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: firstImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(firstImage, width: 60, height: 60, fit: BoxFit.cover),
                        )
                      : Image.asset("assets/3icon.png", width: 60, height: 60),
                  title: Text(trip["title"] ?? "Unknown Trip"),
                  subtitle: Text(trip["startPoint"] ?? "-"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingPage(
                          tripData: filteredTrips[index].data() as Map<String, dynamic>,
                          tripId: filteredTrips[index].id,
                        ),
                      ),
                    );
                  },


                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper function to check if two strings share at least `n` characters in order
  bool _hasMatchingChars(String a, String b, int n) {
    a = a.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    b = b.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (int i = 0; i <= a.length - n; i++) {
      final sub = a.substring(i, i + n);
      if (b.contains(sub)) return true;
    }
    return false;
  }
}
