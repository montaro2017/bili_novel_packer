---
name: "flutter-reducing-app-size"
description: "Measures and optimizes the size of Flutter application bundles for deployment. Use when minimizing download size or meeting app store package constraints."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Thu, 12 Mar 2026 22:22:44 GMT"

---
# Reducing Flutter App Size

## Contents
- [Core Concepts](#core-concepts)
- [Workflow: Generating Size Analysis Files](#workflow-generating-size-analysis-files)
- [Workflow: Analyzing Size Data in DevTools](#workflow-analyzing-size-data-in-devtools)
- [Workflow: Estimating iOS Download Size](#workflow-estimating-ios-download-size)
- [Workflow: Implementing Size Reduction Strategies](#workflow-implementing-size-reduction-strategies)
- [Examples](#examples)

## Core Concepts
- **Debug vs. Release:** Never use debug builds to measure app size. Debug builds include VM overhead and lack Ahead-Of-Time (AOT) compilation and tree-shaking.
- **Upload vs. Download Size:** The size of an upload package (APK, AAB, IPA) does not represent the end-user download size. App stores filter redundant native library architectures and asset densities based on the target device.
- **AOT Tree-Shaking:** The Dart AOT compiler automatically removes unused or unreachable code in profile and release modes.
- **Size Analysis JSON:** The `--analyze-size` flag generates a `*-code-size-analysis_*.json` file detailing the byte size of packages, libraries, classes, and functions.

## Workflow: Generating Size Analysis Files

Use this workflow to generate the raw data required for size analysis.

**Task Progress:**
- [ ] Determine the target platform (apk, appbundle, ios, linux, macos, windows).
- [ ] Run the Flutter build command with the `--analyze-size` flag.
- [ ] Locate the generated `*-code-size-analysis_*.json` file in the `build/` directory.

**Conditional Logic:**
- **If targeting Android:** Run `flutter build apk --analyze-size` or `flutter build appbundle --analyze-size`.
- **If targeting iOS:** Run `flutter build ios --analyze-size`. *Note: This creates a `.app` file useful for relative content sizing, but not for estimating final App Store download size. Use the [Estimating iOS Download Size](#workflow-estimating-ios-download-size) workflow for accurate iOS metrics.*
- **If targeting Desktop:** Run `flutter build [windows|macos|linux] --analyze-size`.

## Workflow: Analyzing Size Data in DevTools

Use this workflow to visualize and drill down into the Size Analysis JSON.

**Task Progress:**
- [ ] Launch DevTools by running `dart devtools` in the terminal.
- [ ] Select "Open app size tool" from the DevTools landing page.
- [ ] Upload the generated `*-code-size-analysis_*.json` file.
- [ ] Inspect the treemap or tree view to identify large packages, libraries, or assets.
- [ ] **Feedback Loop:** 
  1. Identify the largest contributors to app size.
  2. Determine if the dependency or asset is strictly necessary.
  3. Remove, replace, or optimize the identified component.
  4. Regenerate the Size Analysis JSON and compare the new build against the old build using the DevTools "Diff" tab.

## Workflow: Estimating iOS Download Size

Use this workflow to get an accurate projection of iOS download and installation sizes across different devices.

**Task Progress:**
- [ ] Configure the app version and build number in `pubspec.yaml`.
- [ ] Generate an Xcode archive by running `flutter build ipa --export-method development`.
- [ ] Open the generated archive (`build/ios/archive/*.xcarchive`) in Xcode.
- [ ] Click **Distribute App** and select **Development**.
- [ ] In the App Thinning configuration, select **All compatible device variants**.
- [ ] Check the option to **Strip Swift symbols**.
- [ ] Sign and export the IPA.
- [ ] Open the exported directory and review the `App Thinning Size Report.txt` file to evaluate projected sizes per device.

## Workflow: Implementing Size Reduction Strategies

Apply these strategies to actively reduce the compiled footprint of the application.

**Task Progress:**
- [ ] **Split Debug Info:** Strip debug symbols from the compiled binary and store them in separate files.
- [ ] **Remove Unused Resources:** Audit the `pubspec.yaml` and `assets/` directory. Delete any images, fonts, or files not actively referenced in the codebase.
- [ ] **Minimize Library Resources:** Review third-party packages. If a package imports massive resource files (e.g., large icon sets or localization files) but only a fraction is used, consider alternative packages or custom implementations.
- [ ] **Compress Media:** Compress all PNG and JPEG assets using tools like `pngquant`, `imageoptim`, or WebP conversion before bundling them into the app.

## Examples

### Generating Size Analysis (Android)
```bash
# Generate the size analysis JSON for an Android App Bundle
flutter build appbundle --analyze-size --target-platform=android-arm64
```

### Splitting Debug Info (Release Build)
```bash
# Build an APK while stripping debug info to reduce binary size
flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols
```

### Reading the iOS App Thinning Size Report
When reviewing `App Thinning Size Report.txt`, look for the specific target device to understand the true impact on the user:
```text
Variant: Runner-7433FC8E-1DF4-4299-A7E8-E00768671BEB.ipa
Supported variant descriptors: [device: iPhone12,1, os-version: 13.0]
App + On Demand Resources size: 5.4 MB compressed, 13.7 MB uncompressed
App size: 5.4 MB compressed, 13.7 MB uncompressed
```
*Interpretation: The end-user download size (compressed) is 5.4 MB, and the on-device footprint (uncompressed) is 13.7 MB.*
