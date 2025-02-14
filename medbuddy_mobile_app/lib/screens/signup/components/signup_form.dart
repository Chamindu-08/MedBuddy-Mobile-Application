import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medbuddy_mobile_application/components/already_have_an_account.dart';
import 'package:medbuddy_mobile_application/screens/signin/signin_screen.dart';
import '../../../constants.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false; // To show a loading indicator

  // Function to validate Sri Lankan phone numbers (10 digits, starts with 0)
  bool _isValidPhoneNumber(String phone) {
    return RegExp(r"^0\d{9}$").hasMatch(phone);
  }

  // Function to validate passwords (Minimum 6 characters, includes at least one digit)
  bool _isValidPassword(String password) {
    return password.length >= 6 && RegExp(r'\d').hasMatch(password);
  }

  // Sign up function
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Trim spaces from inputs
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      String name = _nameController.text.trim();
      String patientId = _patientIdController.text.trim();
      String phone = _phoneController.text.trim();

      // Create user in Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'userName': name,
        'email': email,
        'contactNo': phone,
        'patientId': patientId,
      });
  
      // Navigate to Login Screen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Registration failed. Please try again.";

      if (e.code == 'email-already-in-use') {
        errorMessage = "This email is already in use. Try another.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email format.";
      } else if (e.code == 'weak-password') {
        errorMessage = "Password is too weak. Use at least 6 characters with a number.";
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(_nameController, "Your Name", Icons.person, "Please enter your name"),
          _buildTextField(_patientIdController, "Patient ID", Icons.credit_card, "Please enter your Patient ID"),
          _buildTextField(_emailController, "Your Email", Icons.email, "Please enter a valid email",
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return "Please enter your email";
                if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
                  return "Please enter a valid email";
                }
                return null;
              }),
          _buildTextField(_phoneController, "Your Contact No.", Icons.phone, "Please enter a valid phone number",
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) return "Please enter your contact number";
                if (!_isValidPhoneNumber(value)) return "Invalid phone number. Use a 10-digit number starting with 0.";
                return null;
              }),
          _buildTextField(_passwordController, "Password", Icons.lock, "Please enter a password",
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) return "Please enter a password";
                if (!_isValidPassword(value)) return "Password must be at least 6 characters and include a number.";
                return null;
              }),
          _buildTextField(_confirmPasswordController, "Confirm Password", Icons.lock, "Passwords do not match",
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) return "Please confirm your password";
                if (value != _passwordController.text) return "Passwords do not match";
                return null;
              }),
          const SizedBox(height: defaultPadding),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text("Sign Up".toUpperCase()),
            ),
          ),
          const SizedBox(height: defaultPadding),
          AlreadyHaveAnAccountCheck(
            login: false,
            press: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),
        ],
      ),
    );
  }

  // Reusable text field widget
  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    IconData icon,
    String errorMessage, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Icon(icon),
          ),
        ),
        validator: validator ?? (value) => value == null || value.isEmpty ? errorMessage : null,
      ),
    );
  }
}
