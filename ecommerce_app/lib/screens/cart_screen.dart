import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/cart_provider.dart';
import 'payment_screen.dart'; // Import PaymentScreen

// --- CartScreen (Integrates Provider and new UI structure) ---
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We listen: true, so the list and total update
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            const Text(
              "Shopping Cart",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            Text(
              "${cart.items.length} items",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text('Your cart is empty.', style: TextStyle(fontSize: 16)))
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0), // Removed horizontal padding here
        child: ListView.builder(
          itemCount: cart.items.length,
          itemBuilder: (context, index) {
            final cartItem = cart.items[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Dismissible(
                key: Key(cartItem.id),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  cart.removeItem(cartItem.id);
                  // Optional: Show a snackbar
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${cartItem.name} removed from cart'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                background: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE6E6),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Spacer(),
                      // Using SvgPicture.string for the trash icon
                      SvgPicture.string(trashIcon),
                    ],
                  ),
                ),
                child: CartCard(
                  id: cartItem.id, // Pass ID for quantity adjustment
                  name: cartItem.name,
                  price: cartItem.price,
                  quantity: cartItem.quantity,
                  // New property (assuming CartProvider implementation):
                  isSelected: cartItem.isSelected,
                ),
              ),
            );
          },
        ),
      ),
      // Uses the new bottom card with Provider data and navigation logic
      bottomNavigationBar: CheckoutCard(cart: cart),
    );
  }
}

// --- CartCard (Updated to include Checkbox) ---
class CartCard extends StatelessWidget {
  const CartCard({
    Key? key,
    required this.id, // New: Product ID for provider interaction
    required this.name,
    required this.price,
    required this.quantity,
    required this.isSelected, // New: Selection state
  }) : super(key: key);

  final String id;
  final String name;
  final double price;
  final int quantity;
  final bool isSelected; // New

  @override
  Widget build(BuildContext context) {
    // Get access to the CartProvider without rebuilding the whole widget
    final cart = Provider.of<CartProvider>(context, listen: false);

    // Get the first initial of the name, handling empty string case
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- NEW: Checkbox for selection ---
        Padding(
          padding: const EdgeInsets.only(right: 8.0, left: 12.0, top: 20.0),
          child: Checkbox(
            value: isSelected,
            onChanged: (value) {
              cart.toggleItemSelection(id); // Assumes this method exists
            },
            activeColor: const Color(0xFFFF7643),
          ),
        ),
        // --- END NEW: Checkbox ---

        // --- Product Initial Placeholder ---
        SizedBox(
          width: 88,
          child: AspectRatio(
            aspectRatio: 0.88,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF7643), // Primary color for visibility
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20), // Spacing after the image container
        // --- End Product Initial Placeholder ---
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                maxLines: 2,
              ),
              const SizedBox(height: 8),

              // --- Price Display ---
              Text.rich(
                TextSpan(
                  // Display total price for item
                  text: "₱${(price * quantity).toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF7643),
                      fontFamily: 'Roboto'),
                  children: [
                    TextSpan(
                      // Display quantity
                        text: " x$quantity",
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // --- Quantity Control Row (New) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    // Set a fixed width for the quantity control box
                    width: 100,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Decrease Button (-)
                        _buildQuantityButton(
                          icon: Icons.remove,
                          // Disable if quantity is 1
                          onPressed: quantity > 1
                              ? () => cart.decreaseQuantity(id)
                              : null,
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        // Increase Button (+)
                        _buildQuantityButton(
                          icon: Icons.add,
                          onPressed: () => cart.increaseQuantity(id),
                        ),
                      ],
                    ),
                  ),
                ],
              )
              // --- End Quantity Control Row ---
            ],
          ),
        )
      ],
    );
  }

  // Helper widget for the +/- buttons
  Widget _buildQuantityButton({required IconData icon, required VoidCallback? onPressed}) {
    return SizedBox(
      height: 30,
      width: 30,
      child: MaterialButton(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: Colors.white,
        elevation: 0,
        disabledColor: Colors.grey.shade200,
        onPressed: onPressed,
        child: Icon(icon, size: 16, color: onPressed != null ? Colors.black : Colors.grey),
      ),
    );
  }
}

// --- CheckoutCard (Updated for Selective Removal) ---
class CheckoutCard extends StatelessWidget {
  const CheckoutCard({
    Key? key,
    required this.cart,
  }) : super(key: key);

  final CartProvider cart;

  @override
  Widget build(BuildContext context) {
    // Use selected item totals
    final double subtotal = cart.selectedSubtotal;
    final double vat = cart.selectedVat;
    final double totalAmount = cart.selectedTotalPriceWithVat;
    final bool isAnyItemSelected = cart.items.any((item) => item.isSelected);

    // Total selected items count for display on the button
    final int selectedItemCount = cart.items.where((item) => item.isSelected).length;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -15),
            blurRadius: 20,
            color: const Color(0xFFDADADA).withOpacity(0.15),
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Price Breakdown ---
            Column(
              children: [
                // Row 1: Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    Text('₱${subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14, fontFamily: 'Roboto')),
                  ],
                ),
                const SizedBox(height: 4),

                // Row 2: VAT
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                        'VAT (12%):',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.bold)
                    ),
                    Text('₱${vat.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 14, fontFamily: 'Roboto')),
                  ],
                ),
                const Divider(height: 16, thickness: 0.5),
              ],
            ),
            // --- End Price Breakdown ---

            // --- Bottom Row: All Checkbox, Total, and Checkout Button ---
            Row(
              children: [
                // NEW: All Checkbox (based on the image)
                Row(
                  children: [
                    Checkbox(
                      value: cart.isAllSelected,
                      onChanged: (value) {
                        cart.toggleAll(value ?? false);
                      },
                      activeColor: const Color(0xFFFF7643),
                    ),
                    const Text('All'),
                  ],
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: "Total:\n",
                      children: [
                        TextSpan(
                          text: "₱${totalAmount.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    // Disable if no items are selected
                    onPressed: isAnyItemSelected
                        ? () async { // Make onPressed async
                      try {
                        // 2. Navigate to the Payment Screen
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(
                              totalAmount: totalAmount,
                            ),
                          ),
                        );

                        // 3. CRITICAL: Remove only the selected items after successful order/navigation
                        await cart.removeSelectedItems();

                      } catch (e) {
                        // Handle order placement error (e.g., show a Snackbar)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().contains('No items selected')
                              ? 'Please select items to checkout.'
                              : 'Failed to place order: $e')),
                        );
                      }
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFFFF7643),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    // Display the count of selected items
                    child: Text("Check Out ($selectedItemCount)"),
                  ),
                ),
              ],
            ),
            // --- End Bottom Row ---
          ],
        ),
      ),
    );
  }
}

// --- SVG Icons (Unchanged) ---
const receiptIcon =
'''<svg width="16" height="20" viewBox="0 0 16 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M2.18 19.85C2.27028 19.9471 2.3974 20.0016 2.53 20H2.82C2.9526 20.0016 3.07972 19.9471 3.17 19.85L5 18C5.19781 17.8082 5.51219 17.8082 5.71 18L7.52 19.81C7.61028 19.9071 7.7374 19.9616 7.87 19.96H8.16C8.2926 19.9616 8.41972 19.9071 8.51 19.81L10.32 18C10.5136 17.8268 10.8064 17.8268 11 18L12.81 19.81C12.9003 19.9071 13.0274 19.9616 13.16 19.96H13.45C13.5826 19.9616 13.7097 19.9071 13.8 19.81L15.71 18C15.8947 17.8137 15.9989 17.5623 16 17.3V1C16 0.447715 15.5523 0 15 0H1C0.447715 0 0 0.447715 0 1V17.26C0.00368349 17.5248 0.107266 17.7784 0.29 17.97L2.18 19.85ZM9 11.5C9 11.7761 8.77614 12 8.5 12H4.5C4.22386 12 4 11.7761 4 11.5V10.5C4 10.2239 4.22386 10 4.5 10H8.5C8.77614 10 9 10.2239 9 10.5V11.5ZM11.5 8C11.7761 8 12 7.77614 12 7.5V6.5C12 6.22386 11.7761 6 11.5 6H4.5C4.22386 6 4 6.22386 4 6.5V7.5C4 7.77614 4.22386 8 4.5 8H11.5Z" fill="#FF7643"/>
</svg>
'''
;

const trashIcon =
'''<svg width="18" height="20" viewBox="0 0 18 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M10.7812 15.6604V7.16981C10.7812 6.8566 11.0334 6.60377 11.3438 6.60377C11.655 6.60377 11.9062 6.8566 11.9062 7.16981V15.6604C11.9062 15.9736 11.655 16.2264 11.3438 16.2264C11.0334 16.2264 10.7812 15.9736 10.7812 15.6604ZM6.09375 15.6604V7.16981C6.09375 6.8566 6.34594 6.60377 6.65625 6.60377C6.9675 6.60377 7.21875 6.8566 7.21875 7.16981V15.6604C7.21875 15.9736 6.9675 16.2264 6.65625 16.2264C6.34594 16.2264 6.09375 15.9736 6.09375 15.6604ZM15 16.6038C15 17.8519 13.9903 18.8679 12.75 18.8679H5.25C4.00969 18.8679 3 17.8519 3 16.6038V3.96226H15V16.6038ZM7.21875 1.50943C7.21875 1.30094 7.38656 1.13208 7.59375 1.13208H10.4062C10.6134 1.13208 10.7812 1.30094 10.7812 1.50943V2.83019H7.21875V1.50943ZM17.4375 2.83019H11.9062V1.50943C11.9062 0.677359 11.2331 0 10.4062 0H7.59375C6.76688 0 6.09375 0.677359 6.09375 1.50943V2.83019H0.5625C0.252187 2.83019 0 3.08302 0 3.39623C0 3.70943 0.252187 3.96226 0.5625 3.96226H1.875V16.6038C1.875 18.4764 3.38906 20 5.25 20H12.75C14.6109 20 16.125 18.4764 16.125 16.6038V3.96226H17.4375C17.7488 3.96226 18 3.70943 18 3.39623C18 3.08302 17.7488 2.83019 17.4375 2.83019Z" fill="#FF4848"/>
</svg>
'''
;