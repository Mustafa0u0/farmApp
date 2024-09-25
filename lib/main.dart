import 'package:farm_app/routes/route_helper.dart';
import 'package:farm_app/utils/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyACp8d7dDVp2hT_nl7g4mFkQGH1_CS7UhM",
            authDomain: "farm-app-93fc6.firebaseapp.com",
            projectId: "farm-app-93fc6",
            storageBucket: "farm-app-93fc6.appspot.com",
            messagingSenderId: "330304864081",
            appId: "1:330304864081:web:b3ad79091fa6b8d18fdd70",
            measurementId: "G-V5M4090789"));
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: RouteHelper.welcome,
      getPages: RouteHelper.routes,
      navigatorKey: navigatorKey,
      theme: ThemeData(
          primaryColor: AppColors.mainColor,
          textTheme: GoogleFonts.promptTextTheme()),
    );
  }
}
