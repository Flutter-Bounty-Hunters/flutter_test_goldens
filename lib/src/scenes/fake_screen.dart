import 'dart:ui' show DisplayFeature;

import 'package:flutter/widgets.dart';
import 'package:super_keyboard/super_keyboard_test.dart';

/// Widget that pretends to be the device screen, intended for goldens that include
/// absolute screen positioning, such as displaying a fake mobile keyboard, keyboard
/// panels, etc.
///
/// [FakeScreen] includes a [SoftwareKeyboardHeightSimulator] within it, which can be
/// configured with various properties provided by [FakeScreen].
class FakeScreen extends StatelessWidget {
  static const defaultSoftwareKeyboardHeight = 300.0;

  const FakeScreen({
    super.key,
    required this.size,
    this.devicePixelRatio = 1.0,
    this.padding = EdgeInsets.zero,
    this.viewPadding = EdgeInsets.zero,
    this.systemGestureInsets = EdgeInsets.zero,
    this.pushContentAboveKeyboard = true,
    this.displayFeatures = const <DisplayFeature>[],
    this.isSoftwareKeyboardEnabled = true,
    this.enableSoftwareKeyboardForAllPlatforms = false,
    this.keyboardHeight = defaultSoftwareKeyboardHeight,
    this.renderSimulatedKeyboard = false,
    this.animateKeyboard = false,
    required this.child,
  });

  /// The `size` set on the [MediaQuery] within this [FakeScreen].
  final Size size;

  /// The `devicePixelRatio` set on the [MediaQuery] within this [FakeScreen].
  final double devicePixelRatio;

  /// The `padding` set on the [MediaQuery] within this [FakeScreen].
  final EdgeInsets padding;

  /// The `viewPadding` set on the [MediaQuery] within this [FakeScreen].
  final EdgeInsets viewPadding;

  /// The `systemGestureInsets` set on the [MediaQuery] within this [FakeScreen].
  final EdgeInsets systemGestureInsets;

  /// The `displayFeatures` set on the [MediaQuery] within this [FakeScreen].
  final List<DisplayFeature> displayFeatures;

  /// Whether or not to enable the simulated software keyboard insets.
  ///
  /// This property is provided so that clients don't need to conditionally add/remove
  /// this widget from the tree. Instead this flag can be flipped, as needed.
  final bool isSoftwareKeyboardEnabled;

  /// Whether to simulate software keyboard insets for all platforms (`true`), or whether to
  /// only simulate software keyboard insets for mobile platforms, e.g., Android, iOS (`false`).
  ///
  /// The value for this property should remain constant within a single test. Don't
  /// attempt to enable and then disable keyboard simulation. That behavior is undefined.
  final bool enableSoftwareKeyboardForAllPlatforms;

  /// The vertical space, in logical pixels, to occupy at the bottom of the screen to simulate the appearance
  /// of a keyboard.
  final double keyboardHeight;

  /// Whether a fake software keyboard should be displayed in the widget tree,
  /// on top of the [child], simulating a real OS software keyboard.
  final bool renderSimulatedKeyboard;

  /// Whether to simulate keyboard open/closing animations.
  ///
  /// These animations change the keyboard insets over time, similar to how a real
  /// software keyboard slides up/down. However, this also means that clients need to
  /// `pumpAndSettle()` to ensure the animation is complete. If you want to avoid `pumpAndSettle()`
  /// and you don't care about the animation, then pass `false` to disable the animations.
  final bool animateKeyboard;

  /// Whether the [child] content should be laid out from the top of the area down to
  /// the top of a simulated keyboard (`true`), or whether the [child] should be laid
  /// out from the top of the area all the way to the bottom of the area, behind any
  /// simulated keyboard (`false`).
  final bool pushContentAboveKeyboard;

  /// The content displayed within this [FakeScreen].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
      child: SizedBox.fromSize(
        size: size,
        child: MediaQuery(
          data: (MediaQuery.maybeOf(context) ?? const MediaQueryData()).copyWith(
            size: size,
            devicePixelRatio: devicePixelRatio,
            padding: padding,
            viewInsets: EdgeInsets.zero,
            viewPadding: viewPadding,
            systemGestureInsets: systemGestureInsets,
            displayFeatures: displayFeatures,
          ),
          child: ClipRect(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SoftwareKeyboardHeightSimulator(
                isEnabled: isSoftwareKeyboardEnabled,
                enableForAllPlatforms: enableSoftwareKeyboardForAllPlatforms,
                keyboardHeight: keyboardHeight,
                renderSimulatedKeyboard: renderSimulatedKeyboard,
                animateKeyboard: animateKeyboard,
                child: Builder(builder: (context) {
                  final keyboardInsets = MediaQuery.of(context).viewInsets.bottom;

                  return Padding(
                    padding: EdgeInsets.only(bottom: pushContentAboveKeyboard ? keyboardInsets : 0),
                    child: Overlay(
                      initialEntries: <OverlayEntry>[
                        OverlayEntry(builder: (BuildContext context) => child),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
