import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String buttonText;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? child;

  const CustomButton({
    super.key,
    required this.buttonText,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // width: 300, // Fixed width of 300px
      // height: 49, // Hug height of 49px
      // padding:
      //     const EdgeInsets.fromLTRB(16, 14, 16, 14), // Padding as specified
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), // Semi-rounded border radius
        border: Border.all(
          width: 1, // Border width (top border only as needed)
          color: Colors.white, // Adjust border color as needed
        ),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(50, 60),
          backgroundColor: backgroundColor, // Set the background color
          foregroundColor: textColor, // Set the text (and icon) color
          disabledForegroundColor:
              Colors.grey, // Set the color for disabled text/icon
          disabledBackgroundColor:
              Colors.grey[300], // Set the color for the disabled background
          shadowColor: Colors.black, // Shadow color
          elevation: 5, // Button elevation (shadow)
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12), // Padding inside the button
          shape: RoundedRectangleBorder(
            // Button shape (e.g. rounded corners)
            borderRadius: BorderRadius.circular(12), // Semi-rounded corners
          ),
        ),
        onPressed: onPressed,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: child,
            ),
            Text(
              buttonText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
