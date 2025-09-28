import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';

import 'package:trip_budgeter/components/Contact.dart';
import 'package:trip_budgeter/components/CustomTrip.dart';
import 'package:trip_budgeter/components/YourBooking.dart';
import 'package:trip_budgeter/components/home.dart';
import 'package:trip_budgeter/components/upcomingTrips.dart';

class CustomBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onTap;

  const CustomBottomBar({
    super.key,
    required this.selectedIndex,
    this.onTap,
  });

  /// 🔹 Check if user is logged in
  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('name') != null && prefs.getString('name')!.isNotEmpty;
  }

  /// 🔹 Show Flushbar Alert
  void _showLoginAlert(BuildContext context) {
    Flushbar(
      message: "You cannot access this page without logging in!",
      icon: const Icon(Icons.info, color: Colors.white),
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.redAccent,
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  /// 🔹 Handle navigation with login check
  Future<void> _navigateTo(BuildContext context, Widget page) async {
    final loggedIn = await _isLoggedIn();
    if (loggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    } else {
      _showLoginAlert(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF38B6FF),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: SalomonBottomBar(
              currentIndex: selectedIndex,
              onTap: (index) async {
                switch (index) {
                  case 0: // Home
                    await _navigateTo(context, const HomePage());
                    break;
                  case 1: // Upcoming Trips
                    await _navigateTo(context, const UpcomingTrips());
                    break;
                  case 2: // Your Booking / Trip Status
                    await _navigateTo(context, const YourBooking());
                    break;
                  case 3: // Contact
                    await _navigateTo(context, const Contact());
                    break;
                  case 4: // Custom Trip
                    await _navigateTo(context, const CustomTrip());
                    break;
                }

                if (onTap != null) onTap!(index);
              },
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              items: [
                SalomonBottomBarItem(
                  icon: selectedIndex == 0
                      ? Image.asset("assets/whiteicon.png", height: 30)
                      : const Icon(LucideIcons.home),
                  title: const Text("Home"),
                  selectedColor: Colors.white,
                ),
                SalomonBottomBarItem(
                   icon: selectedIndex == 1
                      ? Image.asset("assets/whiteicon.png", height: 30)
                      : const Icon(LucideIcons.map), // Better for trips/destinations
                  title: const Text(" Trips"),
                  selectedColor: Colors.white,
                ),
                SalomonBottomBarItem(
                   icon: selectedIndex == 2
                      ? Image.asset("assets/whiteicon.png", height: 30)
                      :const Icon(LucideIcons.clipboard), // Trip status / bookings
                  title: const Text(" Status"),
                  selectedColor: Colors.white,
                ),
                SalomonBottomBarItem(
                   icon: selectedIndex == 3
                      ? Image.asset("assets/whiteicon.png", height: 30)
                      : const Icon(LucideIcons.phone), // Contact
                  title: const Text("Contact"),
                  selectedColor: Colors.white,
                ),
                SalomonBottomBarItem(
                   icon: selectedIndex == 4
                      ? Image.asset("assets/whiteicon.png", height: 30)
                      : const Icon(LucideIcons.edit2), // Custom Trip
                  title: const Text("Custom"),
                  selectedColor: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
