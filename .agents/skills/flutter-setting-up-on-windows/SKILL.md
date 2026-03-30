---
name: "flutter-setting-up-on-windows"
description: "Sets up a Windows environment for Flutter development. Use when configuring a Windows machine to run, build, or deploy Flutter applications for Windows desktop or Android."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Thu, 12 Mar 2026 22:13:13 GMT"

---
# Setting Up Flutter for Windows Development

## Contents
- [Core Requirements](#core-requirements)
- [Workflow: Installing and Configuring the SDK](#workflow-installing-and-configuring-the-sdk)
- [Workflow: Configuring Tooling and IDEs](#workflow-configuring-tooling-and-ides)
- [Workflow: Configuring Target Platforms](#workflow-configuring-target-platforms)
- [Workflow: Building and Packaging for Windows](#workflow-building-and-packaging-for-windows)
- [Workflow: Generating and Installing Certificates](#workflow-generating-and-installing-certificates)
- [Examples](#examples)

## Core Requirements
Configure the Windows environment to support both Flutter framework execution and native C/C++ compilation. Differentiate strictly between **Visual Studio** (required for Windows desktop C++ compilation) and **VS Code** (the recommended Dart/Flutter code editor). 

## Workflow: Installing and Configuring the SDK

Follow this sequential workflow to initialize the Flutter SDK on a Windows machine.

- [ ] Download the latest stable Flutter SDK for Windows.
- [ ] Extract the SDK to a directory with standard user privileges (e.g., `C:\src\flutter`). Do not install in protected directories like `C:\Program Files\`.
- [ ] Copy the absolute path to the Flutter SDK's `bin` directory.
- [ ] Open Windows Environment Variables settings and append the `bin` directory path to the system or user `PATH` variable.
- [ ] Open a new terminal session to apply the `PATH` changes.
- [ ] **Feedback Loop:** Run validator -> review errors -> fix.
  1. Execute `flutter doctor -v`.
  2. Review the output for missing dependencies or path issues.
  3. Resolve any flagged errors before proceeding to tooling setup.

## Workflow: Configuring Tooling and IDEs

- [ ] Install **Visual Studio** (not VS Code). 
- [ ] Select and install the **Desktop development with C++** workload during the Visual Studio installation process. This is mandatory for compiling Windows desktop applications.
- [ ] Install your preferred code editor (VS Code, Android Studio, or IntelliJ).
- [ ] Install the official Flutter and Dart extensions/plugins within your chosen editor.

## Workflow: Configuring Target Platforms

Apply conditional logic based on the specific platform you are targeting for development.

**If targeting Windows Desktop:**
- [ ] Ensure the Visual Studio C++ workload is fully updated.
- [ ] Restart your IDE so it detects the Windows desktop device.
- [ ] To disable platforms you do not intend to compile for, execute `flutter config --no-enable-<platform>` (e.g., `flutter config --no-enable-windows-desktop`).

**If targeting Android on Windows:**
- [ ] **For physical devices:** Enable Developer Options and USB debugging on the device. Install the specific OEM USB drivers for Windows.
- [ ] **For emulators:** Open the Android Virtual Device (AVD) manager. Under "Emulated Performance" -> "Graphics acceleration", select an option specifying "Hardware" to enable hardware acceleration.
- [ ] Verify the device connection by running `flutter devices`.

## Workflow: Building and Packaging for Windows

To distribute a Windows desktop application, assemble the compiled executable and its required dependencies into a single distributable archive.

- [ ] Execute `flutter build windows` to compile the release build.
- [ ] Navigate to `build\windows\runner\Release\`.
- [ ] Create a new staging directory for the distribution zip.
- [ ] Copy the following assets from the `Release` directory into the staging directory:
  - The application executable (`.exe`).
  - All generated `.dll` files.
  - The entire `data` directory.
- [ ] Copy the required Visual C++ redistributables into the staging directory alongside the executable:
  - `msvcp140.dll`
  - `vcruntime140.dll`
  - `vcruntime140_1.dll`
- [ ] Compress the staging directory into a `.zip` file for distribution.

## Workflow: Generating and Installing Certificates

If you require a self-signed certificate for MSIX packaging or local testing, use OpenSSL.

- [ ] Install OpenSSL and add its `bin` directory to your `PATH` environment variable.
- [ ] Generate a private key: `openssl genrsa -out mykeyname.key 2048`
- [ ] Generate a Certificate Signing Request (CSR): `openssl req -new -key mykeyname.key -out mycsrname.csr`
- [ ] Generate the signed certificate (CRT): `openssl x509 -in mycsrname.csr -out mycrtname.crt -req -signkey mykeyname.key -days 10000`
- [ ] Generate the `.pfx` file: `openssl pkcs12 -export -out CERTIFICATE.pfx -inkey mykeyname.key -in mycrtname.crt`
- [ ] Install the `.pfx` certificate on the local Windows machine. Place it in the Certificate Store under **Trusted Root Certification Authorities** prior to installing the application.

## Examples

### Windows Distribution Directory Structure
When assembling your Windows build for distribution, ensure the directory structure strictly matches the following layout before zipping:

```text
Release_Archive/
│   my_flutter_app.exe
│   flutter_windows.dll
│   msvcp140.dll
│   vcruntime140.dll
│   vcruntime140_1.dll
│
└───data/
    │   app.so
    │   icudtl.dat
    │   ...
```
