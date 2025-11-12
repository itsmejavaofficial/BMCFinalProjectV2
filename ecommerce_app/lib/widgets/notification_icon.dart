import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerce_app/screens/notifications_screen.dart';

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Container();
    }

    // CRITICAL: The StreamBuilder must wrap the Badge and IconButton
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),

      builder: (context, snapshot) {
        // unreadCount is defined and ONLY accessible within this builder scope
        final int unreadCount = snapshot.data?.docs.length ?? 0;

        return Badge(
          // unreadCount is correctly used here
          label: Text(
            unreadCount.toString(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          // unreadCount is correctly used here
          isLabelVisible: unreadCount > 0,

          child: IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ); // <--- The Badge is the widget returned by the builder
      },
    ); // <--- The StreamBuilder is the main widget returned by NotificationIcon
  }
}