import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerce_app/screens/admin_panel_screen.dart';
import 'package:ecommerce_app/screens/product_detail_screen.dart';
import '../widgets/product_card.dart';
import 'package:ecommerce_app/screens/order_history_screen.dart';
import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/screens/cart_screen.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/screens/profile_screen.dart'; // 1. ADD THIS
import 'package:ecommerce_app/widgets/notification_icon.dart';
import 'package:ecommerce_app/screens/chat_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _userRole = 'user'; // default role

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoadingRole = true;

  // FIX 1: Define the _currentUser variable
  User? _currentUser;


  @override
  void initState() {
    super.initState();
    // FIX 2: Initialize _currentUser
    _currentUser = _auth.currentUser;
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoadingRole = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _userRole = doc.data()!['role'] ?? 'user';
          _isLoadingRole = false;
        });
      } else {
        // 🧩 No document? Default to "user" and continue
        setState(() {
          _userRole = 'user';
          _isLoadingRole = false;
        });
      }
    } catch (e) {
      print("Error fetching user role: $e");
      setState(() => _isLoadingRole = false);
    }
  }


  // FIX 3: Remove the old logout function, as it is now in ProfileScreen
  // void _logout() async { await _auth.signOut(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        // 2. ADD this new title:
        title: Image.asset(
          'assets/images/app_logo.png', // 3. The path to your logo
          height: 40, // 4. Set a fixed height
        ),
        actions: [
          // 🛒 Cart (only visible for regular users)
          if (_userRole == 'user')
            Consumer<CartProvider>(
              builder: (context, cart, child) {
                return Badge(
                  label: Text(cart.items.length.toString()),
                  isLabelVisible: cart.items.isNotEmpty,
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                  ),
                );
              },
            ),

          // 2. --- ADD OUR NEW WIDGET ---
          const NotificationIcon(),


          IconButton(
            icon: const Icon(Icons.receipt_long), // A "receipt" icon
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),


          // 👑 Admin button (only visible for admins)
          if (_userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                );
              },
            ),

          // FIX 5: DELETED the old "Logout" IconButton

          // 6. ADD this new "Profile" IconButton
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],

      ),

      // 🛍 Product Grid
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No products found. Add some in the Admin Panel!'),
            );
          }

          final products = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(10.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3 / 4,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final productDoc = products[index];
              final productData = productDoc.data() as Map<String, dynamic>;

              return ProductCard(
                productName: productData['name'] ?? 'No Name',
                price: (productData['price'] ?? 0).toDouble(),
                imageUrl: productData['imageUrl'] ?? '',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        productData: productData,
                        productId: productDoc.id,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

        // 1. --- REPLACE YOUR 'floatingActionButton:' ---
        floatingActionButton: _userRole == 'user' && _currentUser != null
            ? StreamBuilder<DocumentSnapshot>( // 2. A new StreamBuilder
          // 3. Listen to *this user's* chat document
            stream: _firestore.collection('chats').doc(_currentUser!.uid).snapshots(),
            builder: (context, snapshot) {

              int unreadCount = 0;
              // 4. Check if the doc exists and has our count field
              if (snapshot.hasData && snapshot.data!.exists) {
                // Ensure data is not null before casting
                final data = snapshot.data!.data();
                if (data != null) {
                  unreadCount = (data as Map<String, dynamic>)['unreadByUserCount'] ?? 0;
                }
              }

              // 5. --- THE FIX for "trailing not defined" ---
              //    We wrap the FAB in the Badge widget
              return Badge(
                // 6. Show the count in the badge
                label: Text('$unreadCount'),
                // 7. Only show the badge if the count is > 0
                isLabelVisible: unreadCount > 0,
                // 8. The FAB is now the *child* of the Badge
                child: FloatingActionButton.extended(
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Contact Admin'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatRoomId: _currentUser!.uid,
                        ),
                      ),
                    );
                  },
                ),
              );
              // --- END OF FIX ---
            },
        )
            : null, // 9. If admin, don't show the FAB
    );
  }
}


