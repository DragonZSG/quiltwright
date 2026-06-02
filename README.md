# Quiltwright

A quilt design app for macOS and iOS.

## Targets

- `QuiltwrightMac`: macOS SwiftUI app target.
- `QuiltwrightiOS`: iOS SwiftUI app target.
- `QuiltwrightUI`: shared SwiftUI package target used by both apps.
- `QuiltwrightChecks`: lightweight SwiftPM verification target for environments without XCTest.

## Getting Started

Open `Quiltwright.xcodeproj` in Xcode, then choose either the `QuiltwrightMac` or
`QuiltwrightiOS` scheme.

From the command line, the shared UI and macOS SwiftPM product can be checked with:

```sh
swift run QuiltwrightChecks
swift build --product QuiltwrightMac
```

The iOS app target is built from Xcode so it can use an iOS simulator or device
destination.

## CI

Buildkite runs `.buildkite/pipeline.yml`, which calls `script/ci.sh`.

The pipeline expects the Buildkite macOS queue `macos-medium`. `script/ci.sh`
uses the agent's selected Xcode by default. If your Buildkite queue or Xcode
path differs, update `.buildkite/pipeline.yml` or set `DEVELOPER_DIR` in the
pipeline environment.

Run the same checks locally with:

```sh
script/ci.sh all
```
