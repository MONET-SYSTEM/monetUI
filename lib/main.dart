import 'package:flutter/material.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/resources/views/onboarding/splash_screen.dart';

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
     initialRoute: '/',
     routes: {
        '/': (context)=> const SplashScreen()
     },
    );
  }
}

