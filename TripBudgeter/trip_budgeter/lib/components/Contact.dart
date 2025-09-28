import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:trip_budgeter/components/appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:trip_budgeter/components/bottombar.dart';

class Contact extends StatefulWidget {
  const Contact({Key? key}) : super(key: key);

  @override
  _ContactState createState() => _ContactState();
}

class _ContactState extends State<Contact> {
    int _selectedIndex = 3;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  final TextEditingController _queryCtrl = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  /// 🔹 Submit Query Function
  Future<void> _submitQuery() async {
    if (_queryCtrl.text.trim().isEmpty) {
      Flushbar(
        message: "Please write your question first!",
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.redAccent,
      ).show(context);
      return;
    }

    try {
      setState(() => _isLoading = true);

      User? user = _auth.currentUser;
      if (user == null) {
        Flushbar(
          message: "You must be logged in to ask a question",
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.redAccent,
        ).show(context);
        return;
      }

      // ✅ User data from Firestore
      final userDoc =
          await _firestore.collection("Users").doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // ✅ Save question into FAQs collection
      await _firestore.collection("FAQs").add({
        "uid": user.uid,
        "name": userData["name"] ?? "",
        "email": userData["email"] ?? user.email,
        "question": _queryCtrl.text.trim(),
        "timestamp": FieldValue.serverTimestamp(),
      });

      _queryCtrl.clear();

      // ✅ Success message
      Flushbar(
        message: "Soon reply in your email.",
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green,
      ).show(context);
    } catch (e) {
      Flushbar(
        message: "Error: $e",
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.redAccent,
      ).show(context);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ Custom AppBar
      appBar: CustomAppBar(),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Heading with Icon
            Row(
              children: [
                const Icon(LucideIcons.messageCircle,
                    size: 24, color: Color(0xFF38B6FF)),
                const SizedBox(width: 8),
                Text(
                  "Ask Your Question",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF38B6FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ✅ Paragraph About TripBudgeter
            Text(
              "TripBudgeter helps you explore the best destinations with ease. "
              "From budget-friendly trips to luxurious adventures, our platform "
              "ensures you get the best deals on flights, hotels, and guided tours.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Query Field
            TextField(
              controller: _queryCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Write your question here...",
                hintStyle:
                    GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38B6FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                ),
                onPressed: _isLoading ? null : _submitQuery,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(LucideIcons.send, color: Colors.white, size: 18),
                label: Text(
                  _isLoading ? "Submitting..." : "Submit Query",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ✅ Section Heading
            Text(
              "Why Choose TripBudgeter?",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            // ✅ Features with icons
            Column(
              children: [
                _buildFeature(
                  icon: LucideIcons.plane,
                  title: "Easy Bookings",
                  description: "Book flights, hotels, and tours hassle-free.",
                ),
                _buildFeature(
                  icon: LucideIcons.wallet,
                  title: "Budget Friendly",
                  description: "Save more with our affordable packages.",
                ),
                _buildFeature(
                  icon: LucideIcons.map,
                  title: "Guided Tours",
                  description: "Explore safely with local expert guides.",
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ✅ Section Heading
            Row(
              children: [
                const Icon(LucideIcons.mapPin,
                    size: 22, color: Color(0xFF38B6FF)),
                const SizedBox(width: 6),
                Text(
                  "Our Destinations",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ✅ Image Cards
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildImageCard(
                  "assets/horizonhunza.jpg",
                  "Northern Areas Trips",
                  LucideIcons.mountain,
                  "Enjoy breathtaking views and adventurous treks in the Northern Areas.",
                ),
                _buildImageCard(
                  "assets/beachrealxationtrip.jpg",
                  "Beach & Relaxation",
                  LucideIcons.sun,
                  "Relax on golden beaches with beautiful sunsets and cool breezes.",
                ),
                _buildImageCard(
                  "assets/adv.jpg",
                  "Adventure & Fun Trips",
                  Icons.directions_run,
                  "Experience thrilling activities, fun rides, and endless adventure.",
                ),
                _buildImageCard(
                  "assets/histricial.jpg",
                  "Historical & Cultural",
                  LucideIcons.landmark,
                  "Explore the rich history and cultural heritage of iconic sites.",
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(selectedIndex: _selectedIndex, onTap: _onItemTapped),

    );
  }

  // ✅ Feature Widget
  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: const Color(0xFF38B6FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 4),
                Text(description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Image Card with Dialog
  Widget _buildImageCard(
      String imagePath, String title, IconData icon, String description) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.asset(imagePath,
                        fit: BoxFit.cover, height: 180, width: double.infinity),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(icon, color: const Color(0xFF38B6FF)),
                            const SizedBox(width: 8),
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          description,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            Icon(LucideIcons.mapPin, color: Colors.orange),
                            Icon(LucideIcons.plane, color: Colors.blue),
                            Icon(LucideIcons.wallet, color: Colors.green),
                          ],
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.asset(imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
