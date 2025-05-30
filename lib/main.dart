import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:monet/models/account.dart';
import 'package:monet/models/account_type.dart';
import 'package:monet/models/currency.dart';
import 'package:monet/models/user.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_routes.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/views/account/add_account.dart';
import 'package:monet/views/account/setup_account.dart';
import 'package:monet/views/auth/forgot_password.dart';
import 'package:monet/views/auth/forgot_password_sent.dart';
import 'package:monet/views/auth/login.dart';
import 'package:monet/views/auth/reset_password.dart';
import 'package:monet/views/auth/setup_pin.dart';
import 'package:monet/views/auth/signup.dart';
import 'package:monet/views/auth/signup_success.dart';
import 'package:monet/views/auth/verification.dart';
import 'package:monet/views/home.dart';
import 'package:monet/views/onboarding/splash_screen.dart';
import 'package:monet/views/onboarding/walkthrough.dart';

Future<void> main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(CurrencyModelAdapter());
  Hive.registerAdapter(AccountTypeModelAdapter());
  Hive.registerAdapter(AccountModelAdapter());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColours.primaryColour),
          useMaterial3: true,
          fontFamily: 'Inter'
      ),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.walkthrough: (context) => const WalkthroughScreen(),
        AppRoutes.signup: (context) => const SignupScreen(),
        AppRoutes.verification: (context) => const VerificationScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.forgotPasswordSent: (context) => const ForgotPasswordSentScreen(),
        AppRoutes.resetPassword: (context) => const ResetPasswordScreen(),
        AppRoutes.setupPin: (context) => const SetupPinScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.setupAccount: (context) => const SetupAccountScreen(),
        AppRoutes.addAccount: (context) => const AddAccountScreen(),
        AppRoutes.signupSuccess: (context) => const SignupSuccessScreen(),
      },
    );
  }
}