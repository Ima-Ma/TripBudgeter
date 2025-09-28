import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_budgeter/components/Contact.dart';
import 'package:trip_budgeter/components/appbar.dart';
import 'package:trip_budgeter/components/bottombar.dart';
import 'package:rxdart/rxdart.dart'; // for StreamZip

class YourBooking extends StatefulWidget {
  const YourBooking({Key? key}) : super(key: key);

  @override
  _YourBookingState createState() => _YourBookingState();
}

class _YourBookingState extends State<YourBooking> {
  int _selectedIndex = 2;
  String? userEmail;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('email');
    });
  }

  @override
  void initState() {
    super.initState();
    _getUserEmail();
  }

  @override
  Widget build(BuildContext context) {
    if (userEmail == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bookingRef = FirebaseFirestore.instance
        .collection("booking_requests")
        .where("userEmail", isEqualTo: userEmail);

    final customReqRef = FirebaseFirestore.instance
        .collection("custom_reqs")
        .where("userEmail", isEqualTo: userEmail);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      bottomNavigationBar:
          CustomBottomBar(selectedIndex: _selectedIndex, onTap: _onItemTapped),
      body: StreamBuilder<List<QuerySnapshot>>(
  stream: Rx.combineLatestList([bookingRef.snapshots(), customReqRef.snapshots()]),
builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookingDocs = snapshot.data![0].docs;
          final customDocs = snapshot.data![1].docs;

          final allDocs = [
            ...bookingDocs.map((doc) => {"type": "booking", "doc": doc}),
            ...customDocs.map((doc) => {"type": "custom", "doc": doc}),
          ];

          if (allDocs.isEmpty) {
            return const Center(
              child: Text(
                "No bookings or custom trips found.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // Sort by createdAt descending
          allDocs.sort((a, b) {
            final aDoc = a["doc"] as QueryDocumentSnapshot;
            final bDoc = b["doc"] as QueryDocumentSnapshot;
            final aData = aDoc.data() as Map<String, dynamic>;
            final bData = bDoc.data() as Map<String, dynamic>;

            DateTime aTime = aData["createdAt"] is Timestamp
                ? (aData["createdAt"] as Timestamp).toDate()
                : DateTime.now();
            DateTime bTime = bData["createdAt"] is Timestamp
                ? (bData["createdAt"] as Timestamp).toDate()
                : DateTime.now();
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: allDocs.length,
            itemBuilder: (context, index) {
              final doc = allDocs[index]["doc"] as QueryDocumentSnapshot;
              final data = doc.data() as Map<String, dynamic>;
              final type = allDocs[index]["type"];
              final createdAt = data["createdAt"] is Timestamp
                  ? (data["createdAt"] as Timestamp).toDate()
                  : DateTime.now();
              final daysSince = DateTime.now().difference(createdAt).inDays;
              final status = data["status"] ?? "";
              bool canCancel = daysSince <= 1 && status != "approved";

              Color statusColor;
              String punchLine;
              IconData statusIcon;

              if (status == "approved") {
                statusColor = Colors.green;
                punchLine = "Your trip is ready! Admin will contact you soon.";
                statusIcon = Icons.check_circle;
              } else if (status == "pending") {
                statusColor = Colors.orange;
                punchLine = "Hang tight! Your trip request is pending.";
                statusIcon = Icons.hourglass_top;
              } else {
                statusColor = Colors.blueGrey;
                punchLine = "Need assistance? Contact admin.";
                statusIcon = Icons.info;
              }

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFE3F2FD)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: statusColor.withOpacity(0.5), width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset("assets/logo.png",
                                width: 40, height: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                type == "booking"
                                    ? data["tripTitle"] ?? "Unknown Trip"
                                    : data["city"] ?? "Custom Trip",
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Icon(statusIcon, color: statusColor, size: 28),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (type == "booking")
                          Text(
                            "Members: ${data["members"] ?? '-'} | Total Bill: PKR ${data["totalBill"] ?? '-'}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        if (type == "custom")
                          Text(
                            "Expected Price: PKR ${data["expectedPrice"] ?? '-'}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          "Notes: ${data["note"] ?? '-'}",
                          style: const TextStyle(
                              fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          punchLine,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: statusColor),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: canCancel
                                    ? () async {
                                        await FirebaseFirestore.instance
                                            .collection(type == "booking"
                                                ? "booking_requests"
                                                : "custom_reqs")
                                            .doc(doc.id)
                                            .delete();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    "Request cancelled successfully." , style: TextStyle(color: Colors.white),)));
                                      }
                                    : null,
                                icon: const Icon(Icons.cancel, color: Colors.white),
                                label: const Text("Cancel Request" , style: TextStyle(color: Colors.white),),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        canCancel ? Colors.red : Colors.grey,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8))),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (status.isEmpty)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const Contact()));
                                  },
                                  icon: const Icon(Icons.contact_mail,
                                      color: Colors.white),
                                  label: const Text("Contact Admin"),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8))),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
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
