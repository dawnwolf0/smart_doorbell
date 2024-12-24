import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/receiver_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ReceiverApp());
}

class ReceiverApp extends StatelessWidget {
  const ReceiverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doorbell Receiver',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ReceiverHomeScreen(),
    );
  }
}

