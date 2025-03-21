import 'package:flutter/material.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_spacing.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/utils/helper.dart';

class SignupSuccessScreen extends StatefulWidget {
  const SignupSuccessScreen({super.key});

  @override
  State<SignupSuccessScreen> createState() => _SignupSuccessScreenState();
}

class _SignupSuccessScreenState extends State<SignupSuccessScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.backgroundColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: Image.asset("assets/images/success.png",
              width: MediaQuery.of(context).size.width / 4)),
          AppSpacing.vertical(),
          Text(AppStrings.youAreSet, style: AppStyles.medium(size: 24)),
        ],
      ),
    );
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initScreen();
  }

  Future<void> _initScreen() async {
    final route = await Helper.initialRoute();
    Future.delayed(const Duration(seconds: 3), () => Navigator.of(context).pushReplacementNamed(route));
  }
}