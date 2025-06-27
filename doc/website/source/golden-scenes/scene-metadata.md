---
title: Scene Metadata
navOrder: 20
---
For Golden Scenes to work, `flutter_test_goldens` needs to know the offset and size of every
golden image in the scene. This is how each golden image is compared and reported individually.
Additionally, `flutter_test_goldens` can track invisible bounds, like focus and semantics.

Golden image bounds, and layers like focus and semantics, are tracked in a metadata structure
within each Golden Scene PNG file.

The metadata is stored, specifically, in the PNG's `iTXt` metadata field. The `iTXt` field is
part of the PNG specification, and is meant to hold arbitrary utf8-encoded text. The metadata
text stored within the `iTXt` field is further encoded as JSON to give it structure.

The use of the PNG `iTXt` field to store Golden Scene metadata is another innovation by 
`flutter_test_goldens`. Most tools track metadata by adding invisible files or directories, such
as a `.golden-scene` file. But, by including metadata within each Golden Scene file, developers 
never need to worry about losing the tracking file. As long as you have the golden file, you
have everything you need to interpret the file, and run tests against it.

## Schema
TODO:

## Read
TODO:

## Write
TODO: