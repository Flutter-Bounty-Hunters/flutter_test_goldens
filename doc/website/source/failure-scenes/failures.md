---
title: What is a Failure Scene?
navOrder: 10
---
Building on the concept of [Golden Scenes](/golden-scenes/what-is-it), `flutter_test_goldens` introduces
the concept of "Failure Scenes". A Failure Scene is just like a Golden Scene, except instead of painting
a collection of goldens, it paints a collection of golden mismatch images.

In Flutter, golden failures typically generate four files: 
 * The golden image
 * The new screenshot
 * An isolated diff
 * A masked diff. 

These images are useful, but viewing them across four files is tedious. Not only do you have to
open and view 4 files to understand 1 failure, but the number of failure files quickly gets out of
control. Imagine goldens that cover 5 different configurations of a widget. Now, imagine that all
5 of those golden tests fail. Flutter would generate 5x4 = 20 failure files. This is intractable
within a production project.

The `golden_toolkit` package improved this issue by placing many different goldens in a single scene.
As a result, those 5 failures would generate a single failure file. But this approach still had its
issues - namely.

Moreover, if a Golden Scene contains more than one golden image, all failure images for all
goldens in the scene, are painted to the same image. This provides the most holistic view
possible for a reviewing developer.

TODO: show examples