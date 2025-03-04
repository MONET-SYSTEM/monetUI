import 'package:flutter/material.dart';
import 'package:monet/resources/app_colours.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/resources/app_styles.dart';

class TextInputComponent extends StatefulWidget {
  final String label;
  const TextInputComponent({super.key, required this.label});

  @override
  State<TextInputComponent> createState() => _TextInputComponentState();
}

class _TextInputComponentState extends State<TextInputComponent> {
  @override
  Widget build(BuildContext context) {
      return TextFormField(
        decoration: InputDecoration(
          labelText: widget.label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColours.light20),
          )
        ),
      );
  }
}
