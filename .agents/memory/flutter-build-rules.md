---
name: Flutter build rules
description: Critical package exclusions and Dart compilation rules for HeartSync Flutter app
---

## Rule: Never add encrypt / pointycastle / crypto to pubspec.yaml
**Why:** These packages cause a `Matrix4 isn't a type` crash deep in Flutter SDK internals (vector_math type conflict). The error appears in Flutter SDK files, not user code, making it very confusing. Removing these packages fixed the crash.

**How to apply:** If you need client-side encryption, use Flutter's built-in `dart:convert` base64 or implement it without the `encrypt` package. Check pubspec.yaml before any `flutter pub add` that touches crypto libraries.

## Rule: After `flutter clean`, always run `flutter pub get` before restarting the workflow
**Why:** The workflow uses `--no-pub` flag. `flutter clean` deletes `.dart_tool/package_config.json`, causing `flutter run --no-pub` to fail with "Did you run this command from the same directory as your pubspec.yaml?"

**How to apply:** Always pair `flutter clean` + `flutter pub get` before restart, never just `flutter clean`.

## Rule: textAlign belongs on Text widget, not TextStyle
**Why:** `TextStyle` has no `textAlign` property — it belongs on `Text(textAlign: ...)`. This is a common mistake that causes compiler errors.

## Rule: Extensions that shadow existing fields cause null-safety confusion
**Why:** Adding an extension `Color? get accent` on a class that already has non-nullable `Color accent` causes analysis warnings and confusion. Remove redundant extensions.
