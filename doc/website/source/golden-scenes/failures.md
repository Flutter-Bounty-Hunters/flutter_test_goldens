---
title: Failures
navOrder: 40
---
`flutter_test_goldens` improves the review experience for failing golden tests.

Golden failures typically generate four files: the golden image, the new screenshot, an isolated
diff, and a masked diff. These images are useful, but viewing them across four files is tedious.

Instead of generating four separate image files upon failure, `flutter_test_goldens` paints
all four of those failure images as a single image, making it easy to view side-by-side.

Moreover, if a Golden Scene contains more than one golden image, all failure images for all
goldens in the scene, are painted to the same image. This provides the most holistic view
possible for a reviewing developer.

TODO: show examples