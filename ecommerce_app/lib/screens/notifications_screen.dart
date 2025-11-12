import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _markNotificationAsRead(String docId) async {
    if (_user == null) return;

    final doc = await _firestore.collection('notifications').doc(docId).get();
    if (doc.exists && (doc.data()?['isRead'] == false)) {
      try {
        await _firestore.collection('notifications').doc(docId).update({
          'isRead': true,
        });
        print('Notification $docId marked as read.');
      } catch (e) {
        print('Error marking notification as read: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar now depends on the StreamBuilder result
      body: _user == null
          ? const Center(child: Text('Please log in.'))
          : StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('notifications')
            .where('userId', isEqualTo: _user!.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // Handle the case where the list is empty
            return Scaffold(
              appBar: AppBar(title: const Text('Notifications')),
              body: const Center(child: Text('You have no notifications.')),
            );
          }

          final docs = snapshot.data!.docs;

          // CRITICAL: Calculate the number of unread notifications
          final int unreadCount = docs.where((doc) => (doc.data() as Map<String, dynamic>)['isRead'] == false).length;
          final unreadDocs = docs.where((doc) => (doc.data() as Map<String, dynamic>)['isRead'] == false).toList();

          return Scaffold(
            appBar: AppBar(
              // Display the count in the AppBar title
              title: Text('Notifications'),

            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
              ),
            ],
          ),

            body: ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final timestamp = (data['createdAt'] as Timestamp?);
                final formattedDate = timestamp != null
                    ? DateFormat('MM/dd/yy hh:mm a').format(timestamp.toDate())
                    : '';

                final bool isRead = data['isRead'] == true;

                // --- MODIFICATION: CHANGE LEADING ICON TO TEXT/NUMBER ---
                return ListTile(
                  onTap: () {
                    _markNotificationAsRead(doc.id);
                  },
                  // Display the NEW/UNREAD indicator as bold text
                  leading: isRead
                      ? null // No leading widget if read
                      : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    data['title'] ?? 'No Title',
                    style: TextStyle(
                      fontWeight: !isRead ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '${data['body'] ?? ''}\n$formattedDate',
                  ),
                  isThreeLine: true,
                );
              },
            ),
          );
        },
      ),
    );
  }
}