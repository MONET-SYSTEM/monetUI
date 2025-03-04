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
  final formKey = GlobalKey<FormState>();
  final nameEditingController = TextEditingController();
  final emailEditingController = TextEditingController();
  final passwordEditingController = TextEditingController();

  final nameFocus = FocusNode();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  bool isLoading = false;
  bool hasAgreed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColours.backgroundColor,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: AppColours.backgroundColor,
          title: Text(AppStrings.signUp, style: AppStyles.appTitle()),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextInputComponent(
                isRequired: true,
                textInputType: TextInputType.name,
                focusNode: nameFocus,
                label: AppStrings.name,
                textEditingController: nameEditingController,
                onFieldSubmitted:
                    (value) => FocusScope.of(context).requestFocus(emailFocus),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextInputComponent(
                isRequired: true,
                textInputType: TextInputType.emailAddress,
                focusNode: emailFocus,
                label: AppStrings.emailAddress,
                textEditingController: emailEditingController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextInputComponent(
                isEnabled: !isLoading,
                isRequired: true,
                focusNode: passwordFocus,
                label: AppStrings.password,
                isPassword: true,
                textEditingController: passwordEditingController,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),

              CheckboxInputComponent(
                isEnabled: !isLoading,
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
                isLoading: isLoading,
                label: AppStrings.signUp,
                onPressed: signup
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
                },
              ),
              const SizedBox(height: 24),
              Text.rich(
                textAlign: TextAlign.center,
                style: AppStyles.medium(size: 16),
                TextSpan(
                  text: AppStrings.alreadyHaveAnAccount,
                  style: AppStyles.medium(color: AppColours.light20),
                  children: [
                    WidgetSpan(child: const SizedBox(width: 4)),
                    WidgetSpan(
                      child: InkWell(
                        onTap:
                            () => Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.login),
                        child: Text(
                          AppStrings.logIn,
                          style: AppStyles.medium(
                            size: 16,
                            color: AppColours.primaryColour,
                          ).copyWith(
                            decoration: TextDecoration.underline,
                            decorationColor: AppColours.primaryColour,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void signup() {
    FocusScope.of(context).unfocus();
    if(!formKey.currentState!.validate()) {
      return;
    }
    setState(() => isLoading = true);
    Future.delayed(const Duration(seconds: 3), (){
      print ("success");
      setState(() => isLoading = false);
    });

  }
}
