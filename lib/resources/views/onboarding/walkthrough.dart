import 'package:flutter/material.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_routes.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/resources/app_styles.dart';
import 'package:monet/resources/views/components/ui/button.dart';
import '../../../models/slide.dart' show SlideModel;

class WalkthroughScreen extends StatefulWidget {
  const WalkthroughScreen({super.key});

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  PageController pageController = PageController();
  List<SlideModel> slides = [
    SlideModel(
      AppStrings.walkthroughTitle1,
      AppStrings.walkthroughDescription1,
      "assets/images/walkthrough1.png",
    ),
    SlideModel(
      AppStrings.walkthroughTitle2,
      AppStrings.walkthroughDescription2,
      "assets/images/walkthrough2.png",
    ),
    SlideModel(
      AppStrings.walkthroughTitle3,
      AppStrings.walkthroughDescription3,
      "assets/images/walkthrough3.png",
    ),
  ];

  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.backgroundColor,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: PageView.builder(
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          bool useRow = constraints.maxWidth > 600;
                          return useRow
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Image.asset(slides[index].image),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          slides[index].title,
                                          style: AppStyles.title1(),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          slides[index].description,
                                          style: AppStyles.regular1(
                                            color: AppColours.light20,
                                            weight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                              : Column(
                                children: [
                                  Center(
                                    child: Image.asset(
                                      slides[index].image,
                                      width: constraints.maxWidth * 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    slides[index].title,
                                    style: AppStyles.title1(),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    slides[index].description,
                                    style: AppStyles.regular1(
                                      color: AppColours.light20,
                                      weight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              );
                        },
                      ),
                    );
                  },
                  controller: pageController,
                  itemCount: slides.length,
                  onPageChanged: (index) => setState(() => currentPage = index),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    indicators(),
                    const SizedBox(height: 24),
                    buttons(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget indicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < slides.length; i++) ...[
          InkWell(
            onTap: () {
              if (i != currentPage) {
                pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 499),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: Icon(
              Icons.circle,
              size: currentPage == i ? 16 : 8,
              color:
                  currentPage == i
                      ? AppColours.primaryColour
                      : AppColours.primaryColourLight,
            ),
          ),
          if (i < slides.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget buttons() {
    return Column(
      children: [
        ButtonComponent(label: AppStrings.signUp, onPressed: () => Navigator.of(context).pushNamed(AppRoutes.signup)),
        const SizedBox(height: 16),
        ButtonComponent(
          type: ButtonType.secondary,
          label: AppStrings.logIn,
          onPressed: () {},
        ),
      ],
    );
  }
}
