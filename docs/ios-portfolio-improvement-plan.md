# CareMyCar iOS Portfolio Improvement Plan

## Current Assessment

CareMyCar is a functional SwiftUI app with clear feature slices, async networking, Keychain-backed auth, role-based navigation, PDF sharing, and practical CRUD workflows. The main gap is not functionality; it is production structure. Views currently own too much state and instantiate services directly in several areas, visual styling is repeated, and loading/empty/error states vary screen by screen.

## UI/UX Direction

Use Apple Human Interface Guidelines as the baseline: large titles for primary surfaces, grouped lists for operational flows, clear primary actions, semantic color, Dynamic Type support, and accessible labels for icon-only controls.

Recommended design language:

- Use a restrained brand palette with semantic tokens instead of hard-coded colors.
- Prefer system backgrounds, grouped lists, materials, SF Symbols, and standard controls.
- Keep forms compact and predictable; use inline validation before network calls.
- Use one consistent empty/error/loading treatment across the app.
- Add subtle `easeInOut` and spring transitions for state changes, not decorative animation.

Screens that most benefit from redesign:

- Login/Register: first impression, validation, password guidance, and better keyboard flow.
- Vehicles list/detail: main client value proposition; should look polished and scannable.
- Service order creation: can become a guided flow with quote preview and confirmation.
- Admin dashboard: should show real operational metrics instead of static shortcuts.
- Marketplace: needs filtering, stock emphasis, and purchase confirmation feedback.

## Architecture

The app now uses Clean Architecture boundaries:

- Presentation: SwiftUI feature views, UI state, navigation routes, and reusable design components.
- Domain: repository contracts and use cases.
- Data: API-backed repository implementations using `APIClient`.
- Core: design system, dependency injection, networking, security, session, and shared presentation state.

`AppDependencies` is the composition root. It wires concrete API repositories into domain use cases and exposes those use cases through SwiftUI `Environment`. Views no longer create concrete services directly.

Suggested next refactor:

1. Move screen state from large views into `@MainActor ObservableObject` view models.
2. Split DTOs from app-facing entities where model files currently contain both.
3. Create typed navigation routes per feature instead of scattered boolean sheet/navigation state.
4. Add unit tests for use cases and view models.
5. Add decoding tests for every API response model.

## App Store Readiness

Before publishing or presenting as production-grade:

- Add app icon variants, launch screen polish, privacy manifest, and localized strings.
- Validate error copy, Spanish accents, and consistent terminology.
- Add offline/network unavailable handling and retry surfaces.
- Add analytics/crash reporting hooks behind protocols.
- Add UI tests for login, vehicle creation, service request, and admin order update.
- Add accessibility checks for VoiceOver labels, minimum hit targets, and Dynamic Type.

## Implemented First Pass

- Added semantic design tokens in `AppTheme`.
- Added reusable state views for loading, empty, and error states.
- Added reusable icon/row components and loading button labels.
- Added `Domain` repository contracts and use cases.
- Added `Data` API repository implementations.
- Added `AppDependencies` and injected use cases through the SwiftUI environment.
- Removed direct service construction from SwiftUI views.
- Modernized login, register, splash, vehicle list, vehicle detail, and add-vehicle surfaces.
