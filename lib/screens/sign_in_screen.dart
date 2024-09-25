import 'package:farm_app/utils/colors.dart';
import 'package:farm_app/widgets/CustomButton.dart';
import 'package:farm_app/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  final AuthController authController = Get.put(AuthController());
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginScreen({Key? key}) : super(key: key);
  final TextEditingController textController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Sign In',
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
              textController: emailController,
              hintText: 'email',
              icon: Icons.email),
          SizedBox(height: 10),
          AppTextField(
              textController: passwordController,
              hintText: 'password',
              isObscure: true,
              icon: Icons.password),
          SizedBox(height: 10),
          CustomButton(
            buttonText: 'Sign In',
            textColor: Colors.white,
            backgroundColor: AppColors.mainColor,
            onPressed: () {
              authController.signIn(
                emailController.text,
                passwordController.text,
              );
            },
          )
        ],
      ),
    );
  }
}
