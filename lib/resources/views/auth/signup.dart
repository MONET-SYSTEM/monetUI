import 'package:flutter/material.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/resources/views/components/form/text_signup.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.signUp, style: AppStyles.appTitle()),
        leading: InkWell(
          onTap: ()=> Navigator.of(context).pop(),
          child: Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          TextInputComponent(label: 'Name',)
        ],
      ),
    );
  }
}
