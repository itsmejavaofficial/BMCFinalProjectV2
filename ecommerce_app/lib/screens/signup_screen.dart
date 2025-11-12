import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/screens/login_screen.dart'; // Ensure this path is correct
import 'package:flutter/material.dart';
// NOTE: Make sure to add the 'flutter_svg' package to your pubspec.yaml
import 'package:flutter_svg/flutter_svg.dart';

// --- Global UI Constants (Copied from new design) ---
const Color kPrimaryColor = Color(0xFFFF7643); // Orange primary color
const Color kSecondaryColor = Color(0xFF757575); // Grey text color
const Color kBackgroundColor = Colors.white;

const authOutlineInputBorder = OutlineInputBorder(
  borderSide: BorderSide(color: kSecondaryColor),
  borderRadius: BorderRadius.all(Radius.circular(28)), // Rounded corners for fields
);

// --- App Root Widget ---
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'eCommerce App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: kBackgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackgroundColor,
          elevation: 0,
          titleTextStyle: TextStyle(color: kSecondaryColor, fontSize: 18),
          iconTheme: IconThemeData(color: kSecondaryColor),
        ),
        primaryColor: kPrimaryColor,
        hintColor: kSecondaryColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SignUpScreen(),
    );
  }
}

// --- SignUpScreen Stateful Implementation ---
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // --- State and Firebase Instances ---
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Controllers and Key (Updated to include confirm password) ---
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // --- New State for Password Visibility Toggle ---
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // --- Listener Callbacks to trigger UI rebuild when text status changes ---
  void _onPasswordChange() => setState(() {});
  void _onConfirmPasswordChange() => setState(() {});

  @override
  void initState() {
    super.initState();
    // Attach listeners to trigger rebuild when text changes from empty to not empty
    _passwordController.addListener(_onPasswordChange);
    _confirmPasswordController.addListener(_onConfirmPasswordChange);
  }

  // --- Utility for showing errors ---
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- Authentication Logic (Modified for new validation) ---
  Future<void> _signUp() async {
    // 1. Validate the form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Additional check for password confirmation
    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    // 3. Set loading to true
    setState(() {
      _isLoading = true;
    });

    try {
      // 4. Create the user
      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 5. Write user data to Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': _emailController.text.trim(),
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
        _showErrorSnackBar("Registration Successful! You are logged in.");
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      } else {
        errorMessage = e.message ?? 'An unknown error occurred during sign up.';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred: ${e.toString()}');
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    // Remove listeners before disposing controllers
    _passwordController.removeListener(_onPasswordChange);
    _passwordController.dispose();
    _confirmPasswordController.removeListener(_onConfirmPasswordChange);
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Build Method (New UI Structure) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    "Register Account",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  // The form section (integrating controllers and logic)
                  _buildSignUpForm(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Extracted Form Builder Widget to keep logic close to controllers ---
  Widget _buildSignUpForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // 1. Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: "Enter your email",
              labelText: "Email",
              floatingLabelBehavior: FloatingLabelBehavior.always,
              hintStyle: const TextStyle(color: kSecondaryColor),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: SvgPicture.string(mailIcon, height: 18),
              ),
              border: authOutlineInputBorder,
              enabledBorder: authOutlineInputBorder,
              focusedBorder: authOutlineInputBorder.copyWith(
                  borderSide: const BorderSide(color: kPrimaryColor)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // 2. Password Field (Dynamic Icon Logic)
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible, // Toggles obscurity
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: "Enter your password",
              labelText: "Password",
              floatingLabelBehavior: FloatingLabelBehavior.always,
              hintStyle: const TextStyle(color: kSecondaryColor),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              suffixIcon: _passwordController.text.isEmpty
              // If empty, show static lock icon
                  ? Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: SvgPicture.string(lockIcon, height: 18),
              )
              // If text is present, show visibility toggle button
                  : IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: kSecondaryColor,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              border: authOutlineInputBorder,
              enabledBorder: authOutlineInputBorder,
              focusedBorder: authOutlineInputBorder.copyWith(
                  borderSide: const BorderSide(color: kPrimaryColor)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // 3. Confirm Password Field (Dynamic Icon Logic)
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible, // Toggles obscurity
            decoration: InputDecoration(
              hintText: "Re-enter your password",
              labelText: "Confirm Password",
              floatingLabelBehavior: FloatingLabelBehavior.always,
              hintStyle: const TextStyle(color: kSecondaryColor),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              suffixIcon: _confirmPasswordController.text.isEmpty
              // If empty, show static lock icon
                  ? Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: SvgPicture.string(lockIcon, height: 18),
              )
              // If text is present, show visibility toggle button
                  : IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: kSecondaryColor,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              border: authOutlineInputBorder,
              enabledBorder: authOutlineInputBorder,
              focusedBorder: authOutlineInputBorder.copyWith(
                  borderSide: const BorderSide(color: kPrimaryColor)),
            ),
            // The actual match validation is done in _signUp, but a basic check is good here
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please re-enter your password';
              }
              return null;
            },
          ),

          const SizedBox(height: 32),

          // 4. Continue/Sign Up Button
          ElevatedButton(
            onPressed: _isLoading ? null : _signUp,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Text("Continue"),
          ),

          const SizedBox(height: 20), // Space between button and login link

          // 5. "Already have an account?" link
          _buildLoginLink(),
        ],
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Already have an account? ",
          style: TextStyle(color: kSecondaryColor),
        ),
        GestureDetector(
          onTap: () {
            // Use pushReplacement to prevent back button going to sign-up again
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          },
          child: const Text(
            "Login",
            style: TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// --- Helper Widget (Copied from new design) ---
class SocalCard extends StatelessWidget {
  const SocalCard({
    Key? key,
    required this.icon,
    required this.press,
  }) : super(key: key);

  final Widget icon;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: icon,
      ),
    );
  }
}


// --- SVG Icons (Copied from new design) ---
const mailIcon =
'''<svg width="18" height="13" viewBox="0 0 18 13" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M15.3576 3.39368C15.5215 3.62375 15.4697 3.94447 15.2404 4.10954L9.80876 8.03862C9.57272 8.21053 9.29421 8.29605 9.01656 8.29605C8.7406 8.29605 8.4638 8.21138 8.22775 8.04204L2.76041 4.11039C2.53201 3.94618 2.47851 3.62546 2.64154 3.39454C2.80542 3.16362 3.12383 3.10974 3.35223 3.27566L8.81872 7.20645C8.93674 7.29112 9.09552 7.29197 9.2144 7.20559L14.6469 3.27651C14.8753 3.10974 15.1937 3.16447 15.3576 3.39368ZM16.9819 10.7763C16.9819 11.4366 16.4479 11.9745 15.7932 11.9745H2.20765C1.55215 11.9745 1.01892 11.4366 1.01892 10.7763V2.22368C1.01892 1.56342 1.55215 1.02632 2.20765 1.02632H15.7932C16.4479 1.02632 16.9819 1.56342 16.9819 2.22368V10.7763ZM15.7932 0H2.20765C0.990047 0 0 0.998092 0 2.22368V10.7763C0 12.0028 0.990047 13 2.20765 13H15.7932C17.01 13 18 12.0028 18 10.7763V2.22368C18 0.998092 17.01 0 15.7932 0Z" fill="#757575"/>
</svg>''';

const lockIcon =
'''<svg width="15" height="18" viewBox="0 0 15 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M9.24419 11.5472C9.24419 12.4845 8.46279 13.2453 7.5 13.2453C6.53721 13.2453 5.75581 12.4845 5.75581 11.5472C5.75581 10.6098 6.53721 9.84906 7.5 9.84906C8.46279 9.84906 9.24419 10.6098 9.24419 11.5472ZM13.9535 14.0943C13.9535 15.6863 12.6235 16.9811 10.9884 16.9811H4.01163C2.37645 16.9811 1.04651 15.6863 1.04651 14.0943V9C1.04651 7.40802 2.37645 6.11321 4.01163 6.11321H10.9884C12.6235 6.11321 13.9535 7.40802 13.9535 9V14.0943ZM4.53488 3.90566C4.53488 2.31368 5.86483 1.01887 7.5 1.01887C8.28488 1.01887 9.03139 1.31943 9.59477 1.86028C10.1564 2.41387 10.4651 3.14066 10.4651 3.90566V5.09434H4.53488V3.90566ZM11.5116 5.12745V3.90566C11.5116 2.87151 11.0956 1.89085 10.3352 1.14028C9.5686 0.405 8.56221 0 7.5 0C5.2875 0 3.48837 1.7516 3.48837 3.90566V5.12745C1.52267 5.37792 0 7.01915 0 9V14.0943C0 16.2484 1.79913 18 4.01163 18H10.9884C13.2 18 15 16.2484 15 14.0943V9C15 7.01915 13.4773 5.37792 11.5116 5.12745Z" fill="#757575"/>
</svg>''';