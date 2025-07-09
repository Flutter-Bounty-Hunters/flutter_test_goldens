---
title: Running on GitHub
description: How to run and manage golden tests on GitHub CI.
navOrder: 10
---
GitHub is the most popular place to run tests, including golden tests, because its
free, and GitHub is the place where almost everyone hosts their source code and
reviews pull requests (PRs).

## Run Golden Tests on GitHub
The following YAML configuration shows how to run Flutter golden tests in a GitHub
Runner. This particular example is configured to run on every PR, but you can adjust
it for other use-cases. Place this configuration in your project at `.github/workflows/pr_validation.yaml`.

```yaml
name: PR Validation
on:
  pull_request:

jobs:
  test_goldens:
    runs-on: ubuntu-latest
    steps:
      # Checkout the repository.
      - uses: actions/checkout@v3

      # Setup Flutter environment.
      - uses: subosito/flutter-action@v2
        with:
          channel: "stable"

      # Download all the packages that the app uses.
      - run: flutter pub get

      # Run all golden tests (change for whatever directory you use).
      - run: flutter test test_goldens
```

## Download Failures from GitHub
By default, when running golden tests on GitHub CI, you can only see the terminal
output for failures. It's often very helpful to be able to see the actual Failure
Scenes, so that you can understand why your local tests passed, but GitHub failed.

To be able to download Failure Scene images, you must configure GitHub CI to upload
those images within the job.

Assuming that all of your failure are stored within subdirectories called `failures`,
adjust your GitHub CI configuration to place the following step at the end of your
job. This typically follows immediately after `- run: flutter test test_goldens`.

```yaml
# Archive golden failures
- uses: actions/upload-artifact@v4
  if: failure()
  with:
    name: golden-failures
    path: "**/failures/**/*.png"
```

Adjust the `path` for wherever/however you choose to store your failure images.
