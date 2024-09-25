import 'package:farm_app/routes/route_helper.dart';
import 'package:farm_app/screens/sign_in_screen.dart';
import 'package:farm_app/utils/colors.dart';
import 'package:farm_app/widgets/CustomButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: ListView(
          children: [
            SvgPicture.asset('assets/images/p1.svg'),
            Container(
                height: 500,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: AppColors.mainColor,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20))),
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  Text(
                    "Discover Your Farm",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 20.8 / 16,
                    ),
                  ),
                  SizedBox(height: 20), // Space between the two Text widgets
                  Text(
                    "Easily manage your farm’s crops and resources and Track planting, watering, and fertilization schedules.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      height: 20.8 / 16,
                    ),
                  ),
                  SizedBox(height: 50), // Space between the two Text widgets

                  CustomButton(
                    buttonText: "Sign in",
                    textColor: Colors.black,
                    backgroundColor: Colors.white,
                    onPressed: () {
                      Get.toNamed(RouteHelper.login);
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(builder: (context) => LoginScreen()),
                      // );
                    },
                  ),
                  SizedBox(height: 10), // Space between the two Text widgets

                  CustomButton(
                    buttonText: "Sign up",
                    textColor: Colors.white,
                    backgroundColor: AppColors.mainColor,
                    onPressed: () {
                      Get.toNamed(RouteHelper.signUp);
                    },
                  ),
                  SizedBox(height: 10), // Space between the two Text widgets

                  CustomButton(
                    buttonText: "Continue with Google",
                    textColor: Colors.black,
                    onPressed: () {},
                    child: SvgPicture.asset("assets/icons/google.svg"),
                  ),
                ]))
          ],
        ));
  }
}
