import 'package:flutter/material.dart' as m;
import 'package:image/image.dart';

double calculateColorMismatchPercent(Color c1, Color c2) {
  final doLog = false; //c1.r == 255; //c1.r != c1.g;
  final color1 = m.Color.fromARGB(255, c1.r.toInt(), c1.g.toInt(), c1.b.toInt());
  final hsv1 = m.HSVColor.fromColor(color1);

  final color2 = m.Color.fromARGB(255, c2.r.toInt(), c2.g.toInt(), c2.b.toInt());
  final hsv2 = m.HSVColor.fromColor(color2);

  // Calculate per-component difference.
  var deltaHue = (hsv2.hue - hsv1.hue).abs();
  final deltaSaturation = (hsv2.saturation - hsv2.saturation).abs();
  final deltaValue = (hsv2.value - hsv1.value).abs();

  // Handle hue circularity (i.e., fact that 360 degrees go back to 0 degrees)
  deltaHue = deltaHue > 180 ? 360 - deltaHue : deltaHue;

  // Normalize each component difference.
  deltaHue = deltaHue / 180;
  // Other components are already in range [0, 1].

  // Combine components instead single distance value.
  //
  // The difference formula is arbitrary, but the goal is to draw attention to differences that are likely
  // to be important, which means reducing differences between things that aren't. In this equation we treat
  // the value difference as the most important, such that black vs white goes directly to the max. Assuming
  // the difference in value doesn't eat up all the difference, the hue is then given 3 times the
  // weight of the saturation difference.
  //
  // This formula can easily exceed the max value of `1.0` so it's clamped. This means that many different
  // color variations will all be at the highest intensity, but that's OK, be there is more than one color
  // difference that's worthy of attention.
  final difference = (deltaValue + ((deltaHue * 3) + deltaSaturation) / 4).clamp(0.0, 1.0);
  if (doLog) {
    print(
        "Color 1 - red: ${c1.r}, green: ${c1.g}, blue: ${c1.b} - h: ${hsv1.hue}, s: ${hsv1.saturation}, v: ${hsv1.value}");
    print(
        "Color 2 - red: ${c2.r}, green: ${c2.g}, blue: ${c2.b} - h: ${hsv2.hue}, s: ${hsv2.saturation}, v: ${hsv2.value}");
    print("Difference: $difference");
  }

  return difference;
}
