import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:trip_budgeter/components/BookingPage.dart';
import 'package:trip_budgeter/components/appbar.dart';
import 'package:trip_budgeter/components/bottombar.dart';
import 'TicketDetailPage.dart';

class UpcomingTrips extends StatefulWidget {
  const UpcomingTrips({Key? key}) : super(key: key);

  @override
  _UpcomingTripsState createState() => _UpcomingTripsState();
}

class _UpcomingTripsState extends State<UpcomingTrips> {
  int _selectedIndex = 1;
  String searchQuery = "";
  double? userBudget;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final tripsRef = FirebaseFirestore.instance.collection("upcoming_trips");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(),
      bottomNavigationBar:
          CustomBottomBar(selectedIndex: _selectedIndex, onTap: _onItemTapped),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Field
            TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  searchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search trips...",
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Image.asset("assets/icon.png", height: 20),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(height: 8),
            // Budget Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Enter your budget",
                      prefixIcon:
                          const Icon(Icons.attach_money, color: Colors.green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38B6FF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    setState(() {
                      final val = double.tryParse(_budgetController.text);
                      userBudget = val;
                    });
                  },
                  child: const Text("Apply"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Trips List
           Expanded(
  child: StreamBuilder<QuerySnapshot>(
    stream: tripsRef.snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      // Keep QueryDocumentSnapshot for later (to get .id)
      final tripsDocs = snapshot.data!.docs;

      // Filter trips based on search and budget
      final filteredTrips = tripsDocs.where((doc) {
        final trip = doc.data() as Map<String, dynamic>;
        final title = (trip["title"] ?? "").toString().toLowerCase();
        final city = (trip["city"] ?? "").toString().toLowerCase();
        final startPoint =
            (trip["startPoint"] ?? "").toString().toLowerCase();

        final matchesSearch = searchQuery.isEmpty ||
            title.contains(searchQuery) ||
            city.contains(searchQuery) ||
            startPoint.contains(searchQuery);

        final price = double.tryParse(trip["price"] ?? "0") ?? 0;
        final matchesBudget = userBudget == null || price <= userBudget!;

        return matchesSearch && matchesBudget;
      }).toList();

      if (filteredTrips.isEmpty) {
        return const Center(
            child:
                Text("Sorry! Increase your budget, no trips found."));
      }

      return ListView.builder(
        itemCount: filteredTrips.length,
        itemBuilder: (context, index) {
          final doc = filteredTrips[index];
          final trip = doc.data() as Map<String, dynamic>;
          final firstImage =
              (trip["images"] as List).isNotEmpty ? trip["images"][0] : null;

          final startDate = trip["startDate"]?.toDate() ?? DateTime.now();
          final endDate = trip["endDate"]?.toDate() ?? DateTime.now();
          final daysLeft = startDate.difference(DateTime.now()).inDays;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15)),
                  child: firstImage != null
                      ? Image.network(firstImage,
                          width: double.infinity, height: 150, fit: BoxFit.cover)
                      : Image.asset("assets/logo.png",
                          width: double.infinity, height: 150),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(trip["title"] ?? "",
                                style: GoogleFonts.poppins(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          if (daysLeft >= 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                "$daysLeft days left",
                                style: GoogleFonts.poppins(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                          "${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}",
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 6),
                      Text("City: ${trip["city"] ?? "-"}",
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.black87)),
                      const SizedBox(height: 6),
                      Text("Price: PKR ${trip["price"] ?? "-"}",
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: List<Widget>.from(
                          (trip["points"] as List)
                              .map((p) => Chip(
                                    label: Text(
                                      p.toString(),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.blue.shade50,
                                  )),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: List<Widget>.from(
                          (trip["spots"] as List)
                              .map((s) => Chip(
                                    label: Text(
                                      s.toString(),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.orange.shade50,
                                  )),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF38B6FF),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingPage(
                                  tripData: trip,
                                  tripId: doc.id,
                                ),
                              ),
                            );
                          },
                          child: const Text("Book Now"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  ),
),
   ],
        ),
      ),
    );
  }
}
