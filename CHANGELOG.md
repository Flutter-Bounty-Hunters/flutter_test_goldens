## 0.0.5
### July 6, 2025
 * FEATURE: Add itemSetup to Gallery so that a single setup can be applied to all items.
 * FEATURE: Timeline now accepts a desired windowSize which it applies to the physicalSize in the test.
 * FIX: Make use of given spacing in GridGoldenSceneLayout
 * FIX/ADJUSTMENT: Don't paint to Canvas before taking photo with FlutterCamera - this broke nuanced render object and layer behavior in follow_the_leader. Instead, use toImageSync() on the existing RepaintBoundary.
 * ADJUSTMENT: Changed GridSceneLayout to use default item decorator and background to match existing behavior of FlexSceneLayout.
 * ADJUSTMENT: When a Gallery is given item constraints, it now sets its physicalSize to match the max bounds.
 * ADJUSTMENT: Changed the existing "minimal" Timeline itemScaffold to become the "standard" one, and then created a true "minimal" itemScaffold that makes no decisions about theme, background color, or padding.
 * ADJUSTMENT: Renamed "pump" method in Timeline to say "builder" because that's more of what it is.

## 0.0.4
### July 4, 2025
 * FIX: Blank failure images were being generated for passing tests.
 * FEATURE: Pixel mismatch tolerances for `SingleShot` and `Gallery`.

## 0.0.3
### July 4, 2025
Messed up this release. Replaced by `v0.0.4`.

## 0.0.2
### June 24, 2025 - Alpha
 * FEATURE: `SingleShot`: A Golden Scene that shows a single screenshot with an ergonomic API.
 * FEATURE: `Gallery`: A Golden Scene that screenshots independent widget trees.
 * FEATURE: `Timeline`: A Golden Scene that screenshots the same widget tree over time.
 * FEATURE: Detailed failure reports that go well beyond Flutter and `golden_toolkit` reporting.
 * FEATURE: Failure Scenes MVP: A scene that shows failing goldens with mismatch visualizations.
 * FEATURE: Golden Scene metadata is tracked in PNG metadata.
 * FEATURE: A variety of marketing goldens are available in the package docs.

## 0.0.1
### Feb 24, 2025 - Initial release
 * FEATURE: `GoldenCamera`: Takes and stores photos.
