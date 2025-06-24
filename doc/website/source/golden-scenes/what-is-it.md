---
title: What is a Golden Scene?
navOrder: 10
---
Golden scenes are one of `flutter_test_golden`'s major innovations. A Golden Scene
is a single image file that contains any number of individual golden images within it.

> Note: If you're familiar with `golden_toolkit` you might think that Golden Scenes are just
> another name for `golden_toolkit` `GoldenBuilder`s, which have existed for years. This isn't the
> case. We address this in its own section below.

Historically, Flutter paints a single golden image to a file. One file means one golden,
and one golden means one file. One file per golden is very cumbersome when working with
a large number of golden images - especially when multiple goldens are related, such as
different visual states of the same widget.

A Golden Scene with independent golden images, such as different configurations of the same
widget, is called a [Gallery](/golden-scenes/gallery).

A Golden Scene with golden images that take place over time, such as the idle, hovered, and
pressed state of a button, is called a [Timeline](/golden-scenes/timeline).

## What makes Golden Scenes different?
Fans of golden tests are no doubt familiar with `golden_toolkit`, a package by eBay Motors,
which has long been the most popular package for writing golden tests. 

> Note: The `golden_toolkit` package is now discontinued, and no longer supported.

The `golden_toolkit` package included the concept of a `GoldenBuilder`, which painted multiple
widget configurations to the same image file. The purpose and visual output of `golden_toolkit`
`GoldenBuilder`s is similar to `flutter_test_golden` Golden Scenes, but we've taken the concept to
a new level of capability and value.

### Extracting Golden Images from a Scene
Unlike `golden_toolkit`, `flutter_test_goldens` doesn't do a pixel comparison of an entire file.
`flutter_test_goldens` tracks the position of every golden image in the Golden Scene file and
extracts just the golden images for comparison.

When comparing an entire file, you end up comparing decorations, too. You compare the text labels
beneath each golden image. You compare borders around each golden image. But none of these decorations
are relevant to your test. These decorations are for human reviewers, not for the computer that's
running the comparison. `flutter_test_goldens` ignores these decorations, leaving you free to
paint whatever details you want, around the golden images in the scene.

### Capturing Goldens over Time
`golden_toolkit` made it possible to capture multiple widget configurations in a single golden file,
but each of those widget configurations were independent widget trees. There was no concept of time.
What if you want to capture the idle state, the hover state, and the pressed state of the same button?
`golden_toolkit` couldn't help you.

`flutter_test_goldens` includes the concept of a `GoldenCamera`, which allows developers to take screenshots
over a period of time. Those screenshots can then be stitched together into a Golden Scene, such as
with a [`Timeline`](/golden-scenes/timeline).
