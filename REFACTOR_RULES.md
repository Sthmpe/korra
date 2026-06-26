# REFACTOR_RULES.md
# Korra Flutter Project — Refactor Instructions for Claude Code
# READ THIS ENTIRE FILE BEFORE TOUCHING ANY CODE

---

## 1. IDENTITY OF THIS PROJECT

- Project name: korra
- Framework: Flutter (Dart)
- State management: BLoC (do NOT suggest or switch to GetX, Riverpod, or Provider)
- Authentication: Firebase Auth
- Primary database: Firebase Firestore
- File storage: Supabase Storage (NOT Firebase Storage — Firebase Storage is not used)
- Edge functions: Supabase (Deno)
- Branch to work on: refactor/clean-architecture
- Main branch: NEVER touch, NEVER push to main

---

## 2. ABSOLUTE RULES — NEVER BREAK THESE

1. NEVER push to main branch
2. NEVER rename any field or variable that maps to a Firestore document field or Firebase Auth property
3. NEVER rename any field used in Supabase edge function calls or RPC payloads
4. NEVER change any UI layout — no padding, margin, sizing, colors, or widget positioning
5. NEVER change the visual appearance of any screen
6. NEVER delete any file — only refactor and reorganise
7. NEVER change file names of existing files
8. NEVER modify anything outside lib/ and supabase/ folders
9. NEVER run flutter pub add or add new dependencies without asking first
10. NEVER refactor the next folder until the current folder is approved
11. NEVER make one giant commit — commit per folder or per logical group of files

---

## 3. FOLDERS YOU ARE ALLOWED TO TOUCH

- lib/ — full access to refactor
- supabase/ — full access to refactor

## FOLDERS YOU MUST COPY AS-IS (do not touch internals)

- android/
- ios/
- web/
- windows/
- linux/
- macos/
- test/
- assets/
- pubspec.yaml — do NOT modify
- pubspec.lock — do NOT modify
- Any file in the project root except REFACTOR_RULES.md

---

## 4. FIREBASE AND SUPABASE FIELD NAME PROTECTION

### Firebase Firestore rules:
- If you see a variable used inside any Firestore call — collection(), doc(), get(), set(), update(), where(), orderBy() — DO NOT rename it
- If you see fromJson(), toJson(), fromMap(), toMap(), fromFirestore(), or toFirestore() methods — DO NOT rename the string keys inside them
- If you see a model class with fields that clearly match Firestore document fields — DO NOT rename those fields

### Firebase Auth rules:
- If you see any reference to Firebase Auth properties — DO NOT rename them
- Protected property names: uid, email, displayName, photoURL, emailVerified, phoneNumber, isAnonymous
- DO NOT rename any variable that holds a FirebaseUser or User object property

### Supabase Storage rules:
- Supabase is used for FILE STORAGE in this project (not Firebase Storage)
- If you see any Supabase storage call — supabase.storage, from(), upload(), download(), getPublicUrl() — DO NOT rename the bucket names or file path strings
- If you see response parsing from Supabase storage — DO NOT rename the keys being parsed

### Supabase Edge Function rules:
- If you see any HTTP call to a Supabase edge function URL — DO NOT rename the payload keys being sent
- If you see response parsing from a Supabase edge function — DO NOT rename the keys being parsed

### General rule:
- Only rename purely local/UI variables that have NO connection to Firebase or Supabase
- When in doubt — DO NOT rename. Leave it as-is and add a // REVIEW: comment

---

## 5. ICON PACKAGE RULES

The project is consolidating to ONE icon package only.

Approved package: material_design_icons_flutter
Import to use: import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
Icon prefix: MdiIcons.iconName

What to do:
- Find every usage of Iconsax, CupertinoIcons, FontAwesomeIcons, or any other icon package
- Replace each icon with the closest equivalent from MdiIcons
- Remove all unused icon package imports after replacing
- Do NOT remove material_design_icons_flutter from pubspec.yaml
- If you cannot find a reasonable MdiIcons equivalent, leave a comment: // TODO: find MdiIcons equivalent for [originalIcon]

---

## 6. DESIGN SYSTEM — FILES TO CREATE

Create all of these in lib/core/theme/ before touching any screen or widget file.
These files must be created FIRST in Phase 1.

### lib/core/theme/app_colors.dart
- Extract every hardcoded Color(0xFF...) or Colors.xyz found in the codebase
- Create named static constants for each
- Example:
  static const Color primary = Color(0xFF...);
  static const Color backgroundPrimary = Color(0xFF...);
- After creating this file, replace all hardcoded colors in lib/ with AppColors.xyz

### lib/core/theme/app_text_styles.dart
- Extract every repeated TextStyle(...) pattern found in the codebase
- Create named static TextStyle constants
- Example:
  static const TextStyle heading1 = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  static const TextStyle bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
- After creating, replace all repeated TextStyle usage with AppTextStyles.xyz

### lib/core/theme/app_spacing.dart
- Extract repeated EdgeInsets, SizedBox heights/widths, and padding values
- Create named constants
- Example:
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const EdgeInsets paddingMd = EdgeInsets.all(16.0);
- After creating, replace hardcoded spacing with AppSpacing.xyz

### lib/core/theme/app_borders.dart
- Extract repeated BorderRadius patterns
- Example:
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(8));

### lib/core/theme/app_decorations.dart
- Extract repeated BoxDecoration patterns used across multiple widgets
- Example:
  static BoxDecoration cardDecoration = BoxDecoration(
    borderRadius: AppBorders.cardRadius,
    color: AppColors.surface,
  );

### lib/core/theme/app_text_field_styles.dart
- Extract repeated InputDecoration patterns
- Create reusable InputDecoration objects

---

## 7. WIDGET EXTRACTION RULES

When you find a widget class or build() section that is:
- Copied or nearly identical across 2 or more files
- A self-contained UI piece (card, button, tile, avatar, badge, etc.)

Do this:
- Extract it into lib/widgets/shared/widget_name.dart
- Make it reusable with parameters for the parts that change
- Replace all usages across the codebase with the new shared widget
- Keep the original file but now call the extracted widget instead
- Do NOT change the visual output — it must look identical

Naming convention for extracted widgets:
- File name: snake_case — example: merchant_card.dart
- Class name: PascalCase — example: MerchantCard

---

## 8. BLOC RULES

- Do NOT change BLoC event names
- Do NOT change BLoC state names
- Do NOT change BLoC class names
- You may improve the internal implementation for memory efficiency
- You may extract repeated logic into private methods within the same BLoC file
- You may add proper dispose() calls if streams or controllers are not being disposed
- Do NOT split a BLoC into multiple BLoCs — keep existing structure

---

## 9. DOCUMENTATION RULES

For every folder you refactor, create one markdown documentation file inside that folder.

File naming: use the folder name + .md
Example: lib/bloc/auth/ → create lib/bloc/auth/auth_bloc.md

Each documentation file must contain:
- Overview: what this folder/module is responsible for
- Files: list every file in the folder and one sentence about what it does
- Usage: how to use this module from other parts of the app (with example if relevant)
- Dependencies: what other modules or packages this depends on
- Notes: any important warnings or things a new developer should know

For BLoC folders also include:
- Events: list all events with description
- States: list all states with description

---

## 10. COMMENTING RULES

Remove:
- Commented-out code blocks (dead code)
- Obvious comments that restate what the code already says
  Example: // increment counter  counter++;
- TODO comments that are already done
- Auto-generated comments that add no value

Keep or add:
- Comments explaining WHY something is done a non-obvious way
- Comments on complex business logic
- Comments on Firestore query structure if it is not self-explanatory
- Comments on Supabase edge function calls explaining what the function does
- Dart doc comments (///) on all public classes, methods, and properties

Format for public members:
/// Brief description of what this does.
/// 
/// [paramName] - what this parameter represents
/// Returns [type] representing what
class MyClass { ... }

---

## 11. MEMORY EFFICIENCY RULES

Look for and fix:
- StreamSubscription variables that are never cancelled — add dispose()
- AnimationController instances without dispose()
- Large lists loaded all at once when pagination would work better — flag with a TODO comment, do not auto-fix pagination without asking
- Repeated identical object creation inside build() methods — move to initState() or outside the method
- const constructors missing on widgets that could be const — add const
- setState() called unnecessarily — flag but do not auto-fix BLoC-connected widgets
- Images loaded without cacheWidth or cacheHeight — add where missing

---

## 12. CODE QUALITY RULES

Apply these across all Dart files in lib/:
- Add const wherever possible on widget constructors
- Use final for variables that are never reassigned
- Remove unused imports
- Remove unused variables
- Use null-safe patterns properly — avoid ! where a safer null check is possible
- Extract long build() methods into smaller private methods within the same widget class
  (Do NOT extract into separate files unless the widget is reusable — see Section 7)
- Use named constructors for model classes where it improves clarity
- Ensure all async methods have proper error handling (try/catch or .catchError)

---

## 13. PHASE ORDER — DO NOT SKIP AHEAD

Work in this exact order. Stop after each phase and wait for approval.

Phase 1 — lib/core/theme/
  Create all design system files (app_colors, app_text_styles, app_spacing, app_borders, app_decorations)
  Then do a global find-and-replace across lib/ to use these new classes
  Document in lib/core/theme/theme.md

Phase 2 — lib/bloc/
  Refactor each BLoC subfolder one at a time
  Fix memory/dispose issues
  Add documentation .md files per subfolder

Phase 3 — lib/widgets/
  Extract all reusable widgets
  Organise into lib/widgets/shared/
  Document in lib/widgets/widgets.md

Phase 4 — lib/screens/
  Update all screens to use shared widgets and design system classes
  Document each screen subfolder

Phase 5 — lib/services/
  Clean up Firebase service classes:
    - Firestore service classes
    - Firebase Auth service classes
  Clean up Supabase service classes:
    - Supabase Storage service classes
    - Supabase edge function caller classes
  Add error handling where missing
  Document each service

Phase 6 — supabase/
  Clean up Deno edge function files
  Add documentation per function
  Do NOT change any function endpoint URLs, bucket names, or payload structures

---

## 14. COMMIT MESSAGE FORMAT

Use this format for every commit:
refactor(scope): short description

Examples:
refactor(theme): create AppColors and replace hardcoded colors
refactor(auth-bloc): add dispose for stream subscriptions
refactor(widgets): extract MerchantCard to shared widgets
docs(auth-bloc): add auth_bloc.md documentation

---

## 15. IF YOU ARE UNSURE

If you are unsure whether something is safe to change — DO NOT change it.
Leave a comment in the code: // REVIEW: [describe what you are unsure about]
And add it to a file called REVIEW_NEEDED.md in the project root.

Your job is to make the code cleaner, more readable, and more memory efficient.
Your job is NOT to redesign the architecture or change how the app works.

When in doubt — leave it and flag it.
