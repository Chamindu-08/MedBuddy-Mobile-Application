import 'package:flutter/material.dart';
import '../../../constants.dart';

class LoginScreenTopImage extends StatelessWidget {
  const LoginScreenTopImage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 2,
              child: Image.asset("assets/images/medbuddy_light.png"),
            ),
            const Spacer(),
          ],
        ),
        const Text(
          "Welcome back,",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,),
        ),
        const SizedBox(height: defaultPadding / 2),
        const Text(
          "Sign in with your email and password  \nor continue with social media",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: defaultPadding * 2),
      ],
    );
  }
}
