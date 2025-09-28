import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  /// 🔹 Email & Password Signup
  Future<void> _signup() async {
    try {
      setState(() => _isLoading = true);

      // Create user in Firebase Auth
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      // Add user info in Firestore including password (demo purposes only ⚠️)
      await _firestore.collection("Users").doc(userCred.user!.uid).set({
        "name": _nameCtrl.text.trim(),
        "email": _emailCtrl.text.trim(),
        "password": _passwordCtrl.text.trim(), // ⚠️ Only for demo
        "role": "user",
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup successful!")),
      );

      // Navigate to login page or homepage
      Navigator.pushReplacementNamed(context, "/login");
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
      backgroundColor: const Color(0xFF38B6FF), // primary blue
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // 🔹 Logo
              Center(
                child: Column(
                  children: [
                    Image.asset("assets/whitelogo.png", height: 80),
                    const SizedBox(height: 10),
                    Text(
                      "Create Account",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 🔹 Signup Card
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
                  children: [
                    // Name Field
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(LucideIcons.user,
                            color: Color(0xFF38B6FF)),
                        hintText: "Full Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Email Field
                    TextField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(LucideIcons.mail,
                            color: Color(0xFF38B6FF)),
                        hintText: "Email",
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
                        hintText: "Password",
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
                    const SizedBox(height: 20),

                    // Signup Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38B6FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _signup,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                "Sign Up",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
