# Korra Design System & UI/UX Specifications

Welcome to the Korra Design System. This document outlines the design tokens, visual guidelines, typography, and component specifications that define the user interface and user experience of both the **Customer** and **Merchant** apps. 

Use this file to understand the styling parameters and maintain complete visual consistency across all feature additions, platforms (Android, iOS, Web), and refactoring tasks.

---

## 1. Brand Identity & Creative Direction
Korra is a premium fintech platform designed to feel **clean, secure, trustworthy, and modern**. 
* **Design Philosophy**: Minimalist structure combined with premium details (soft borders, rounded corners, subtle shadows, and crisp typography).
* **Cross-Flavor Parity**: Both the Merchant and Customer apps share the same design language, layout grids, spacing scales, and typography. The differentiator is semantic styling and feature scoping.

---

## 2. Core Color Palette Tokens
All colors are defined under the centralized [KorraColors](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/config/constants/colors.dart) class.

| Token | Hex Value | Semantic / Usage |
| :--- | :--- | :--- |
| **Brand Primary** | `#FFA54600` | Earthy Orange / Rust. Hero buttons, interactive accents, brand focus. |
| **Brand Dark** | `#DT7A3300` | Pressed / Active states for brand buttons. |
| **Brand Light** | `#FFF2EB` | Light tint background for warnings, badges, and alerts. |
| **Surface** | `#FFF9FAFB` | Primary light surface color (default background for cards and screens). |
| **Warm Surface** | `#FFFAF7F4` | Brand-tinted warm background. |
| **Pure Black** | `#000000` | Used for overlay math and precise elevation drop shadows. |
| **Text Dark** | `#FF101828` | Near-black headings and title texts (high contrast). |
| **Text Mid** | `#FF667085` | Medium grey for body copy and general description texts. |
| **Text Secondary**| `#FF8E8E93` | iOS-style grey for caption metadata. |
| **Text Hint** | `#FF98A2B3` | Input text placeholder / hint colors. |
| **Border Default** | `#FFE0E0E0` | Standard divider and card outline color. |
| **Border Light** | `#FFEAECF0` | Very light border for table lines and list dividers. |
| **Success** | `#FF1DB954` | Primary success color. |
| **Success Fg** | `#FF027A48` | Dark green text for paid status tags and credit notifications. |
| **Success Bg** | `#FFECFDF5` | Light green background for positive action badges. |
| **Settle Green** | `#FF059669` | Mid-green accent for paid invoices and settlements. |
| **Warning Fg** | `#FFB95000` | Amber/Orange text for pending or flagged warning messages. |
| **Error Fg** | `#FFB42318` | Destructive actions, delete account buttons, and error sheets. |
| **Error Bg** | `#FFFEF3F2` | Light red background for failure alert panels. |

---

## 3. Typography Tokens
Korra uses **Inter** (via Google Fonts) as its primary typeface. All text styles utilize responsive scaling (`.sp`) in widgets via ScreenUtil. Detailed constants are defined in [KorraTextStyles](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/config/constants/text_styles.dart).

### Font Weight Scale
* `w400` (Regular)
* `w500` (Medium)
* `w600` (SemiBold)
* `w700` (Bold)
* `w800` (ExtraBold)
* `w900` (Black)

### Typography Hierarchy

| Style Name | Size (SP) | Weight | Line Height | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **displayLg** | `34.0` | `w800` | `1.2` (Tabular) | Vault balances, high-priority transaction hero values. |
| **displayMd** | `32.0` | `w800` | `1.2` (Tabular) | Secondary hero financial balances. |
| **displayBalance**| `32.0` | `w900` | `1.2` | Total store balance counters. |
| **headingXl** | `24.0` | `w800` | `1.0` | KPI card statistics and analytics graphs header. |
| **headingMd** | `20.0` | `w700` | `1.2` | Page app bar titles and bottom sheet headers. |
| **headingSm** | `18.0` | `w700` | `1.2` | Main page dashboard section headers. |
| **titleLg** | `16.0` | `w700` | `Normal` | Card titles and list tile headers. |
| **bodyLarge** | `16.0` | `w400` | `Normal` | Standard button labels and readable descriptive text. |
| **bodyMedium** | `14.0` | `w400` | `Normal` | Primary body copy, inputs text, settings labels. |
| **caption** | `12.0` | `w400` | `Normal` | Secondary details, metadata descriptions, and subtitles. |
| **micro** | `10.0` | `w500` | `Normal` | Small tag text, badge numbers, and indicators. |

---

## 4. Spacing & Grid Layout
Korra maintains a consistent mathematical layout grid for padding, spacing, and alignment. Spacing scale is documented in [KorraSizes](file:///c:/Users/USER/Desktop/flutter_projects/korra/lib/config/constants/sizes.dart).

* **Page Gutter**: `20.0` horizontal margin (use `16.0` for tighter, nested grids).
* **Vertical/Horizontal Spacings**: Use a base-4 grid scale (`4.0`, `8.0`, `12.0`, `16.0`, `20.0`, `24.0`, `32.0`, `40.0`, `48.0`, `56.0`).
* **Component Heights**:
  * **Primary Buttons**: `54.0`
  * **Compact Buttons**: `36.0`
  * **Text Inputs**: `52.0`
  * **Filter Chips**: `32.0`
  * **Bottom Navigation Bar**: `72.0`

---

## 5. Shape Corners & Border Radius
Standardized corners provide a soft, modern aesthetic across all platforms.

* ** xs (4.0)**: Tiny badges, status pills.
* ** sm (8.0)**: Chips, small transaction tags.
* ** chipRadius (10.0)**: Filter chips.
* ** fieldRadius (12.0)**: Text input boxes, dropdown selectors.
* ** cardRadius (16.0)**: Main containers, dashboards, action cards, image boxes.
* ** sheetRadius (24.0)**: Bottom sheets, fullscreen dialog popups.
* ** pillRadius (999.0)**: Fully rounded CTA buttons and active indicator tags.

---

## 6. Standardized UI Components

### App Header (`KorraHeader`)
* **Background**: Always solid `#FFFFFF` (White) to support clean interfaces.
* **Left Icon**: Custom back arrow (`Iconsax.arrow_left`, size `24.0`) that natively dismisses the current route (`Navigator.pop(context)`).
* **Elevation**: Border-bottom with very light `#F2F4F7` divider (no drop shadow).

### Text Input Fields
* **Container**: Light background fill `#F9F9F9`.
* **Border**: Outline border with radius `12.0` (`fieldRadius`). Border color is `#E0E0E0` in unfocused state, `#A54600` (Brand Primary) in focused state.
* **Typo**: Input text is `Inter` size `14.0`, Hint text is `#98A2B3`.

### Action Bottom Sheets
* **Structure**: Top rounded card with radius `24.0` (`sheetRadius`).
* **Header**: Centered horizontal handle bar (`40.0` width, `4.0` height, color `#E0E0E0`), followed by a Bold title at `20.sp` weight.
* **Actions**: Vertically stacked primary and secondary buttons, separated by consistent `16.0` gaps.

### Segmented Tabs
* **Outer Container**: Rounded container with radius `14.0` (`segmentRadius`) in `#F2F4F7`.
* **Active Tab Indicator**: White card shape with soft shadow and `12.0` radius.
* **Text**: Toggles between brand colors when active and muted grey when inactive.

---

## 7. Interactive Feedback & Micro-animations
To keep the app alive and highly interactive, always implement:
* **Haptics**: Apply `HapticFeedback.lightImpact()` on all buttons, headers, back buttons, and input tab activations.
* **Feedback Sheets**: Error and warning dialogs should trigger a subtle haptic vibration upon presentation.
* **Hover and Tap States**: Ensure buttons utilize standard ink-splashes (`InkWell` or `ElevatedButton`) with correct borders and colors matching the brand identity.
