import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatUser currentUser = ChatUser(id: "1", firstName: "You");
  final ChatUser adminUser = ChatUser(id: "2", firstName: "Admin");

  List<ChatMessage> messages = [
    ChatMessage(
      text: "Hello! 👋 How can we help you today?",
      user: ChatUser(id: "2", firstName: "Admin"),
      createdAt: DateTime.now(),
    ),
  ];

  String? userEmail;
  String? userName;
  String? uid;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('email') ?? "unknown@example.com";
      userName = prefs.getString('name') ?? "User";
      uid = prefs.getString('uid') ?? "unknown_uid";
    });
  }

  void _sendMessage(ChatMessage message) async {
    setState(() {
      messages.insert(0, message);
    });

    // Save user message to Firestore FAQs collection
    if (userEmail != null && userName != null && uid != null) {
      await FirebaseFirestore.instance.collection("FAQs").add({
        "email": userEmail,
        "name": userName,
        "question": message.text,
        "reply": "", // initially empty
        "replyTimestamp": null,
        "timestamp": DateTime.now(),
        "uid": uid,
      });
    }

    // Optional: simulate admin reply locally in chat
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        messages.insert(
          0,
          ChatMessage(
            text: "Got it ✅ We’ll get back to you shortly!",
            user: adminUser,
            createdAt: DateTime.now(),
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with Us"),
        backgroundColor: const Color(0xFF38B6FF),
      ),
      body: DashChat(
        currentUser: currentUser,
        onSend: _sendMessage,
        messages: messages,
        inputOptions: InputOptions(
          alwaysShowSend: true,
          sendButtonBuilder: (onSend) => IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF38B6FF)),
            onPressed: onSend,
          ),
        ),
        messageOptions: const MessageOptions(
          currentUserContainerColor: Color(0xFF38B6FF),
          currentUserTextColor: Colors.white,
          containerColor: Colors.white,
          textColor: Colors.black87,
        ),
      ),
    );
  }
}
