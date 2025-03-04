import 'package:flutter/material.dart';
import 'package:monet/models/slide.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_routes.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/resources/views/components/ui/button.dart';

class WalkthroughScreen extends StatefulWidget {
  const WalkthroughScreen({super.key});

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  final PageController _pageController = PageController();
  final List<SlideModel> _slides = [
    SlideModel(AppStrings.walkthroughTitle1, AppStrings.walkthroughDescription1,
        "assets/images/walkthrough1.png"),
    SlideModel(AppStrings.walkthroughTitle2, AppStrings.walkthroughDescription2,
        "assets/images/walkthrough2.png"),
    SlideModel(AppStrings.walkthroughTitle3, AppStrings.walkthroughDescription3,
        "assets/images/walkthrough3.png")
  ];
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.backgroundColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: pages()),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                indicators(),
                const SizedBox(height: 24),
                buttons(),
                const SizedBox(height: 24)
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget indicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < _slides.length; i++) ...[
          InkWell(
            onTap: () {
              if (i != _currentPage) {
                _pageController.animateToPage(i,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut);
              }
            },
            child: Icon(Icons.circle,
                size: _currentPage == i ? 16 : 8,
                color: _currentPage == i
                    ? AppColours.primaryColour
                    : AppColours.primaryColourLight),
          ),
          if (i < _slides.length - 1) const SizedBox(height: 8),
        ]
      ],
    );
  }

  Widget buttons() {
    return Column(
      children: [
        ButtonComponent(
            label: AppStrings.signUp,
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.signup)
        ),
        const SizedBox(height: 16),
        ButtonComponent(
            type: ButtonType.secondary,
            label: AppStrings.logIn,
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login)
        ),
      ],
    );
  }

  Widget pages() {
    return PageView.builder(
      itemBuilder: (context, index) {
        return ListView(
          padding: const EdgeInsets.all(24),
          shrinkWrap: true,
          children: [
            const SizedBox(height: 48),
            Center(
              child: Image.asset(_slides[index].image,
                  width: MediaQuery.of(context).size.width / 1.5),
            ),
            const SizedBox(height: 24),
            Text(_slides[index].title,
                style: AppStyles.title1(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(_slides[index].description,
                style: AppStyles.regular1(
                    color: AppColours.light20, weight: FontWeight.w500),
                textAlign: TextAlign.center),
          ],
        );
      },
      controller: _pageController,
      itemCount: _slides.length,
      onPageChanged: (index) => setState(() => _currentPage = index),
    );
  }
}