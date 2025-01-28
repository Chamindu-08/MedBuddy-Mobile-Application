import 'package:flutter/material.dart';
import 'package:medbuddy_mobile_app/screens/signup/components/socal_icon.dart';
import '../../../screens/Signup/components/or_divider.dart';

class SocalSignUp extends StatelessWidget {
   const SocalSignUp({
     super.key,
   });

   @override
   Widget build(BuildContext context) {
     return Column(
       children: [
         const OrDivider(),
         Row(
           mainAxisAlignment: MainAxisAlignment.center,
           children: <Widget>[
             SocalIcon(
               iconSrc: "assets/icons/facebook.svg",
               press: () {},
             ),
             SocalIcon(
               iconSrc: "assets/icons/twitter.svg",
               press: () {},
             ),
             SocalIcon(
               iconSrc: "assets/icons/google-plus.svg",
               press: () {},
             ),
           ],
         ),
       ],
     );
   }
 }