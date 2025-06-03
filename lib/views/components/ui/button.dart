import 'package:flutter/material.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_styles.dart';

class ButtonComponent extends StatefulWidget {
  final String label;
  final double? width;
  final Widget? icon;
  final ButtonType type;
  final Function() onPressed;
  final bool isLoading;

  const ButtonComponent({super.key, required this.label, this.icon, this.type = ButtonType.primary, this.width, required this.onPressed, this.isLoading = false});

  @override
  State<ButtonComponent> createState() => _ButtonComponentState();
}

class _ButtonComponentState extends State<ButtonComponent> {
  final Map<ButtonType, Color> backgroundColour = {
    ButtonType.primary: AppColours.primaryColour,
    ButtonType.secondary: AppColours.primaryColourLight,
    ButtonType.light: Colors.white,
  };

  final Map<ButtonType, Color> foregroundColour = {
    ButtonType.primary: Colors.white,
    ButtonType.secondary: AppColours.primaryColour,
    ButtonType.light: Colors.black,
  };

  final Map<ButtonType, Color> borderColour = {
    ButtonType.primary: AppColours.primaryColour,
    ButtonType.secondary: AppColours.primaryColourLight,
    ButtonType.light: AppColours.light20.withOpacity(0.5),
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? MediaQuery.of(context).size.width,
      height: 56,
      child: ElevatedButton(
          onPressed: () {
            if(!widget.isLoading) widget.onPressed();
          },
          style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: borderColour[widget.type]!),
                  borderRadius: BorderRadius.circular(16)),
              backgroundColor: backgroundColour[widget.type],
              foregroundColor: foregroundColour[widget.type]),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      widget.icon!,
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.label,
                      style: AppStyles.buttonText(color: Colors.white),
                    ),
                  ],
                )),
    );
  }
}

enum ButtonType { primary, secondary, light }

class AppButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? backgroundColor;

  const AppButton({
    Key? key,
    required this.title,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ButtonType buttonType = ButtonType.primary;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              backgroundColor: backgroundColor ?? AppColours.primaryColour,
              foregroundColor: Colors.white),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  ),
                )
              : Text(
                  title,
                  style: AppStyles.buttonText(color: Colors.white),
                ),
      ),
    );
  }
}
