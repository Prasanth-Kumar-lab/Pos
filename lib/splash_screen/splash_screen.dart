import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

import '../../home_screen/view/view.dart';
import '../../profile/views/profile_buttons.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    await Future.delayed(const Duration(seconds: 2)); // Simulate splash delay

    if (isLoggedIn) {
      final role = prefs.getString('role') ?? '';
      final name = prefs.getString('name') ?? 'User';
      final username = prefs.getString('username') ?? '';
      final mobileNumber = prefs.getString('mobileNumber') ?? 'N/A';
      final businessId = prefs.getString('businessId') ?? 'N/A';
      final user_id = prefs.getString('user_id') ?? 'N/A';

      if (role == 'Admin') {
        Get.offAll(() => ProfileButtons(
          name: name,
          username: username,
          mobileNumber: mobileNumber,
          businessId: businessId,
          role: role,
          user_id: user_id,
        ));
      } else if (role == 'Biller') {
        Get.offAll(() => HomeScreen(
          name: name,
          username: username,
          mobileNumber: mobileNumber,
          businessId: businessId,
          role: role,
          user_id: user_id,
        ));
      } else {
        Get.offAllNamed('/login');
      }
    } else {
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Center(
          child: Lottie.asset(
            'assets/Order Confirmed.json',
            repeat: true,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
