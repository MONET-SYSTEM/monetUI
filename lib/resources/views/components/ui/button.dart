import 'package:flutter/material.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_styles.dart';

class ButtonComponent extends StatefulWidget {
  final String label;
  final double? width;
  final Widget? icon;
  final ButtonType? type;
  final Function() onPressed;

  const ButtonComponent({super.key, required this.label, this.icon, this.type, this.width, required this.onPressed});

  @override
  State<ButtonComponent> createState() => _ButtonComponentState();
}

class _ButtonComponentState extends State<ButtonComponent> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? MediaQuery.of(context).size.width,
      height: 56,
      child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: widget.type == ButtonType.secondary ? AppColours.primaryColourLight : AppColours.primaryColour
      ),
      child:Text(widget.label, style: AppStyles.title3(
        color: widget.type == ButtonType.secondary ? AppColours.dark100 : Colors.white, ))),
    );
  }
}

enum ButtonType {
  primary,
  secondary
}
