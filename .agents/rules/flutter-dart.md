---
trigger: glob
description: Flutter and Dart architecture conventions for Smart CV Maker
globs: "lib/**/*.dart, test/**/*.dart"
---

# Flutter and Dart

- Keep Widgets focused on rendering and event forwarding.
- Use Riverpod for mutable application and feature state.
- Access data through repositories; do not call Supabase from Widgets.
- Prefer immutable models with explicit `fromJson`, `toJson`, and `copyWith` behavior.
- Keep navigation declarative with GoRouter and pass `cvId` explicitly.
- Avoid business logic in controllers and UI callbacks.
- Dispose controllers and subscriptions owned by StatefulWidgets.
- Use clear English identifiers; user-facing text may be Vietnamese.
- Do not swallow exceptions; map them to useful states or rethrow typed failures.
- Add widget tests for important UI states and unit tests for domain/data logic.
- Format changed Dart files and keep `flutter analyze` free of new issues.

