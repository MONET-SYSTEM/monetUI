import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:monet/controller/auth.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_routes.dart';
import 'package:monet/resources/app_spacing.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/utils/helper.dart';
import 'package:monet/views/components/form/checkbox_input.dart';
import 'package:monet/views/components/form/text_signup.dart';
import 'package:monet/views/components/ui/app_bar.dart';
import 'package:monet/views/components/ui/button.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'profile',
    'openid', // This is crucial for getting idToken
  ],
);

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameEditingController = TextEditingController();
  final _emailEditingController = TextEditingController();
  final _passwordEditingController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _hasAgreed = false;

  Map<String, dynamic> _errors = {};

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColours.backgroundColor,
        appBar: buildAppBar(context, AppStrings.signUp),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              AppSpacing.vertical(size: 48),
              _signUpForm(),
              AppSpacing.vertical(),
              ButtonComponent(
                  isLoading: _isLoading,
                  label: AppStrings.signUp,
                  onPressed: _handleSignup),
              AppSpacing.vertical(size: 16),
              Text(AppStrings.orWith,
                  textAlign: TextAlign.center,
                  style: AppStyles.bold(size: 14, color: AppColours.light20)),
              AppSpacing.vertical(size: 16),
              ButtonComponent(
                  type: ButtonType.light,
                  label: AppStrings.signUpWithGoogle,
                  icon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset("assets/images/google.png"),
                  ),
                  onPressed: _handleGoogleSignUp),
              AppSpacing.vertical(),
              Text.rich(
                  textAlign: TextAlign.center,
                  style: AppStyles.medium(size: 16),
                  TextSpan(
                      text: AppStrings.alreadyHaveAnAccount,
                      style: AppStyles.medium(color: AppColours.light20),
                      children: [
                        WidgetSpan(child: AppSpacing.horizontal(size: 4)),
                        WidgetSpan(child: InkWell(
                          onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                          child: Text(
                            AppStrings.login,
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameEditingController.dispose();
    _emailEditingController.dispose();
    _passwordEditingController.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();

    super.dispose();
  }

  Widget _signUpForm() {
    return Column(
      children: [
        TextInputComponent(
          error: _errors['name']?.join(', '),
          isEnabled: !_isLoading,
          isRequired: true,
          textInputType: TextInputType.name,
          focusNode: _nameFocus,
          label: AppStrings.name,
          textEditingController: _nameEditingController,
          onFieldSubmitted: (value) =>
              FocusScope.of(context).requestFocus(_emailFocus),
          textInputAction: TextInputAction.next,
        ),
        AppSpacing.vertical(),
        TextInputComponent(
          error: _errors['email']?.join(', '),
          isEnabled: !_isLoading,
          isRequired: true,
          textInputType: TextInputType.emailAddress,
          focusNode: _emailFocus,
          label: AppStrings.emailAddress,
          textEditingController: _emailEditingController,
          onFieldSubmitted: (value) =>
              FocusScope.of(context).requestFocus(_passwordFocus),
          textInputAction: TextInputAction.next,
        ),
        AppSpacing.vertical(),
        TextInputComponent(
          error: _errors['password']?.join(', '),
          isEnabled: !_isLoading,
          isRequired: true,
          focusNode: _passwordFocus,
          label: AppStrings.password,
          textEditingController: _passwordEditingController,
          isPassword: true,
          onFieldSubmitted: (value) => FocusScope.of(context).unfocus(),
          textInputAction: TextInputAction.done,
        ),
        AppSpacing.vertical(),
        CheckboxInputComponent(
            isEnabled: !_isLoading,
            label: Text.rich(
                style: AppStyles.medium(size: 14),
                TextSpan(text: AppStrings.agreeText, children: [
                  WidgetSpan(child: AppSpacing.horizontal(size: 4)),
                  TextSpan(
                      text: AppStrings.termsAndPrivacy,
                      style: AppStyles.medium(
                          size: 14, color: AppColours.primaryColour))
                ])),
            value: _hasAgreed,
            onChanged: (value) => setState(() => _hasAgreed = value)),
      ],
    );
  }

  Future<void> _handleSignup() async {
    setState(() => _errors = {});

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_hasAgreed) {
      Helper.snackBar(context, message: AppStrings.inputIsRequired.replaceAll(":input", AppStrings.termsAndPrivacy), isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    var result = await AuthController.register(
        _nameEditingController.text.trim(),
        _emailEditingController.text.trim(),
        _passwordEditingController.text);

    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      Helper.snackBar(context, message: result.message, isSuccess: false);
      if (result.errors != null) {
        setState(() => _errors = result.errors!);
      }

      return;
    }

    final route = await Helper.initialRoute();
    Navigator.of(context).pushNamed(route);
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User cancelled
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        Helper.snackBar(context,
          message: 'Google sign in failed: No access token received.',
          isSuccess: false
        );
        setState(() => _isLoading = false);
        return;
      }

      // Use accessToken with AuthController instead of idToken
      var result = await AuthController.googleSignUpWithAccessToken(accessToken);
      _handleGoogleSignUpResult(result);

    } catch (e) {
      print('Google Sign-In Error: $e');
      Helper.snackBar(context,
        message: 'Google sign in failed: ${e.toString()}',
        isSuccess: false
      );
      setState(() => _isLoading = false);
    }
  }

  void _handleGoogleSignUpResult(result) async {
    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      Helper.snackBar(context, message: result.message, isSuccess: false);
      if (result.errors != null) {
        setState(() => _errors = result.errors!);
      }
      return;
    }

    Helper.snackBar(context, message: result.message, isSuccess: true);
    final route = await Helper.initialRoute();
    Navigator.of(context).pushNamed(route);
  }
}