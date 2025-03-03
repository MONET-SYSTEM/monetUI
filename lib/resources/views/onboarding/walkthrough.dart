import 'package:flutter/material.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/resources/views/components/ui/button.dart';

class WalkthroughScreen extends StatefulWidget {
  const WalkthroughScreen({super.key});

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.backgroundColor,
      
      body: Padding(
          padding: EdgeInsets.all(24),
          child: Column (
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset("assets/images/walkthrough1.png"),
                const SizedBox(height:24),
                Text(AppStrings.walkthroughTitle1,
                    style:AppStyles.title1(),
                    textAlign: TextAlign.center),
                const SizedBox(height:16),
                Text(AppStrings.walkthroughDescription1,
                    style:AppStyles.regular1(color: AppColours.light20),
                    textAlign: TextAlign.center),
                const SizedBox(height:24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.circle, size: 16, color: AppColours.primaryColour),
                    const SizedBox(width:16),
                    Icon(Icons.circle, size: 16, color: AppColours.primaryColourLight),
                    const SizedBox(width:16),
                    Icon(Icons.circle, size: 16, color: AppColours.primaryColourLight)
                  ],
                ),
                const SizedBox(height:24),
                ButtonComponent(label: AppStrings.signUp),
                const SizedBox(height:16),
                ButtonComponent(type: ButtonType.secondary, label: AppStrings.logIn)
              ],
          ),
      ),
    );
  }
}
