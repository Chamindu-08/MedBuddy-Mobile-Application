import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:medbuddy_mobile_application/screens/signup/components/socal_icon.dart';
import '../../../screens/Signup/components/or_divider.dart';

class SocalSignUp extends StatelessWidget {
   const SocalSignUp({
     super.key,
   });

  static final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  static final GoogleSignIn googleSignIn = GoogleSignIn();
  
  static Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final UserCredential userCredential =
          await firebaseAuth.signInWithCredential(credential);
      final User? user = userCredential.user;

      return user;
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (kDebugMode) {
          print(e.message);
        }
      }
      return null;
    }
  }
  
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
               press: () {
                signInWithGoogle();
               },
             ),
           ],
         ),
       ],
     );
   }
 }