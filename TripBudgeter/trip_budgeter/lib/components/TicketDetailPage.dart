import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trip_budgeter/components/BookingPage.dart';

class TicketDetailPage extends StatefulWidget {
  final Map<String, dynamic> ticketData;
  final String ticketId;

  const TicketDetailPage({super.key, required this.ticketData, required this.ticketId});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  late List<String> images;
  String? selectedImage;

  @override
  void initState() {
    super.initState();
    images = List<String>.from(widget.ticketData["images"] ?? []);
    selectedImage = images.isNotEmpty ? images.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.ticketData;

    return Scaffold(
      appBar: AppBar(
        title: Text(trip["title"] ?? "Trip Detail"),
        backgroundColor: const Color(0xFF38B6FF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  selectedImage!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),

            // Horizontal image selector
            if (images.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length > 4 ? 4 : images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final img = images[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedImage = img;
                        });
                      },
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              img,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (selectedImage == img)
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF38B6FF),
                                  width: 3,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),

            Text(
              trip["title"] ?? "-",
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              trip["city"] ?? "-",
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              "Duration: ${trip["duration"] ?? "-"}",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              "Start: ${trip["startDate"]?.toDate() ?? "-"}",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              "End: ${trip["endDate"]?.toDate() ?? "-"}",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              "Price: ${trip["price"] ?? "-"}",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Spots
            if (trip["spots"] != null && (trip["spots"] as List).isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Spots:", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  Wrap(
                    spacing: 6,
                    children: List<Widget>.from((trip["spots"] as List).map(
                      (spot) => Chip(label: Text(spot)),
                    )),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            // Points
            if (trip["points"] != null && (trip["points"] as List).isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Activities:", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  Wrap(
                    spacing: 6,
                    children: List<Widget>.from((trip["points"] as List).map(
                      (point) => Chip(label: Text(point)),
                    )),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Book Now Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingPage(
                        tripData: trip,
                        tripId: widget.ticketId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.book_online, color: Colors.white),
                label: const Text("Book Now", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38B6FF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
