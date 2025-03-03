import 'package:flutter/material.dart';

class AppStyles {
  static TextStyle titleX({double size = 64, Color color = Colors.black}) {
      return TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.bold
      );
  }

  static TextStyle title1({double size = 28, Color color = Colors.black}) {
    return TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.bold
    );
  }

  static TextStyle title3({double size = 18, Color color = Colors.black}) {
    return TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.bold
    );
  }

  static TextStyle regular1({double size = 16, Color color = Colors.black, FontWeight weight = FontWeight.normal}) {
    return TextStyle(
      color: color,
      fontSize: size,
      fontWeight: weight
    );
  }

}