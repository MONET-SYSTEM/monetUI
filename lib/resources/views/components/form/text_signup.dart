import 'package:flutter/material.dart';
import 'package:monet/resources/app_colours.dart';

class TextInputComponent extends StatefulWidget {
  final String label;
  final bool isPassword;

  const TextInputComponent({
    super.key,
    required this.label,
    this.isPassword = false,
  });

  @override
  State<TextInputComponent> createState() => _TextInputComponentState();
}

class _TextInputComponentState extends State<TextInputComponent> {
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: (widget.isPassword && !showPassword),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(color: AppColours.light20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColours.light20.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColours.light20.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColours.primaryColour.withOpacity(0.2),
          ),
        ),
        suffixIcon:
            widget.isPassword
                ? InkWell(
                  onTap: togglePassword,
                  child: Icon(
                    showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColours.light20,
                  ),
                )
                : const SizedBox(),
      ),
    );
  }
  void togglePassword()  => setState(() {
    showPassword = !showPassword;
  });
}
