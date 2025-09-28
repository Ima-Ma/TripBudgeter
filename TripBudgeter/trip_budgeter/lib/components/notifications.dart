import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class Notifications extends StatefulWidget {
  const Notifications({Key? key}) : super(key: key);

  @override
  _NotificationsState createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  String? userEmail;
  bool loadingEmail = true;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('email');
      loadingEmail = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loadingEmail) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userEmail == null) {
      return const Scaffold(
        body: Center(
          child: Text("No user logged in", style: TextStyle(fontSize: 16)),
        ),
      );
    }

    final faqRef = FirebaseFirestore.instance
        .collection("FAQs")
        .where("email", isEqualTo: userEmail);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Notifications"),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF38B6FF),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: faqRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          final faqs = snapshot.data?.docs ?? [];

          if (faqs.isEmpty) {
            return const Center(
              child: Text(
                "No notifications found.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              final data = faqs[index].data() as Map<String, dynamic>;
              final question = data["question"] ?? "-";
              final reply = data["reply"] ?? "No reply yet";
              final questionTime = (data["timestamp"] as Timestamp?)?.toDate();
              final replyTime = (data["replyTimestamp"] as Timestamp?)?.toDate();

              return Card(
                shape: RoundedRectangleBorder(
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                child: Padding(
                  
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.question_answer, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            "Question",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(question, style: const TextStyle(fontSize: 14)),
                      if (questionTime != null)
                        Text(
                          "Asked: ${DateFormat('dd MMM yyyy, hh:mm a').format(questionTime)}",
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      const Divider(height: 16),
                      Row(
                        children: const [
                          Icon(Icons.reply, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            "Reply",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(reply, style: const TextStyle(fontSize: 14)),
                      if (replyTime != null)
                        Text(
                          "Replied: ${DateFormat('dd MMM yyyy, hh:mm a').format(replyTime)}",
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
