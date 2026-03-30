---
name: "flutter-handling-http-and-json"
description: "Executes HTTP requests and handles JSON serialization in a Flutter app. Use when integrating with REST APIs or parsing structured data from external sources."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Thu, 12 Mar 2026 22:18:44 GMT"

---
# Handling HTTP and JSON

## Contents
- [Core Guidelines](#core-guidelines)
- [Workflow: Executing HTTP Operations](#workflow-executing-http-operations)
- [Workflow: Implementing JSON Serialization](#workflow-implementing-json-serialization)
- [Workflow: Parsing Large JSON in the Background](#workflow-parsing-large-json-in-the-background)
- [Examples](#examples)

## Core Guidelines

- **Enforce HTTPS:** iOS and Android disable cleartext (HTTP) connections by default. Always use HTTPS endpoints. If HTTP is strictly required for debugging, configure `network_security_config.xml` (Android) and `NSAppTransportSecurity` (iOS).
- **Construct URIs Safely:** Always use `Uri.https(authority, unencodedPath, [queryParameters])` to safely build URLs. This handles encoding and formatting reliably, preventing string concatenation errors.
- **Handle Status Codes:** Always validate the `http.Response.statusCode`. Treat `200` (OK) and `201` (Created) as success. Throw explicit exceptions for other codes (do not return `null`).
- **Prevent UI Jank:** Move expensive JSON parsing operations (taking >16ms) to a background isolate using the `compute()` function.
- **Structured AI Output:** When integrating LLMs, enforce reliable JSON output by specifying a strict JSON schema in the system prompt and setting the response MIME type to `application/json`.

## Workflow: Executing HTTP Operations

Use this workflow to implement network requests using the `http` package.

**Task Progress:**
- [ ] Add the `http` package to `pubspec.yaml`.
- [ ] Configure platform permissions (Internet permission in `AndroidManifest.xml` and macOS `.entitlements`).
- [ ] Construct the target `Uri`.
- [ ] Execute the HTTP method.
- [ ] Validate the response and parse the JSON payload.

**Conditional Implementation:**
- **If fetching data (GET):** Use `http.get(uri)`.
- **If sending new data (POST):** Use `http.post(uri, headers: {...}, body: jsonEncode(data))`. Ensure `Content-Type` is `application/json; charset=UTF-8`.
- **If updating data (PUT):** Use `http.put(uri, headers: {...}, body: jsonEncode(data))`.
- **If deleting data (DELETE):** Use `http.delete(uri, headers: {...})`.

**Feedback Loop: Validation & Error Handling**
1. Run the HTTP request.
2. Check `response.statusCode`.
3. If `200` or `201`, call `jsonDecode(response.body)` and map to a Dart object.
4. If any other code, throw an `Exception('Failed to load/update/delete resource')`.
5. Review errors -> fix endpoint, headers, or payload structure.

## Workflow: Implementing JSON Serialization

Choose the serialization strategy based on project complexity.

**Conditional Implementation:**
- **If building a small prototype or simple models:** Use manual serialization with `dart:convert`.
- **If building a production app with complex/nested models:** Use code generation with `json_serializable`.

### Manual Serialization Setup
**Task Progress:**
- [ ] Import `dart:convert`.
- [ ] Define the Model class with `final` properties.
- [ ] Implement a `factory Model.fromJson(Map<String, dynamic> json)` constructor.
- [ ] Implement a `Map<String, dynamic> toJson()` method.

### Code Generation Setup (`json_serializable`)
**Task Progress:**
- [ ] Add dependencies: `flutter pub add json_annotation` and `flutter pub add -d build_runner json_serializable`.
- [ ] Import `json_annotation.dart` in the model file.
- [ ] Add the `part 'model_name.g.dart';` directive.
- [ ] Annotate the class with `@JsonSerializable()`. Use `explicitToJson: true` if the class contains nested models.
- [ ] Define the `fromJson` factory and `toJson` method delegating to the generated functions.
- [ ] Run the generator: `dart run build_runner build --delete-conflicting-outputs`.

## Workflow: Parsing Large JSON in the Background

Use this workflow to prevent frame drops when parsing large JSON payloads (e.g., lists of 1000+ items).

**Task Progress:**
- [ ] Create a top-level or static function that takes a `String` (the response body) and returns the parsed Dart object (e.g., `List<Model>`).
- [ ] Inside the function, call `jsonDecode` and map the results to the Model class.
- [ ] In the HTTP fetch method, pass the top-level parsing function and the `response.body` to Flutter's `compute()` function.

## Examples

### Example 1: HTTP GET with Manual Serialization
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class Album {
  final int id;
  final String title;

  const Album({required this.id, required this.title});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as int,
      title: json['title'] as String,
    );
  }
}

Future<Album> fetchAlbum() async {
  final uri = Uri.https('jsonplaceholder.typicode.com', '/albums/1');
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception('Failed to load album');
  }
}
```

### Example 2: HTTP POST Request
```dart
Future<Album> createAlbum(String title) async {
  final uri = Uri.https('jsonplaceholder.typicode.com', '/albums');
  final response = await http.post(
    uri,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{'title': title}),
  );

  if (response.statusCode == 201) {
    return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception('Failed to create album.');
  }
}
```

### Example 3: Background Parsing with `compute`
```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// 1. Top-level function for parsing
List<Photo> parsePhotos(String responseBody) {
  final parsed = (jsonDecode(responseBody) as List<Object?>)
      .cast<Map<String, Object?>>();
  return parsed.map<Photo>(Photo.fromJson).toList();
}

// 2. Fetch function using compute
Future<List<Photo>> fetchPhotos(http.Client client) async {
  final uri = Uri.https('jsonplaceholder.typicode.com', '/photos');
  final response = await client.get(uri);

  if (response.statusCode == 200) {
    // Run parsePhotos in a separate isolate
    return compute(parsePhotos, response.body);
  } else {
    throw Exception('Failed to load photos');
  }
}
```

### Example 4: Code Generation (`json_serializable`)
```dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(explicitToJson: true)
class User {
  final String name;
  
  @JsonKey(name: 'registration_date_millis')
  final int registrationDateMillis;

  User(this.name, this.registrationDateMillis);

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```
