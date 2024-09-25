import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:farm_app/utils/colors.dart';

class AuthController extends GetxController {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Rx<User?> firebaseUser = Rx<User?>(null);

  @override
  void onInit() {
    firebaseUser.bindStream(_auth.authStateChanges());
    super.onInit();
  }

  // Sign-up method with username, email, password, and phone number
  Future<void> signUp(String username, String email, String password,
      String phoneNumber) async {
    try {
      // Show loading while signing up
      Get.defaultDialog(
          title: 'Please Wait', content: CircularProgressIndicator());

      // Create a new user with email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user information (username and phone number) to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'phoneNumber': phoneNumber,
        'uid': userCredential.user!.uid,
      });

      // Remove loading indicator
      Get.back();

      // Check if farm details exist, otherwise navigate to farm details screen
      await _checkFarmDetails(userCredential.user!.uid);
    } on FirebaseAuthException catch (e) {
      // Remove loading indicator
      Get.back();

      String errorMessage;

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage =
              'The email address is already in use by another account.';
          break;
        case 'invalid-email':
          errorMessage =
              'The email address is not valid. Please enter a correct email.';
          break;
        case 'weak-password':
          errorMessage =
              'The password is too weak. Please enter a stronger password.';
          break;
        default:
          errorMessage = 'An unknown error occurred. Please try again.';
          break;
      }

      Get.snackbar(
          'Sign-up Error', errorMessage); // Show specific error messages
    } catch (e) {
      // Remove loading indicator
      Get.back();
      Get.snackbar(
          'Sign-up Error', 'An unexpected error occurred: ${e.toString()}');
    }
  }

  // Sign-in method
  Future<void> signIn(String email, String password) async {
    try {
      // Show loading while signing in
      Get.defaultDialog(
          title: 'Please Wait',
          content: CircularProgressIndicator(color: AppColors.mainColor));

      // Attempt to sign in with email and password
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Remove loading indicator
      Get.back();

      // Check if farm details exist, otherwise navigate to farm details screen
      await _checkFarmDetails(_auth.currentUser!.uid);
    } on FirebaseAuthException catch (e) {
      // Remove loading indicator
      Get.back();

      String errorMessage;

      switch (e.code) {
        case 'invalid-email':
          errorMessage =
              'The email address is not valid. Please enter a correct email.';
          break;
        case 'user-not-found':
          errorMessage =
              'No user found with this email. Please check your email or sign up.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'user-disabled':
          errorMessage =
              'This account has been disabled. Please contact support.';
          break;
        default:
          errorMessage = 'An unknown error occurred. Please try again.';
          break;
      }

      // Show specific error messages
      Get.snackbar('Sign-in Error', errorMessage);
    } catch (e) {
      // Remove loading indicator
      Get.back();
      // Handle any other errors not covered by FirebaseAuthException
      Get.snackbar(
          'Sign-in Error', 'An unexpected error occurred: ${e.toString()}');
    }
  }

  // Sign-out method
  void signOut() async {
    await _auth.signOut();
    Get.offAllNamed('/login');
  }

  // Check if farm details exist for the user
  Future<void> _checkFarmDetails(String uid) async {
    try {
      DocumentSnapshot farmDoc =
          await _firestore.collection('farms').doc(uid).get();

      if (farmDoc.exists) {
        // Farm details exist, navigate to the home page
        Get.offAllNamed('/home');
      } else {
        // No farm details, navigate to farm details entry screen
        Get.offAllNamed('/farm-Managment');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to retrieve farm details: ${e.toString()}');
    }
  }
}
