import 'package:farm_app/utils/colors.dart';
import 'package:farm_app/widgets/CustomButton.dart';
import 'package:farm_app/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

class SignUpScreen extends StatelessWidget {
  SignUpScreen({Key? key}) : super(key: key);
  final AuthController authController = Get.put(AuthController());
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final TextEditingController phoneNumberController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Sign up',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.mainColor,
      ),
      body: ListView(
        padding: EdgeInsets.all(8),
        children: [
          SvgPicture.asset('assets/images/p1.svg'),
          SizedBox(height: 10),
          AppTextField(
              textController: usernameController,
              hintText: 'Username',
              icon: Icons.person),
          SizedBox(height: 10),
          AppTextField(
              textController: emailController,
              hintText: 'Email',
              icon: Icons.email),
          SizedBox(height: 10),
          AppTextField(
              textController: passwordController,
              isObscure: true,
              hintText: 'password',
              icon: Icons.password),
          SizedBox(height: 10),
          AppTextField(
              textController: phoneNumberController,
              hintText: 'phone number',
              keyboardType: TextInputType.phone,
              prefixText: "+60 ",
              icon: Icons.phone),
          SizedBox(height: 15),
          CustomButton(
            buttonText: 'Sgin up',
            textColor: Colors.white,
            backgroundColor: AppColors.mainColor,
            onPressed: () {
              authController.signUp(
                usernameController.text,
                emailController.text,
                passwordController.text,
                phoneNumberController.text,
              );
            },
          )
        ],
      ),
    );
  }
}
