import 'package:flutter/material.dart';

const int mainColor1 = 0xFF030637;
const int mainColor2 = 0xFF3C0753;
const int mainColor3 = 0xFF720455;
const int mainColor4 = 0xFF910A67;
const int red = 0xFFFF5353;
const int green = 0XFF53FF98;
const int blue = 0XFF4C70CB;
Color gris = const Color.fromRGBO(64, 64, 64, 1.0);

Color getPrimary(BuildContext c) {
  return Theme.of(c).primaryColor;
}
