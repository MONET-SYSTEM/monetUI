import 'package:flutter/material.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_styles.dart';

// Keep the original function for backward compatibility
AppBar buildAppBar(BuildContext context, String title, {Color? backgroundColor, Color? foregroundColor}) {
  return AppBar(
    centerTitle: true,
    backgroundColor: backgroundColor ?? AppColours.backgroundColor,
    title: Text(title, style: AppStyles.appTitle(color: foregroundColor)),
    leading: Navigator.of(context).canPop() ? IconButton(
      onPressed: () => Navigator.of(context).pop(),
      icon: Icon(Icons.arrow_back, color: foregroundColor),
    ): null,
  );
}

// Add the CustomAppBar class that EditAccountScreen is expecting
class CustomAppBar extends AppBar {
  CustomAppBar({
    super.key,
    required String title,
    bool showBackButton = false,
    Color? backgroundColor,
    Color? foregroundColor,
    List<Widget>? actions,
  }) : super(
    centerTitle: true,
    backgroundColor: backgroundColor ?? AppColours.primaryColour,
    foregroundColor: foregroundColor ?? Colors.white,
    title: Text(title, style: AppStyles.appTitle(color: foregroundColor ?? Colors.white)),
    leading: showBackButton ? Builder(
      builder: (context) => IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back, color: foregroundColor ?? Colors.white),
      ),
    ) : null,
    actions: actions,
    elevation: 0,
  );
}

