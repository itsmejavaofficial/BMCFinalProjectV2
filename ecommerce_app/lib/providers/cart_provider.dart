import 'package:flutter/foundation.dart'; // Gives us ChangeNotifier
import 'dart:async'; // 1. ADD THIS (for StreamSubscription)
import 'package:firebase_auth/firebase_auth.dart'; // 2. ADD THIS
import 'package:cloud_firestore/cloud_firestore.dart'; // 3. ADD THIS

class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  bool isSelected; // *** NEW: Selection state ***

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.isSelected = false, // *** NEW: Default to selected when added ***
  });

  // 1. UPDATED: A method to convert our CartItem object into a Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'isSelected': isSelected, // *** NEW: Include selection state ***
    };
  }

  // 2. UPDATED: A factory constructor to create a CartItem from a Map
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(), // Ensure price is double
      quantity: json['quantity'] as int? ?? 1, // Ensure quantity is int
      isSelected: json['isSelected'] as bool? ?? true, // *** NEW: Default true if missing ***
    );
  }
}

// 1. The CartProvider class "mixes in" ChangeNotifier
class CartProvider extends ChangeNotifier {

  // 2. This is the private list of items.
  List<CartItem> _items = [];

  // 5. New properties for auth and database
  String? _userId; // Will hold the current user's ID
  StreamSubscription? _authSubscription; // To listen to auth changes


  // 6. Get Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  // 3. A public "getter" to let widgets *read* the list of items
  List<CartItem> get items => _items;

  // 4. A public "getter" to calculate the total number of items
  int get itemCount {
    return _items.fold(0, (total, item) => total + item.quantity);
  }

  // --- NEW GETTERS FOR CHECKOUT SELECTION ---

  // NEW: Checks if all current items are selected
  bool get isAllSelected => _items.isNotEmpty && _items.every((item) => item.isSelected);

  // NEW: Calculate subtotal based ONLY on selected items
  double get selectedSubtotal {
    double total = 0.0;
    for (var item in _items.where((item) => item.isSelected)) { // Filter by isSelected
      total += (item.price * item.quantity);
    }
    return total;
  }

  // NEW: VAT based on selected items
  double get selectedVat {
    return selectedSubtotal * 0.12;
  }

  // NEW: FINAL total based on selected items (used for CheckoutCard)
  double get selectedTotalPriceWithVat {
    return selectedSubtotal + selectedVat;
  }

  // --- EXISTING TOTALS (for general cart overview, if needed) ---

  // RENAME 'totalPrice' to 'subtotal' (for ALL items, regardless of selection)
  double get subtotal {
    double total = 0.0;
    for (var item in _items) {
      total += (item.price * item.quantity);
    }
    return total;
  }

  // VAT for ALL items
  double get vat {
    return subtotal * 0.12;
  }

  // FINAL total for ALL items
  double get totalPriceWithVat {
    return subtotal + vat;
  }

  // --- NEW SELECTION LOGIC ---

  // NEW: Toggles the isSelected state for a single item
  void toggleItemSelection(String productId) {
    try {
      final item = _items.firstWhere((item) => item.id == productId);
      item.isSelected = !item.isSelected;
      _saveCart();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling selection: Item ID $productId not found.');
      }
    }
  }

  // NEW: Toggles selection state for ALL items
  void toggleAll(bool select) {
    for (var item in _items) {
      item.isSelected = select;
    }
    _saveCart();
    notifyListeners();
  }


  // --- EXISTING QUANTITY LOGIC (updated to call _saveCart) ---

  void increaseQuantity(String productId) {
    try {
      final item = _items.firstWhere((item) => item.id == productId);
      item.quantity++;
      _saveCart(); // Save the change
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error increasing quantity: Item ID $productId not found.');
      }
    }
  }

  void decreaseQuantity(String productId) {
    final itemIndex = _items.indexWhere((item) => item.id == productId);

    if (itemIndex != -1) {
      if (_items[itemIndex].quantity > 1) {
        _items[itemIndex].quantity--;
      } else {
        // Quantity is 1, so remove the item completely
        _items.removeAt(itemIndex);
      }
      _saveCart(); // Save the change whether quantity was decreased or item was removed
      notifyListeners();
    }
  }

  // --- FIREBASE AND LIFECYCLE ---

  CartProvider() {
    print('CartProvider initialized');
    initializeAuthListener();
  }

  void initializeAuthListener() {
    print('CartProvider auth listener initialized');
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User logged out, clearing cart.');
        _userId = null;
        _items = [];
      } else {
        print('User logged in: ${user.uid}. Fetching cart...');
        _userId = user.uid;
        _fetchCart();
      }
      notifyListeners();
    });
  }


  // Fetches the cart from Firestore
  Future<void> _fetchCart() async {
    if (_userId == null) return;

    try {
      final doc = await _firestore.collection('userCarts').doc(_userId).get();

      if (doc.exists && doc.data()!['cartItems'] != null) {
        final List<dynamic> cartData = doc.data()!['cartItems'];

        // Convert the list of Maps into our List<CartItem>
        _items = cartData.map((item) => CartItem.fromJson(item)).toList();
        print('Cart fetched successfully: ${_items.length} items');
      } else {
        _items = [];
      }
    } catch (e) {
      print('Error fetching cart: $e');
      _items = [];
    }
    notifyListeners();
  }

  // Saves the current local cart to Firestore
  Future<void> _saveCart() async {
    if (_userId == null) return;

    try {
      // Convert our List<CartItem> into a List<Map> (now including isSelected)
      final List<Map<String, dynamic>> cartData =
      _items.map((item) => item.toJson()).toList();

      await _firestore.collection('userCarts').doc(_userId).set({
        'cartItems': cartData,
      });
      print('Cart saved to Firestore');
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  // --- CORE CART MODIFICATION METHODS ---

  // UPDATED addItem LOGIC: New items default to isSelected = true
  void addItem(String id, String name, double price, int quantity) {
    var index = _items.indexWhere((item) => item.id == id);

    if (index != -1) {
      _items[index].quantity += quantity;
      // Note: We don't change the isSelected state if it already exists.
    } else {
      // New item is added, defaulting isSelected to true
      _items.add(CartItem(
        id: id,
        name: name,
        price: price,
        quantity: quantity,
        isSelected: false,
      ));
    }

    _saveCart();
    notifyListeners();
  }

  // The "Remove Item from Cart" logic (for swipe/manual removal)
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    _saveCart();
    notifyListeners();
  }

  // UPDATED: Creates an order using ONLY the selected items
  Future<void> placeOrder() async {
    final List<CartItem> selectedItems = _items.where((item) => item.isSelected).toList();

    double sub = selectedItems.fold(0.0, (total, item) => total + (item.price * item.quantity));
    double v = sub * 0.12;
    double total = sub + v;


    // Check if we have a user and SELECTED items
    if (_userId == null || selectedItems.isEmpty) {
      throw Exception('No items selected for checkout.');
    }

    try {
      // 1. Calculate totals for SELECTED items
      double sub = selectedItems.fold(0.0, (total, item) => total + (item.price * item.quantity));
      double v = sub * 0.12;
      double total = sub + v;
      int count = selectedItems.fold(0, (total, item) => total + item.quantity);

      // 2. Convert SELECTED items to a list of Maps
      final List<Map<String, dynamic>> orderItemsData =
      selectedItems.map((item) => item.toJson()).toList();

      // 3. Create a new document in the 'orders' collection
      await _firestore.collection('orders').add({
        'userId': _userId,
        'items': orderItemsData, // List of SELECTED item maps
        'subtotal': sub,
        'vat': v,
        'totalPriceWithVat': total, // Renamed for consistency with getter
        'itemCount': count,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print('Error placing order: $e');
      rethrow; // Use rethrow to allow the calling widget to catch the error
    }
  }

  // *** CRITICAL LOGIC FOR SELECTIVE REMOVAL ***
  // This method removes only the items that were selected for purchase.
  Future<void> removeSelectedItems() async {
    if (_userId == null) return;

    // 1. Remove all selected items locally
    _items.removeWhere((item) => item.isSelected);

    try {
      // 2. Save the remaining (unselected) items back to Firestore
      await _saveCart();
      print('Selected items removed, unselected items retained in Firestore.');
    } catch (e) {
      print('Error while removing selected items: $e');
    }

    // 3. Update the UI
    notifyListeners();
  }


  Future<void> unsafeClearAllCart() async {
    _items = [];
    if (_userId != null) {
      try {
        await _firestore.collection('userCarts').doc(_userId).set({
          'cartItems': [],
        });
        // Renamed log to confirm this is the intentional, full clear
        print('Firestore: UNSAFELY cleared all cart data.');
      } catch (e) {
        print('Error clearing Firestore cart: $e');
      }
    }
    notifyListeners();
  }

// ORIGINAL: Future<void> clearCart() async { ... } (This block is what you had)
// We are replacing the old clearCart() with the explicit unsafeClearAllCart() above.
// If you must keep a clearCart() function, point it to the unsafe one:
  Future<void> clearCart() => unsafeClearAllCart();

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}