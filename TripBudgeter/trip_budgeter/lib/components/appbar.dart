import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_budgeter/components/UserProfile.dart';
import 'package:trip_budgeter/components/Notifications.dart'; // Import your notifications page

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _CustomAppBarState extends State<CustomAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool isLoggedIn = false;
  String userName = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name') ?? "";
      isLoggedIn = userName.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIconButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: Colors.white),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF38B6FF),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animation.value,
                child: child,
              );
            },
            child: Image.asset(
              'assets/whiteicon.png',
              height: 80,
            ),
          ),
        ),
        title: Image.asset(
          'assets/whitelogo.png',
          height: 50,
        ),
        actions: [
          Row(
            children: [
             // User Dropdown
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      dropdownColor: Colors.white,
                      items: isLoggedIn
                          ? [
                              DropdownMenuItem(
                                value: 'profile',
                                child: Row(
                                  children: [
                                    const Icon(Icons.person,
                                        color: Colors.black),
                                    const SizedBox(width: 6),
                                    Text(userName,
                                        style: const TextStyle(
                                            color: Colors.black)),
                                  ],
                                ),
                              ),
                              const DropdownMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.black),
                                    SizedBox(width: 6),
                                    Text("Edit Profile",
                                        style:
                                            TextStyle(color: Colors.black)),
                                  ],
                                ),
                              ),
                              const DropdownMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.logOut,
                                        color: Colors.black),
                                    SizedBox(width: 6),
                                    Text("Logout",
                                        style:
                                            TextStyle(color: Colors.black)),
                                  ],
                                ),
                              ),
                            ]
                          : [
                              const DropdownMenuItem(
                                value: 'login',
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.logIn,
                                        color: Colors.black),
                                    SizedBox(width: 6),
                                    Text("Login",
                                        style: TextStyle(color: Colors.black)),
                                  ],
                                ),
                              ),
                              const DropdownMenuItem(
                                value: 'signup',
                                child: Row(
                                  children: [
                                    Icon(Icons.app_registration,
                                        color: Colors.black),
                                    SizedBox(width: 6),
                                    Text("Signup",
                                        style: TextStyle(color: Colors.black)),
                                  ],
                                ),
                              ),
                            ],
                      onChanged: (value) async {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const UserProfile()),
                          );
                        } else if (value == 'logout') {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(
                                context, '/login');
                          }
                        } else if (value == 'login') {
                          Navigator.pushReplacementNamed(context, '/login');
                        } else if (value == 'signup') {
                          Navigator.pushReplacementNamed(context, '/signup');
                        }
                      },
                    ),
                  ),
                ),
              ),
             // Notification Icon
              if (isLoggedIn)
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const Notifications()),
                    );
                  },
                  icon: const Icon(LucideIcons.bell, color: Colors.white),
                  tooltip: "Notifications",
                ),
              
            
            ],
          ),
        ],
      ),
    );
  }
}
