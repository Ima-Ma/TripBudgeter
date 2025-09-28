import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_budgeter/components/appbar.dart';
import 'package:trip_budgeter/components/bottombar.dart';

class CustomTrip extends StatefulWidget {
  const CustomTrip({Key? key}) : super(key: key);

  @override
  _CustomTripState createState() => _CustomTripState();
}

class _CustomTripState extends State<CustomTrip> {
  int _selectedIndex = 4;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String? userEmail;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  String? selectedStartPointId;
  Map<String, dynamic>? selectedStartPointData;
  String? city;
  List<String> selectedSpots = [];
  List<String> selectedTripPoints = [];
  TextEditingController noteController = TextEditingController();

  final Map<String, List<String>> citySpots = {
    "Lahore": ["Badshahi Mosque", "Lahore Fort", "Shalimar Gardens", "Minar-e-Pakistan", "Anarkali Bazaar"],
    "Karachi": ["Clifton Beach", "Quaid-e-Azam Mausoleum", "Pakistan Maritime Museum", "Mohatta Palace", "Frere Hall"],
    "Islamabad": ["Faisal Mosque", "Daman-e-Koh", "Pakistan Monument", "Lok Virsa Museum", "Rawal Lake"],
    "Rawalpindi": ["Raja Bazaar", "Ayub National Park", "Rawalpindi Cricket Stadium", "Jinnah Park", "Liaquat Bagh"],
    "Multan": ["Multan Fort", "Shrine of Shah Rukn-e-Alam", "Bahauddin Zakariya Shrine", "Ghanta Ghar", "Hussain Agahi Bazaar"],
    "Faisalabad": ["Clock Tower (Ghanta Ghar)", "Jinnah Garden", "Lyallpur Museum", "D Ground", "Chenab Club"],
    "Peshawar": ["Qissa Khwani Bazaar", "Bala Hisar Fort", "Peshawar Museum", "Sethi House", "Jamrud Fort"],
    "Quetta": ["Hanna Lake", "Quaid-e-Azam Residency (Ziarat)", "Hazarganji Chiltan Park", "Quetta Museum", "Spin Karez"],
    "Gilgit": ["Naltar Valley", "Rakaposhi View Point", "Kargah Buddha", "Gilgit Bridge", "Bagrot Valley"],
    "Skardu": ["Shigar Fort", "Shangrila Lake", "Sheosar Lake", "Satpara Lake", "Deosai National Park"],
    "Hunza": ["Attabad Lake", "Baltit Fort", "Altit Fort", "Eagle’s Nest", "Khunjerab Pass"],
    "Murree": ["Mall Road", "Patriata (New Murree)", "Kashmir Point", "Pindi Point", "Changla Gali"],
    "Naran": ["Lake Saif-ul-Malook", "Lalazar Plateau", "Babusar Top", "Dudipatsar Lake", "Kunhar River"],
    "Swat": ["Malam Jabba", "Fizagat Park", "Miandam Valley", "Ushu Forest", "Mahodand Lake"],
    "Neelum Valley": ["Kutton Waterfall", "Keran", "Sharda University Ruins", "Ratti Gali Lake", "Arang Kel"],
  };

  final List<String> tripPoints = ["Sightseeing", "Cultural Visit", "Trekking", "Camping", "Boating", "Shopping", "Bonfire"];

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('email');
    });
  }

  int _calculateExpectedPrice() {
    int price = (selectedSpots.length * 2500) + (selectedTripPoints.length * 500);
    if (price < 10000) price = 10000; // minimum expected bill
    return price;
  }

  void _submitCustomTrip() async {
    if (!_formKey.currentState!.validate() || selectedStartPointId == null || city == null) return;

    final expectedPrice = _calculateExpectedPrice();

    final data = {
      "userEmail": userEmail,
      "startPoint": selectedStartPointData?['address'],
      "city": city,
      "classType": selectedStartPointData?['classType'] ?? "Others",
      "spots": selectedSpots,
      "points": selectedTripPoints,
      "note": noteController.text,
      "expectedPrice": expectedPrice,
      "status": "pending",
      "createdAt": DateTime.now(),
    };

    await FirebaseFirestore.instance.collection("custom_reqs").add(data);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Custom trip request submitted! Admin will contact you soon.")),
    );

    setState(() {
      selectedStartPointId = null;
      selectedStartPointData = null;
      city = null;
      selectedSpots = [];
      selectedTripPoints = [];
      noteController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      bottomNavigationBar: CustomBottomBar(selectedIndex: _selectedIndex, onTap: _onItemTapped),
     body: userEmail == null
    ? const Center(child: CircularProgressIndicator())
    : SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Create Your Custom Trip",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Start Points Dropdown
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('points').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final points = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: selectedStartPointId,
                    decoration: const InputDecoration(
                      labelText: "Select Start Point",
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: points.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            "${data['address']} - ${data['cityName']}",
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (id) {
                      setState(() {
                        selectedStartPointId = id;
                        selectedStartPointData = points
                            .firstWhere((doc) => doc.id == id)
                            .data() as Map<String, dynamic>;
                      });
                    },
                    validator: (v) => v == null ? "Select a start point" : null,
                  );
                },
              ),
              const SizedBox(height: 12),

              // City Dropdown
              DropdownButtonFormField<String>(
                value: city,
                items: citySpots.keys
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    city = v;
                    selectedSpots = [];
                  });
                },
                validator: (v) => v == null ? "Select a city" : null,
                decoration: const InputDecoration(labelText: "Select City"),
              ),
              const SizedBox(height: 12),

              // Spots
              if (city != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Select Spots"),
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: citySpots[city]!
                            .map((s) => FilterChip(
                                  label: Text(s),
                                  selected: selectedSpots.contains(s),
                                  onSelected: (v) {
                                    setState(() {
                                      if (v) {
                                        selectedSpots.add(s);
                                      } else {
                                        selectedSpots.remove(s);
                                      }
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),

              // Trip Points
              const Text("Select Trip Highlights"),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tripPoints
                      .map((p) => FilterChip(
                            label: Text(p),
                            selected: selectedTripPoints.contains(p),
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  selectedTripPoints.add(p);
                                } else {
                                  selectedTripPoints.remove(p);
                                }
                              });
                            },
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Notes
              const Text("Add Note"),
              TextFormField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Any additional details...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 12),

              // Expected Price
              Text(
                "Expected Price: PKR ${_calculateExpectedPrice()}",
                style: const TextStyle(fontSize: 16, color: Colors.green),
              ),
              const SizedBox(height: 12),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitCustomTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38B6FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    "Submit Custom Trip (Admin will contact you soon)",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
               const SizedBox(height: 12),

              // Creative Features
              Text(
                "Why Choose Our Trips?",
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildAnimatedFeature(
                icon: Icons.flight_takeoff,
                title: "Comfortable Flights",
                description: "Affordable and safe air travel with trusted airlines.",
              ),
              _buildAnimatedFeature(
                icon: Icons.hotel,
                title: "Luxury Stays",
                description: "Handpicked hotels & resorts with the best amenities.",
              ),
              _buildAnimatedFeature(
                icon: Icons.explore,
                title: "Guided Tours",
                description: "Explore destinations with expert local guides.",
              ),
              _buildAnimatedFeature(
                icon: Icons.support_agent,
                title: "24/7 Support",
                description: "Travel assistance anytime, anywhere on your trip.",
              ),
        
            ],
          ),
        ),
      ),
 );
  }
   Widget _buildAnimatedFeature({required IconData icon, required String title, required String description}) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, (1 - value) * 20), child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF38B6FF), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(description, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

