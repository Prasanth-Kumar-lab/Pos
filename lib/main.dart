/*
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/profile/views/profile_buttons.dart';
import 'package:task/profile/views/profile_buttons.dart';
import 'package:task/signup_page/views/signup_screen.dart';
import 'package:task/splash_screen/splash_screen.dart';

import 'home_screen/view/view.dart';
import 'login/views/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Auth App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/splash', // Set Splash as initial

      getPages: [
        GetPage(name: '/splash', page: () => SplashScreen()),
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/signup', page: () => SignupScreen()),
        GetPage(
          name: '/home',
          page: () => HomeScreen(
            name: Get.arguments['name'] ?? 'User',
            username: Get.arguments['username'] ?? '',
            mobileNumber: Get.arguments['number'] ?? 'N/A',
            businessId: Get.arguments['business_id']??'N/A',
            role: Get.arguments['role'] ?? 'N/A',
            user_id: Get.arguments['id'] ?? 'N/A',
          ),
        ),
        GetPage(
          name: '/home',
          page: () => ProfileButtons(
            name: Get.arguments['name'] ?? 'User',
            username: Get.arguments['username'] ?? '',
            mobileNumber: Get.arguments['number'] ?? 'N/A',
            businessId: Get.arguments['business_id']?? 'N/A',
            user_id: Get.arguments['id']?? 'N/A',
            role: Get.arguments['role'] ?? 'N/A',
          ),
        ),
      ],
    );
  }
}
*/
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/profile/views/profile_buttons.dart';
import 'package:task/signup_page/views/signup_screen.dart';
import 'package:task/splash_screen/splash_screen.dart';
import 'package:task/home_screen/view/view.dart';
import 'package:task/login/views/login_screen.dart';
import 'package:task/print/controller/print_controller.dart'; // Adjust path if needed
import 'home_screen/model/product_model.dart'; // If used in injection

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Auth App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => SplashScreen()),
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/signup', page: () => SignupScreen()),

        // Inject PrintController when navigating to Home
        GetPage(
          name: '/home',
          page: () {
            final args = Get.arguments ?? {};
            final initialProducts = args['products'] as List<Product>? ?? []; // Map to initialProducts
            final initialTotal = args['total'] as double? ?? 0.0; // Map to initialTotal
            final businessId = args['business_id'] ?? '';

            // Inject controller dynamically with real data
            Get.put(PrintController(
              initialProducts: initialProducts, // Updated parameter name
              initialTotal: initialTotal, // Updated parameter name
              businessId: businessId,
            ));

            return HomeScreen(
              name: args['name'] ?? 'User',
              username: args['username'] ?? '',
              mobileNumber: args['number'] ?? 'N/A',
              businessId: businessId,
              role: args['role'] ?? 'N/A',
              user_id: args['id'] ?? 'N/A',
            );
          },
        ),

        GetPage(
          name: '/profile',
          page: () {
            final args = Get.arguments ?? {};
            return ProfileButtons(
              name: args['name'] ?? 'User',
              username: args['username'] ?? '',
              mobileNumber: args['number'] ?? 'N/A',
              businessId: args['business_id'] ?? 'N/A',
              user_id: args['id'] ?? 'N/A',
              role: args['role'] ?? 'N/A',
            );
          },
        ),
      ],
    );
  }
}