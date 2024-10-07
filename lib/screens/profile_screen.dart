import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farm_app/utils/colors.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? userId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Load user profile data
  }

  Future<void> _loadUserProfile() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      userId = currentUser.uid;

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        setState(() {
          usernameController.text = userDoc['username'];
          emailController.text = currentUser.email ?? ''; // Display email
          phoneNumberController.text = userDoc['phoneNumber'];
          isLoading = false;
        });
      }
    }
  }

  // Update the user's Firestore profile
  Future<void> _saveProfileChanges() async {
    if (userId != null) {
      await _firestore.collection('users').doc(userId).update({
        'username': usernameController.text,
        'phoneNumber': phoneNumberController.text,
      });

      // Update password in Firebase Auth if entered
      User? currentUser = _auth.currentUser;
      if (currentUser != null && passwordController.text.isNotEmpty) {
        await currentUser.updatePassword(passwordController.text);
      }

      Get.snackbar('Success', 'Profile updated successfully',
          backgroundColor: Colors.green, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.mainColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      icon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    readOnly: true, // Make email read-only (cannot edit)
                    decoration: const InputDecoration(
                      labelText: 'Email (cannot be changed)',
                      icon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      icon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password (optional)',
                      icon: Icon(Icons.password),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _saveProfileChanges();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainColor,
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
