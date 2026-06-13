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

## Architecture Target

The recommended target is MVVM with Clean Architecture boundaries:

- Presentation: SwiftUI views, view models, UI state, navigation routes.
- Domain: use cases and app entities independent from API DTOs.
- Data: API clients, repositories, DTO mapping, Keychain/session persistence.
- Core: design system, dependency injection, networking, error mapping, analytics hooks.

The first implemented step is `AppDependencies`, which centralizes service construction and exposes dependencies through SwiftUI `Environment`. This reduces coupling immediately and creates a path to mocks for previews/tests.

Suggested next refactor:

1. Define service protocols, for example `VehicleServicing`, `AuthServicing`, `OrdersServicing`.
2. Move screen state from large views into `@MainActor ObservableObject` view models.
3. Introduce repositories when API DTOs start leaking too much into UI workflows.
4. Create typed navigation routes per feature instead of scattered boolean sheet/navigation state.
5. Add unit tests for view models and decoding tests for every API response model.

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
- Added `AppDependencies` and injected it through the SwiftUI environment.
- Migrated auth, vehicle, marketplace, and key admin flows to use injected services.
- Modernized login, register, splash, vehicle list, vehicle detail, and add-vehicle surfaces.

