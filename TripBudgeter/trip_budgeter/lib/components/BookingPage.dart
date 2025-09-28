import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingPage extends StatefulWidget {
  final Map<String, dynamic> tripData;
  final String tripId;

  const BookingPage({super.key, required this.tripData, required this.tripId});

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _formKey = GlobalKey<FormState>();

  int members = 1;
  bool isHelper = false;

  Map<String, int> hotelRoomsPerSpot = {}; // spot -> number of rooms
  Map<String, int> hotelDaysPerSpot = {}; // spot -> number of days
  Map<String, int> roomTypePerSpot = {}; // spot -> 1 to 4 beds
  Map<String, bool> selectedMeals = {}; // spot -> include meal
  TextEditingController noteController = TextEditingController();

  double totalBill = 0;

  @override
  void initState() {
    super.initState();
    final spots = widget.tripData["spots"] as List<dynamic>? ?? [];
    for (var spot in spots) {
      hotelRoomsPerSpot[spot.toString()] = 1;
      hotelDaysPerSpot[spot.toString()] = 1;
      roomTypePerSpot[spot.toString()] = 1;
      selectedMeals[spot.toString()] = false;
    }
    _calculateBill();
  }

  void _calculateBill() {
    double basePrice = double.tryParse(widget.tripData["price"] ?? "0") ?? 0;
    double extraMemberCharge = members > 5 ? (members - 5) * 5000 : 0;

    // Hotel charges per spot (roomType * rooms * days * 2000)
    double hotelCharge = 0;
    hotelRoomsPerSpot.forEach((spot, rooms) {
      final type = roomTypePerSpot[spot] ?? 1;
      final days = hotelDaysPerSpot[spot] ?? 1;
      hotelCharge += rooms * type * days * 2000;
    });

    // Meal charges per spot
    double mealCharge =
        selectedMeals.values.where((v) => v).length * 500.0; // per spot

    double helperCharge = isHelper ? 2000 : 0;

    setState(() {
      totalBill = basePrice + extraMemberCharge + hotelCharge + mealCharge + helperCharge;
    });
  }


// Inside _BookingPageState
Future<void> _submitBooking() async {
  if (!_formKey.currentState!.validate()) return;

  // Retrieve email from SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userEmail = prefs.getString('email'); // make sure you stored it during login

  final bookingData = {
    "tripId": widget.tripId,
    "tripTitle": widget.tripData["title"] ?? "",
    "members": members,
    "isHelper": isHelper,
    "hotelRoomsPerSpot": hotelRoomsPerSpot,
    "hotelDaysPerSpot": hotelDaysPerSpot,
    "roomTypePerSpot": roomTypePerSpot,
    "selectedMeals": selectedMeals,
    "note": noteController.text,
    "totalBill": totalBill,
    "createdAt": DateTime.now(),
    "spots": widget.tripData["spots"] ?? [],
    "points": widget.tripData["points"] ?? [],
    "userEmail": userEmail ?? "Unknown", // store email in database
  };

  await FirebaseFirestore.instance
      .collection("booking_requests")
      .add(bookingData);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Booking request submitted successfully!")),
  );

  Navigator.pop(context);
}

  Widget _buildSpotCard(String spot) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spot,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Room type
            Row(
              children: [
                Text("Room Type (beds): ", style: GoogleFonts.poppins(fontSize: 14)),
                DropdownButton<int>(
                  value: roomTypePerSpot[spot],
                  items: List.generate(
                      4,
                      (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text("${index + 1}"),
                          )),
                  onChanged: (val) {
                    setState(() {
                      roomTypePerSpot[spot] = val ?? 1;
                      _calculateBill();
                    });
                  },
                ),
              ],
            ),
            // Hotel Rooms
            Row(
              children: [
                Text("Rooms: ", style: GoogleFonts.poppins(fontSize: 14)),
                IconButton(
                    onPressed: () {
                      if ((hotelRoomsPerSpot[spot] ?? 1) > 1) {
                        setState(() {
                          hotelRoomsPerSpot[spot] = (hotelRoomsPerSpot[spot] ?? 1) - 1;
                          _calculateBill();
                        });
                      }
                    },
                    icon: const Icon(Icons.remove)),
                Text("${hotelRoomsPerSpot[spot]}", style: GoogleFonts.poppins(fontSize: 14)),
                IconButton(
                    onPressed: () {
                      setState(() {
                        hotelRoomsPerSpot[spot] = (hotelRoomsPerSpot[spot] ?? 1) + 1;
                        _calculateBill();
                      });
                    },
                    icon: const Icon(Icons.add)),
                const SizedBox(width: 16),
                Text("Days: ", style: GoogleFonts.poppins(fontSize: 14)),
                DropdownButton<int>(
                  value: hotelDaysPerSpot[spot],
                  items: List.generate(
                      10,
                      (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text("${index + 1}"),
                          )),
                  onChanged: (val) {
                    setState(() {
                      hotelDaysPerSpot[spot] = val ?? 1;
                      _calculateBill();
                    });
                  },
                ),
              ],
            ),
            // Meal selection
            Row(
              children: [
                Checkbox(
                    value: selectedMeals[spot] ?? false,
                    onChanged: (v) {
                      setState(() {
                        selectedMeals[spot] = v ?? false;
                        _calculateBill();
                      });
                    }),
                const Text("Include Meal (Breakfast/Lunch/Dinner)")
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Cost for this spot: PKR ${(hotelRoomsPerSpot[spot]! * roomTypePerSpot[spot]! * hotelDaysPerSpot[spot]! * 2000) + (selectedMeals[spot]! ? 500 : 0)}",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spots = widget.tripData["spots"] as List<dynamic>? ?? [];
    final points = widget.tripData["points"] as List<dynamic>? ?? [];
    final tripImages = widget.tripData["images"] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("Book: ${widget.tripData["title"] ?? ""}"),
        backgroundColor: const Color(0xFF38B6FF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Images Carousel
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: tripImages.map((img) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(img, width: 250, fit: BoxFit.cover),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              // Trip Details
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Trip Details", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("Title: ${widget.tripData["title"]}", style: GoogleFonts.poppins(fontSize: 14)),
                      Text("City: ${widget.tripData["city"]}", style: GoogleFonts.poppins(fontSize: 14)),
                      Text("Duration: ${widget.tripData["duration"]}", style: GoogleFonts.poppins(fontSize: 14)),
                      Text(
                        "Dates: ${DateFormat('dd MMM yyyy').format(widget.tripData["startDate"].toDate())} - ${DateFormat('dd MMM yyyy').format(widget.tripData["endDate"].toDate())}",
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: points.map((p) => Chip(label: Text(p.toString()))).toList(),
                      ),
                      const SizedBox(height: 8),
                      Text("Spots: ${spots.join(", ")}", style: GoogleFonts.poppins(fontSize: 14)),
                      const SizedBox(height: 8),
                      Text("Base Price: PKR ${widget.tripData["price"]}", style: GoogleFonts.poppins(fontSize: 14, color: Colors.green)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Billing Explanation
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Billing Tips", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 6),
                      Text(
                          "- Base Price: Trip base price as listed.\n"
                          "- Extra Members: Members above 5 will add PKR 5000 per member.\n"
                          "- Hotel Charges: Number of rooms * bed type * days * PKR 2000.\n"
                          "- Meal Charges: PKR 500 per spot if meal included.\n"
                          "- Helper: PKR 2000 if helper added.\n\n"
                          "Select options below to see real-time bill updates.",
                          style: GoogleFonts.poppins(fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Members & Helper
              Text("Members", style: GoogleFonts.poppins(fontSize: 14)),
              Row(
                children: [
                  IconButton(
                      onPressed: () {
                        if (members > 1) {
                          setState(() {
                            members--;
                            _calculateBill();
                          });
                        }
                      },
                      icon: const Icon(Icons.remove)),
                  Text("$members", style: GoogleFonts.poppins(fontSize: 16)),
                  IconButton(
                      onPressed: () {
                        setState(() {
                          members++;
                          _calculateBill();
                        });
                      },
                      icon: const Icon(Icons.add)),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Checkbox(
                          value: isHelper,
                          onChanged: (v) {
                            setState(() {
                              isHelper = v ?? false;
                              _calculateBill();
                            });
                          }),
                      const Text("Add Helper")
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Spot-wise selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: spots.map((spot) => _buildSpotCard(spot.toString())).toList(),
              ),
              const SizedBox(height: 12),
              // Notes
              Text("Additional Notes", style: GoogleFonts.poppins(fontSize: 14)),
              TextFormField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Add any note...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 16),
              // Total Bill
              Text("Total Bill: PKR $totalBill", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38B6FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _submitBooking,
                  child: const Text("Confirm Booking"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
