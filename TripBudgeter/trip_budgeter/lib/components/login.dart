import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:trip_budgeter/components/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  /// 🔹 Login with Email & Password
  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Authenticate user
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      // Fetch user details from Firestore
      final docRef = _firestore.collection("Users").doc(userCred.user!.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception("User not found in database");
      }

      final userData = doc.data()!;

      // ✅ Save details in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("uid", userCred.user!.uid);
      await prefs.setString("name", userData["name"] ?? "");
      await prefs.setString("email", userData["email"] ?? "");
      await prefs.setString("role", userData["role"] ?? "user");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login successful!")),
      );

      // Navigate to home
      Navigator.pushReplacementNamed(context, "/home");
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Auth Error: ${e.message}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF38B6FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // 🔹 App Logo
              Center(
                child: Image.asset("assets/whitelogo.png", height: 80),
              ),

              const SizedBox(height: 50),

              // 🔹 Login Container
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Login Header
                    Row(
                      children: [
                        Image.asset("assets/whiteicon.png",
                            height: 28, color: const Color(0xFF38B6FF)),
                        const SizedBox(width: 10),
                        Text(
                          "Welcome Back!",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF38B6FF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Email Field
                    TextField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(LucideIcons.mail,
                            color: Color(0xFF38B6FF)),
                        hintText: "Enter your email",
                        hintStyle: GoogleFonts.poppins(fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Password Field
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(LucideIcons.lock,
                            color: Color(0xFF38B6FF)),
                        hintText: "Enter your password",
                        hintStyle: GoogleFonts.poppins(fontSize: 14),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? LucideIcons.eyeOff
                                : LucideIcons.eye,
                            color: const Color(0xFF38B6FF),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: implement forgot password
                        },
                        child: Text(
                          "Forgot Password?",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF38B6FF),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 🔹 Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38B6FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 4,
                        ),
                        onPressed: _login,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                "Login",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🔹 Signup Option
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Signup(),
                            ),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(
                                text: "Sign Up",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF38B6FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
