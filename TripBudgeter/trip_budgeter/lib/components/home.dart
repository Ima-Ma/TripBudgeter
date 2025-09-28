import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trip_budgeter/components/ChatPage.dart';
import 'package:trip_budgeter/components/TripsByStartPointPage.dart';
import 'package:trip_budgeter/components/appbar.dart';
import 'package:trip_budgeter/components/bottombar.dart';
import 'TicketDetailPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripsRef = FirebaseFirestore.instance.collection("upcoming_trips");

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Popular Trips",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF38B6FF),
                    child: Image.asset("assets/icon.png", height: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Search
              TextField(
                decoration: InputDecoration(
                  hintText: "Search destinations...",
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Image.asset("assets/icon.png", height: 20),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                ),
              ),
              const SizedBox(height: 12),

              // Horizontal Trips List
              SizedBox(
                height: 140,
                child: StreamBuilder<QuerySnapshot>(
                  stream: tripsRef.orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final trips = snapshot.data!.docs;
                    if (trips.isEmpty) return const Center(child: Text("No trips found."));

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        final trip = trips[index].data() as Map<String, dynamic>;
                        final firstImage = (trip["images"] as List).isNotEmpty ? trip["images"][0] : null;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TicketDetailPage(
                                  ticketData: trip,
                                  ticketId: trips[index].id,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width / 3 - 20,
                            margin: const EdgeInsets.only(right: 12),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: firstImage != null
                                      ? Image.network(
                                          firstImage,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 120,
                                        )
                                      : Container(
                                          color: Colors.grey.shade300,
                                          width: double.infinity,
                                          height: 120,
                                        ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Text(
                                    trip["city"] ?? trip["title"] ?? "Unknown",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
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
              ),
              const SizedBox(height: 12),

              // Trip Plans
              Text(
                "Trip Plans",
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance.collection("points").snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
    final points = snapshot.data!.docs;
    if (points.isEmpty) return const Center(child: Text("No points found."));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: points.take(4).map((pointDoc) {
        final point = pointDoc.data() as Map<String, dynamic>;
        final address = point["address"] ?? "Unknown";
        final pointType = point["pointType"] ?? "";

        return Expanded(
          child: GestureDetector(
            onTap: () {
              // Navigate to new page showing upcoming trips with startPoint = cityName
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TripsByStartPointPage(startPoint: address),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF38B6FF).withOpacity(0.08),
                border: Border.all(color: const Color(0xFF38B6FF).withOpacity(0.4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset("assets/3icon.png", height: 30),
                  const SizedBox(height: 6),
                  Text(
                    address,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    pointType,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  },
),

              const SizedBox(height: 12),

              // Carousel
              StreamBuilder<QuerySnapshot>(
                stream: tripsRef.orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final trips = snapshot.data!.docs;
                  if (trips.isEmpty) return const Center(child: Text("No trips found."));

                  return CarouselSlider(
                    options: CarouselOptions(
                      height: 150,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 3),
                      enlargeCenterPage: true,
                      viewportFraction: 0.75,
                    ),
                    items: trips.map((tripDoc) {
                      final trip = tripDoc.data() as Map<String, dynamic>;
                      final firstImage = (trip["images"] as List).isNotEmpty ? trip["images"][0] : null;

                      return Builder(
                        builder: (context) {
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 6,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: firstImage != null
                                      ? Image.network(
                                          firstImage,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        )
                                      : Container(color: Colors.grey.shade300),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.black.withOpacity(0.3),
                                  ),
                                ),
                                Positioned(
                                  left: 16,
                                  right: 16,
                                  bottom: 16,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            trip["title"] ?? "Unknown Trip",
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            trip["duration"] ?? "-",
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      CircleAvatar(
                                        backgroundColor: Colors.white.withOpacity(0.8),
                                        child: IconButton(
                                          icon: const Icon(
                                            LucideIcons.info,
                                            size: 16,
                                            color: Colors.black87,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => TicketDetailPage(
                                                  ticketData: trip,
                                                  ticketId: tripDoc.id,
                                                ),
                                              ),
                                            );
                                          },
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
                    }).toList(),
                  );
                },
              ),
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
      bottomNavigationBar: CustomBottomBar(selectedIndex: _selectedIndex, onTap: _onItemTapped),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF38B6FF),
        icon: Image.asset("assets/icon.png", height: 22),
        label: const Text(
          "Chat with Us",
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatPage()));
        },
      ),
    );
  }

  // Mini trip box
  Widget _buildMiniTripBox(String title, String iconPath) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFF38B6FF).withOpacity(0.08),
          border: Border.all(color: const Color(0xFF38B6FF).withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(iconPath, height: 30),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // Animated feature
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
