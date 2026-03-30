---
name: "flutter-setting-up-on-linux"
description: "Sets up a Linux environment for Flutter development. Use when configuring a Linux machine to run, build, or deploy Flutter applications."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Thu, 12 Mar 2026 22:12:22 GMT"

---
# Setting Up a Linux Environment for Flutter Development

## Contents
- [System Dependencies](#system-dependencies)
- [Workflow: Configuring the Linux Toolchain](#workflow-configuring-the-linux-toolchain)
- [Workflow: Validating the Environment](#workflow-validating-the-environment)
- [Workflow: Preparing for Distribution (Snapcraft)](#workflow-preparing-for-distribution-snapcraft)
- [Examples](#examples)

## System Dependencies
To build and run Flutter applications on a Linux desktop, install the required C/C++ toolchain and system libraries. Flutter relies on `dart:ffi` to interface with Linux system calls and the GTK framework for UI rendering.

Required packages for Debian/Ubuntu-based distributions:
*   **Core Utilities:** `curl`, `git`, `unzip`, `xz-utils`, `zip`
*   **Build Tools:** `clang`, `cmake`, `ninja-build`, `pkg-config`
*   **Libraries:** `libglu1-mesa`, `libgtk-3-dev`, `libstdc++-12-dev`

## Workflow: Configuring the Linux Toolchain

Follow this sequential workflow to prepare the Linux host for Flutter desktop development.

**Task Progress:**
- [ ] 1. Update package lists and upgrade existing packages.
- [ ] 2. Install core utilities and build dependencies.
- [ ] 3. Configure IDE/Editor with Flutter support.
- [ ] 4. (Conditional) Enable Linux support on ChromeOS.

**1. Update and Install Dependencies**
Execute the following command to install all required packages on Debian/Ubuntu systems:
```bash
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa clang cmake ninja-build pkg-config libgtk-3-dev libstdc++-12-dev
```

**2. Conditional: ChromeOS Setup**
*   **If developing on a Chromebook:** Turn on Linux support in the ChromeOS settings. Ensure the Linux container is fully updated using the `apt-get` commands above before proceeding.

**3. IDE Configuration**
Install Visual Studio Code, Android Studio, or an IntelliJ-based IDE. Install the official Dart and Flutter extensions/plugins to enable language server features and debugging capabilities.

## Workflow: Validating the Environment

Run this feedback loop to ensure the toolchain is correctly recognized by the Flutter SDK.

**Task Progress:**
- [ ] 1. Run environment validator.
- [ ] 2. Verify connected Linux devices.
- [ ] 3. Resolve toolchain errors.

**1. Run Validator**
Execute the Flutter diagnostic tool with verbose output:
```bash
flutter doctor -v
```

**2. Review and Fix (Feedback Loop)**
*   **If errors exist under the "Linux toolchain" section:** Review the missing dependencies, install the flagged packages, and re-run `flutter doctor -v`. Repeat until the Linux toolchain section passes.

**3. Verify Device Availability**
Ensure the Linux desktop is recognized as a valid deployment target:
```bash
flutter devices
```
*Expected Output:* At least one entry must display with the platform marked as **linux**.

## Workflow: Preparing for Distribution (Snapcraft)

When preparing a release build for the Snap Store, configure the Snapcraft build environment.

**Task Progress:**
- [ ] 1. Install Snapcraft and LXD.
- [ ] 2. Configure LXD.
- [ ] 3. Build the Snap package.

**1. Install Build Tools**
```bash
sudo snap install snapcraft --classic
sudo snap install lxd
```

**2. Configure LXD**
Initialize LXD and add the current user to the `lxd` group:
```bash
sudo lxd init
sudo usermod -a -G lxd <your_username>
```
*Note: Log out and log back in to apply the group changes.*

**3. Build the Snap**
Navigate to the project root containing the `snap/snapcraft.yaml` file and execute the build:
```bash
snapcraft --use-lxd
```

## Examples

### Baseline `snapcraft.yaml` Configuration
Use this template for the `<project_root>/snap/snapcraft.yaml` file when packaging a Flutter Linux app for the Snap Store.

```yaml
name: super-cool-app
version: 0.1.0
summary: Super Cool App
description: Super Cool App that does everything!

confinement: strict
base: core22
grade: stable

slots:
  dbus-super-cool-app:
    interface: dbus
    bus: session
    name: org.bar.super_cool_app

apps:
  super-cool-app:
    command: super_cool_app
    extensions: [gnome]
    plugs:
    - network
    slots:
      - dbus-super-cool-app

parts:
  super-cool-app:
    source: .
    plugin: flutter
    flutter-target: lib/main.dart
```
