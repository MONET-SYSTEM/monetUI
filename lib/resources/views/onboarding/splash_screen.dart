import 'package:flutter/material.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_routes.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/resources/app_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _State();
}

class _State extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.primaryColour,
      body: Center(
        child: Text(AppStrings.appName, style: AppStyles.titleX(size: 56, color: Colors.white),),
      ),
    );
  }

  @override
  void initState() {
    initApp();
    super.initState();
  }

  void initApp() {
    Future.delayed(
        const Duration(seconds: 5),
            () => Navigator.of(context).pushReplacementNamed(AppRoutes.walkThrough));
  }
}
