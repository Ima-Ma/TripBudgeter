import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:trip_budgeter/components/Contact.dart';
import 'package:trip_budgeter/components/home.dart';
import 'package:trip_budgeter/components/login.dart';
import 'package:trip_budgeter/components/signup.dart';
import 'package:trip_budgeter/firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trip Budgeter',
      initialRoute: '/home',
     
        routes: {
        '/home': (context) => HomePage(),
        '/login': (context) => Login(),
        '/signup': (context) => Signup(),
        '/Contactus': (context) => Contact(),



      },

    );
  }
}

