import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:trip_budgeter/components/appbar.dart';

/// Custom CNIC Input Formatter
class CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length > 13) {
      digits = digits.substring(0, 13); // limit 13 digits
    }

    String newText = '';
    for (int i = 0; i < digits.length; i++) {
      newText += digits[i];
      if (i == 4 || i == 11) {
        newText += '-';
      }
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _cnicCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();

  String? _selectedGender;
  LatLng _selectedLocation = LatLng(24.8607, 67.0011); // Karachi default
  double _zoom = 14.0;
  bool _isSaving = false;

  List<dynamic> _searchResults = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameCtrl.text = prefs.getString('name') ?? '';
      _emailCtrl.text = prefs.getString('email') ?? '';
      _phoneCtrl.text = prefs.getString('phone') ?? '';
      _cnicCtrl.text = prefs.getString('cnic') ?? '';
      _locationCtrl.text = prefs.getString('location') ?? '';
      _selectedGender = prefs.getString('gender');

      double? lat = prefs.getDouble('lat');
      double? lng = prefs.getDouble('lng');
      if (lat != null && lng != null) {
        _selectedLocation = LatLng(lat, lng);
        if (_locationCtrl.text.isEmpty) {
          _locationCtrl.text =
              "${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}";
        }
      }
    });
  }

  Future<void> _searchLocation(String query) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&countrycodes=pk&format=json');
    final response = await http.get(url, headers: {
      'User-Agent': 'FlutterApp/1.0 (contact@example.com)',
    });

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        _searchResults = data;
      });
    }
  }

  void _onAreaSelect(Map<String, dynamic> item) {
    double lat = double.parse(item['lat']);
    double lon = double.parse(item['lon']);
    String displayName = item['display_name'];

    setState(() {
      _selectedLocation = LatLng(lat, lon);
      _zoom = 15;
      _locationCtrl.text = displayName;
      _searchResults = [];
    });

    _mapController.move(_selectedLocation, _zoom);
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and Email cannot be empty!")),
      );
      return;
    }

    // ✅ CNIC validation
    final cnicPattern = RegExp(r'^\d{5}-\d{7}-\d{1}$');
    if (!cnicPattern.hasMatch(_cnicCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Invalid CNIC format! Use xxxxx-xxxxxxx-x")),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your Gender!")),
      );
      return;
    }

    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _nameCtrl.text);
    await prefs.setString('email', _emailCtrl.text);
    await prefs.setString('phone', _phoneCtrl.text);
    await prefs.setString('gender', _selectedGender!);
    await prefs.setString('cnic', _cnicCtrl.text);
    await prefs.setString('location', _locationCtrl.text);
    await prefs.setDouble('lat', _selectedLocation.latitude);
    await prefs.setDouble('lng', _selectedLocation.longitude);

    // Save to Firestore
    await _firestore.collection("UserProfiles").doc(_emailCtrl.text.trim()).set({
      "name": _nameCtrl.text.trim(),
      "email": _emailCtrl.text.trim(),
      "phone": _phoneCtrl.text.trim(),
      "gender": _selectedGender,
      "cnic": _cnicCtrl.text.trim(),
      "location": _locationCtrl.text.trim(),
      "lat": _selectedLocation.latitude,
      "lng": _selectedLocation.longitude,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile saved successfully!")),
    );
  }

  void _pickLocation(LatLng pos) {
    setState(() {
      _selectedLocation = pos;
      _locationCtrl.text =
          "${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}";
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    void Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF38B6FF)),
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF38B6FF), width: 2),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      items: ["Male", "Female"].map((gender) {
        return DropdownMenuItem(
          value: gender,
          child: Row(
            children: [
              Icon(
                gender == "Male" ? Icons.man : Icons.woman_outlined,
                color: const Color(0xFF38B6FF),
              ),
              const SizedBox(width: 8),
              Text(gender, style: GoogleFonts.poppins(fontSize: 14)),
            ],
          ),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedGender = val),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.person, color: Color(0xFF38B6FF)),
        labelText: "Gender",
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Profile Picture Section
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundImage: const NetworkImage(
                        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT1rTLeQraa9s-Rkj2_KMPOzh30CwK1G2D85A&s"),
                    backgroundColor: Colors.grey[300],
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF38B6FF),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 18),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Card container for form
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "Personal Information",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Trip Budgeter - Manage your travel profile",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                        controller: _nameCtrl,
                        label: "Full Name",
                        icon: Icons.person_outline),
                    const SizedBox(height: 12),
                    _buildTextField(
                        controller: _emailCtrl,
                        label: "Email",
                        icon: Icons.email_outlined),
                    const SizedBox(height: 12),
                    _buildTextField(
                        controller: _phoneCtrl,
                        label: "Phone Number",
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _buildGenderDropdown(),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _cnicCtrl,
                      label: "CNIC Number (xxxxx-xxxxxxx-x)",
                      icon: Icons.credit_card,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CnicInputFormatter()],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _locationCtrl,
                      label: "Search Area",
                      icon: Icons.search,
                      onChanged: (val) {
                        if (val.length > 3) _searchLocation(val);
                      },
                    ),
                    const SizedBox(height: 8),
                    ..._searchResults.map((item) => ListTile(
                          leading: const Icon(Icons.location_on,
                              color: Color(0xFF38B6FF)),
                          title: Text(item['display_name'],
                              style: GoogleFonts.poppins(fontSize: 13)),
                          onTap: () => _onAreaSelect(item),
                        )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text("Pick Your Location",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 300,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: _zoom,
                    onTap: (tapPos, latlng) => _pickLocation(latlng),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_pin,
                              color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38B6FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("Save Profile",
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
