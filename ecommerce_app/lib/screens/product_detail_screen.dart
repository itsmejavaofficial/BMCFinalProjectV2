import 'package:flutter/material.dart';
import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:provider/provider.dart';

// 1. Changed from StatelessWidget to StatefulWidget
class ProductDetailScreen extends StatefulWidget {

  final Map<String, dynamic> productData;
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productData,
    required this.productId,
  });

  @override
  // 2. Created the State class
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

// 3. The new State class
class _ProductDetailScreenState extends State<ProductDetailScreen> {

  // 4. ADD OUR NEW STATE VARIABLE FOR QUANTITY, starting at 1
  int _quantity = 1;

  // 1. ADD THIS FUNCTION
  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }


  // 2. ADD THIS FUNCTION
  void _decrementQuantity() {
    // We don't want to go below 1
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }


  // 5. The build method is now inside the State class
  @override
  Widget build(BuildContext context) {
    // 1. Access productData using 'widget.'
    final String name = widget.productData['name'];
    final String description = widget.productData['description'];
    final String imageUrl = widget.productData['imageUrl'];
    final double price = (widget.productData['price'] as num? ?? 0.0).toDouble();

    // 2. Get the CartProvider (same as before)
    final cart = Provider.of<CartProvider>(context, listen: false);


    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Product image
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              )
            else
              Container(
                width: double.infinity,
                height: 300,
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 100),
              ),

            const SizedBox(height: 16),

            // 📋 Product info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₱${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.green,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(description),
                  const SizedBox(height: 30),


                  // 4. --- NEW QUANTITY SELECTOR SECTION ---
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 5. DECREMENT BUTTON
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove),
                        onPressed: _decrementQuantity, // Calls our new state function
                      ),

                      // 6. QUANTITY DISPLAY
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '$_quantity', // 7. Displays our state variable
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),

                      // 8. INCREMENT BUTTON
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: _incrementQuantity, // Calls our new state function
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // --- END OF NEW SECTION ---


                  // 🛒 Add to Cart button
                  ElevatedButton.icon(
                    onPressed: () {
                      // 10. --- UPDATED LOGIC ---
                      // We now pass the _quantity from our state
                      cart.addItem(
                        widget.productId,
                        name,
                        price,
                        _quantity, // 11. Pass the selected quantity
                      );

                      // 12. Feedback Snackbar with quantity
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added $_quantity x $name to cart!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}