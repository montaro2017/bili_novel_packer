---
name: "flutter-building-plugins"
description: "Builds Flutter plugins that provide native interop for other apps to use. Use when creating reusable packages that bridge Flutter with platform-specific functionality."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Thu, 12 Mar 2026 22:21:35 GMT"

---
# Developing Flutter Plugins

## Contents
- [Architecture & Design Patterns](#architecture--design-patterns)
- [Workflow: Creating a New Plugin](#workflow-creating-a-new-plugin)
- [Workflow: Implementing Android Platform Code](#workflow-implementing-android-platform-code)
- [Workflow: Implementing Windows Platform Code](#workflow-implementing-windows-platform-code)
- [Workflow: Adding Platforms to an Existing Plugin](#workflow-adding-platforms-to-an-existing-plugin)
- [Examples](#examples)

## Architecture & Design Patterns

### Federated Plugins
Implement federated plugins to split a plugin's API across multiple packages, allowing independent teams to build platform-specific implementations. Structure federated plugins into three distinct components:
1. **App-facing interface:** The primary package users depend on. It exports the public API.
2. **Platform interface:** The package defining the common interface that all platform implementations must implement.
3. **Platform implementations:** Independent packages containing platform-specific code (e.g., `my_plugin_android`, `my_plugin_windows`).

### FFI vs. Standard Plugins
Choose the correct plugin template based on your native interoperability requirements:
* **Standard Plugins (`--template=plugin`):** Use for accessing platform-specific APIs (e.g., Android SDK, iOS frameworks) via Method Channels.
* **FFI Plugins (`--template=plugin_ffi`):** Use for accessing C/C++ native libraries, configuring Google Play services on Android, or using static linking on iOS/macOS. 
  * *Constraint:* FFI plugin packages support bundling native code and method channel registration code, but *not* method channels themselves. If you require both method channels and FFI, use the standard non-FFI plugin template.

## Workflow: Creating a New Plugin

Follow this workflow to initialize a new plugin package.

**Task Progress:**
- [ ] Determine if the plugin requires FFI or standard Method Channels.
- [ ] Execute the appropriate `flutter create` command.
- [ ] Verify the generated directory structure.

**Conditional Initialization:**
* **If creating a STANDARD plugin:**
  Run the following command, specifying your supported platforms, organization, and preferred languages (defaults are Swift and Kotlin):
  ```bash
  flutter create --template=plugin \
    --platforms=android,ios,web,linux,macos,windows \
    --org com.example.organization \
    -i objc -a java \
    my_plugin
  ```
* **If creating an FFI plugin:**
  Run the following command to generate a project with Dart code in `lib` (using `dart:ffi`) and native source code in `src` (with a `CMakeLists.txt`):
  ```bash
  flutter create --template=plugin_ffi my_ffi_plugin
  ```

## Workflow: Implementing Android Platform Code

Always edit Android platform code using Android Studio to ensure proper code completion and Gradle synchronization.

**Task Progress:**
- [ ] Run initial build to generate necessary Gradle files.
- [ ] Open the Android module in Android Studio.
- [ ] Implement `FlutterPlugin` and lifecycle-aware interfaces.
- [ ] Refactor legacy `registerWith` logic.
- [ ] Run validator -> review errors -> fix.

1. **Generate Build Files:**
   Build the code at least once before editing to resolve dependencies.
   ```bash
   cd example
   flutter build apk --config-only
   ```
2. **Open in IDE:**
   Launch Android Studio and open the `example/android/build.gradle` or `example/android/build.gradle.kts` file.
3. **Locate Source:**
   Navigate to your plugin's source code at `java/<organization-path>/<PluginName>`.
4. **Implement V2 Embedding:**
   * Implement the `FlutterPlugin` interface.
   * Ensure your plugin class has a public constructor.
   * Extract shared initialization logic from the legacy `registerWith()` method and the new `onAttachedToEngine()` method into a single private method. Both entry points must call this private method to maintain backward compatibility without duplicating logic.
5. **Implement Lifecycle Interfaces:**
   * **If your plugin requires an `Activity` reference:** Implement the `ActivityAware` interface and handle the `onAttachedToActivity`, `onDetachedFromActivityForConfigChanges`, `onReattachedToActivityForConfigChanges`, and `onDetachedFromActivity` callbacks.
   * **If your plugin runs in a background `Service`:** Implement the `ServiceAware` interface.
6. **Update Example App:**
   Ensure the example app's `MainActivity.java` extends the v2 embedding `io.flutter.embedding.android.FlutterActivity`.
7. **Document API:**
   Document all non-overridden public members in your Android implementation.

## Workflow: Implementing Windows Platform Code

Always edit Windows platform code using Visual Studio.

**Task Progress:**
- [ ] Run initial build to generate the Visual Studio solution.
- [ ] Open the solution in Visual Studio.
- [ ] Implement C++ logic.
- [ ] Rebuild the solution.

1. **Generate Build Files:**
   ```bash
   cd example
   flutter build windows
   ```
2. **Open in IDE:**
   Launch Visual Studio and open the `example/build/windows/hello_example.sln` file.
3. **Locate Source:**
   Navigate to `hello_plugin/Source Files` and `hello_plugin/Header Files` in the Solution Explorer.
4. **Rebuild:**
   After making changes to the C++ plugin code, you *must* rebuild the solution in Visual Studio before running the app, or the outdated plugin binary will be used.

## Workflow: Adding Platforms to an Existing Plugin

Use this workflow to retrofit an existing plugin with support for additional platforms.

**Task Progress:**
- [ ] Run the platform addition command.
- [ ] Update iOS/macOS podspecs (if applicable).
- [ ] Implement the platform-specific code.

1. **Run Create Command:**
   Navigate to the root directory of your existing plugin and run:
   ```bash
   flutter create --template=plugin --platforms=web,macos .
   ```
2. **Update Podspecs:**
   If adding iOS or macOS support, open the generated `.podspec` file and configure the required dependencies and deployment targets.

## Examples

### Android V2 Embedding Implementation
High-fidelity example of an Android plugin implementing `FlutterPlugin` and `ActivityAware` while maintaining legacy compatibility.

```java
package com.example.myplugin;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** MyPlugin */
public class MyPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  private MethodChannel channel;

  // Public constructor required for v2 embedding
  public MyPlugin() {}

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    setupChannel(flutterPluginBinding.getBinaryMessenger());
  }

  // Legacy v1 embedding support
  public static void registerWith(Registrar registrar) {
    MyPlugin plugin = new MyPlugin();
    plugin.setupChannel(registrar.messenger());
  }

  // Shared initialization logic
  private void setupChannel(BinaryMessenger messenger) {
    channel = new MethodChannel(messenger, "my_plugin");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    // Handle Activity attachment
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    // Handle config changes
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    // Handle reattachment
  }

  @Override
  public void onDetachedFromActivity() {
    // Clean up Activity references
  }
}
```
