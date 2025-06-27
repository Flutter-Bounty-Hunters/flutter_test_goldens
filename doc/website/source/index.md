---
title: Welcome to Flutter Test Goldens
description: The world's best golden generator for Flutter apps
layout: layouts/docs_page.jinja
---
Welcome to the documentation website for `flutter_test_goldens`, the best package for
generating golden tests for Flutter apps.

## We solve your golden problems
Traditional Flutter golden tests come with a number of frustrating limitations. Here's
how we solve them.

 * **Failure Files:** Flutter spreads a single test failure across four different files.
   It's frustrating to have to open up multiple files to cross reference. With
   `flutter_test_goldes`, your failure output is painted to a single file for easy review.
 * **Widget Galleries:** Flutter developers often want to verify multiple configurations
   of a single widget, or multiple related widgets, at the same time. With
   `flutter_test_goldens`, you can easily paint a variety of widgets into a gallery,
   which is painted to a single golden file.
 * **Widget Interaction States:** What does your widget look like when the user hovers
   over it? Or presses it? What does your animation look like at 10ms, 20ms, 30ms?
   With `flutter_test_goldens`, you can paint a Timeline that shows how your widget
   changes over time, and across user interactions.
 * **Focus and Semantic Bounds:** Widgets aren't just what you see, they're also what you
   don't see. Traditional Flutter goldens have no way of tracking and verifying invisible
   bounds, like focus and semantics. With `flutter_test_goldens`, you can track these
   bounds as metadata. They won't pollute your pristine golden, but they'll be captured
   as metadata and verified when the test runs.
 * **Failure on Size Change:** In a traditional golden test, if a new golden has a different
   size, the test fails without painting the new golden at all. This makes it difficult to
   see what went wrong. With `flutter_test_goldens`, the new golden is always painted, even
   if the new output changes size. That way, you can review where things went wrong.
