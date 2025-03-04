import 'package:flutter/material.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_routes.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/resources/views/components/form/checkbox_input.dart';
import 'package:monet/resources/views/components/form/text_signup.dart';
import 'package:monet/resources/views/components/ui/button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.backgroundColor,
      appBar: AppBar(
        title: Text(AppStrings.signUp, style: AppStyles.appTitle()),
        leading: InkWell(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          TextInputComponent(label: AppStrings.name),
          const SizedBox(height: 16),
          TextInputComponent(label: AppStrings.emailAddress),
          const SizedBox(height: 16),
          TextInputComponent(label: AppStrings.password, isPassword: true),
          const SizedBox(height: 16),

          CheckboxInputComponent(
            label: Text.rich(
              style: AppStyles.medium(size: 14),
              TextSpan(
                text: AppStrings.agreeText,
                children: [
                  WidgetSpan(child: const SizedBox(height: 4)),
                  TextSpan(
                    text: AppStrings.termsAndPrivacy,
                    style: AppStyles.medium(
                      size: 14,
                      color: AppColours.primaryColour,
                    ),
                  ),
                ],
              ),
            ),
            value: false,
            onChanged: (value) {
              print(value);
            },
          ),
          const SizedBox(height: 24),
          ButtonComponent(
            label: AppStrings.signUp,
            onPressed: () {
              print("sign up");
            },
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.orWith,
            textAlign: TextAlign.center,
            style: AppStyles.bold(size: 14, color: AppColours.light20),
          ),
          const SizedBox(height: 16),
          ButtonComponent(
            type: ButtonType.light,
            label: AppStrings.signUpWithGoogle,
              icon: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset("assets/images/google.png"),
              ),
              onPressed: () {
                print("signUpWithGoogle");
              }),
          const SizedBox(height: 24),
          Text.rich(
              textAlign: TextAlign.center,
              style: AppStyles.medium(size: 16),
              TextSpan(
                  text: AppStrings.alreadyHaveAnAccount,
                  style: AppStyles.medium(color: AppColours.light20),
                  children: [
                    WidgetSpan(child: const SizedBox(width: 4)),
                    WidgetSpan(child: InkWell(
                      onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                      child: Text(
                        AppStrings.logIn,
                        style: AppStyles.medium(
                            size: 16, color: AppColours.primaryColour)
                            .copyWith(
                            decoration: TextDecoration.underline,
                            decorationColor: AppColours.primaryColour),
                      ),
                    ))
                  ]))
        ],
      ),
    );
  }
}
