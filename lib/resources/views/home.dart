import 'package:flutter/material.dart';
import 'package:monet/controller/auth.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_routes.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/utils/helper.dart';
import 'package:monet/resources/views/components/ui/app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.backgroundColor,
      appBar: buildAppBar(context, AppStrings.appName),
      body: Center(
        child: TextButton(
          onPressed: _logout,
          child: Text(AppStrings.logout),
        ),
      ),
    );
  }

  void _logout() async {

    final result = await AuthController.logout();

    if(!result.isSuccess){
      Helper.snackBar(context, message: result.message, isSuccess: false);
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.walkthrough);
  }
}