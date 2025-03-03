import 'package:flutter/material.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_routes.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/resources/views/onboarding/splash_screen.dart';
import 'package:monet/resources/views/onboarding/walkthrough.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: AppColours.primaryColour),
      ),
     initialRoute: AppRoutes.splash,
     routes: {
        AppRoutes.splash: (context)=> const SplashScreen(),
       AppRoutes.walkThrough: (context)=> const WalkthroughScreen()
     },
    );
  }
}

