import 'package:flutter/material.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_routes.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/services/account_service.dart';
import 'package:monet/services/auth_service.dart';

class Helper {
  static snackBar(context, {required String message, bool isSuccess = true}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: isSuccess ? AppColours.primaryColour : Colors.red.shade900,
        content: Text(message, style: AppStyles.snackBar())));
  }

  static Future<String> initialRoute() async {
    final user = await AuthService.get();
    final account = await AccountService.get();
    if(user == null) {
      return AppRoutes.walkthrough;
    } else if(user.emailVerifiedAt == null) {
      return AppRoutes.verification;
    } else if(user.pin == null) {
      return AppRoutes.setupPin;
    } else if(account == null) {
      return AppRoutes.setupAccount;
    }

    return AppRoutes.home;
  }

  static double parseInputAmount(String value) {
    if(value.isEmpty) return 0;

    value = value.replaceAll(",", ".");
    return double.parse(value);
  }
}