---
title: Display Images
navOrder: 35 
---
Displaying images in a Flutter golden test is an especially annoying and tedious
process. The root cause is that Flutter's test system manually controls the passage
of time, which is important for inspecting UI frames, but prevents all real
asynchronous behavior from executing, including loading images.

There are three non-standard image loading scenarios in a golden test:
 * Loading from the network
 * Loading from a file
 * Loading from memory

## Display an Image from the Network
Apps often load images from the network. To load and display these images in a
golden test, you need to tell Flutter to allow network requests, and you need to
explicitly pre-cache the network image.

By default, Flutter forcibly prevents HTTP calls through an `HttpClient`. Fortunately, 
there's a mechanism to tell Flutter to mind its own business.

The following code is a minimal sample for loading images from the network within
a test.

```dart
void testWidgets("load a file image", (tester) async {
  // Normally, Flutter forcibly prevents HTTP calls. Turn that off by null'ing out
  // the HttpOverrides.
  final testOverride = HttpOverrides.current;
  HttpOverrides.global = null;
  addTearDown(() => HttpOverrides.global = testOverride);
  
  const imageUrl = "https://upload.wikimedia.org/wikipedia/commons/b/b3/Vista_Satelital_de_Nohyaxch%C3%A9_y_Edzn%C3%A1%2C_Campeche.png";
  
  // Load the image from the internet. This must be done in `runAsync` because
  // network communication is a real asynchronous behavior.
  await tester.runAsync(() async {
    await precacheImage(NetworkImage(imageUrl), tester.binding.rootElement!);
  });
  
  // Display the image in the widget tree.
  await tester.pumpWidget(
    MyApp(
      // Network images are globally key'd on their URL, so you don't have to
      // pass the same `ImageProvider` that you used to load the image.
      child: Image.network(imageUrl),
    ),
  );
});
```

The first thing you'll notice in the network image example is that we have to mess
with Flutter's `HttpOverrides`. This is where Flutter's test system installs its
own `HttpClient` that rejects every request. We turn that off, and we also setup
a test teardown method that restores it - we don't want to turn it off for all tests.

The one nice detail about using network images is that the image URL `String` can
be used to refer to that image anywhere. We don't have to pass the `ImageProvider`
into our widget tree, which means this is an approach that might actually work for
real-world apps.

If you use this approach, be mindful that images can disappear from the internet at any
time. Also, network conditions can change at any time. Network images introduce a
source of flakiness that you might need to deal with from time to time.

## Display an Image from File
Though less common than network images, an app might want to load an image from
the local file system. This load path only requires image pre-caching.

The following code is a minimal sample for loading images from a file within a test.

```dart
void testWidgets("load a file image", (tester) async {
  await tester.runAsync(() async {
    await precacheImage(FileImage(File("path/to/my_image.png")), tester.binding.rootElement!);
  });

  // Display the image in the widget tree.
  await tester.pumpWidget(
    MyApp(
      // File images are globally key'd on their `File`, so you don't have to
      // pass the same `ImageProvider` that you used to load the image.
      child: Image.network(imageUrl),
    ),
  );
});
```

Loading images from file is probably the easiest load path to orchestrate in a
golden test. However, it's only useful if your app happens to load images from
the local file system. As a result, this load path is probably only useful for 
some desktop apps.

## Display an Image from Memory
In rare situations, you might want to load an image into a widget tree based on
an in-memory representation. This would probably only happen if an image were
generated or altered within a test. However, we cover this load path for completeness.

Using an in-memory image in a test requires the same pre-caching as other loading
methods. This approach also requires that you use the same instance of your `ImageProvider`
both to load the image, as well as to display the image.

The following code is a minimal sample for displaying images from memory within a test.

```dart
void testWidgets("load an in-memory image", (tester) async {
  // Load or create your image data.
  final imageProvider = MemoryImage(
    // We use a File for code brevity, but if you want to load from a File
    // then use the File loading path.
    File("path/to/my_image.png").readAsBytesSync(),
  );

  // Use Flutter's `runAsync()` method so that you can run a real
  // asynchronous call from a test. Use this opportunity to call
  // Flutter's `precacheImage()` method to load your `ImageProvider`.
  await tester.runAsync(() async {
    await precacheImage(imageProvider, tester.binding.rootElement!);
  });

  await tester.pumpWidget(
    MyApp(
      child: Image(
        // Use the same `ImageProvider` in your widget tree.
        image: imageProvider,
      ),
    ),
  );
});
```

The biggest drawback of this load path, compared to other load paths, is that
you need to somehow get your `ImageProvider` from the test into your widget tree.
This is easy for an example where the entire tree is assembled in the test. However,
real tests use widget trees that don't expose inner `ImageProvider`s.

