# CareMyCar iOS

CareMyCar iOS is a SwiftUI portfolio app for vehicle ownership, maintenance tracking, service orders, parts marketplace workflows, and agency/admin operations.

## Highlights

- SwiftUI app targeting iOS 18+
- Role-based navigation for clients and agency/admin users
- Async/await networking with a reusable API client
- Keychain-backed session persistence
- Marketplace, vehicle, maintenance, service order, admin catalog, sales, and PDF export flows
- Shared design system components for consistent UI states, rows, badges, and loading actions
- Environment-based dependency injection through `AppDependencies`

## Architecture

The codebase is organized by feature with shared core modules:

- `App`: app entry point, root session routing, splash state
- `Core/Networking`: API client and backend error mapping
- `Core/Security`: Keychain token storage
- `Core/Session`: session restoration and sign-out state
- `Core/DesignSystem`: semantic colors, spacing, reusable rows and state views
- `Core/DI`: dependency container exposed through SwiftUI environment
- `Core/Presentation`: shared UI state models
- `Features`: auth, home, vehicles, maintenance, service orders, marketplace, admin and tools
- `Models`: API DTOs and app-facing models

See [docs/ios-portfolio-improvement-plan.md](docs/ios-portfolio-improvement-plan.md) for the professional improvement roadmap.

## Requirements

- Xcode 26.5 or newer
- iOS 18.0 or newer
- Swift 5

## Build

Open `CareMyCariOS.xcodeproj` in Xcode and run the `CareMyCariOS` scheme.

Command-line build:

```sh
xcodebuild -project CareMyCariOS.xcodeproj \
  -scheme CareMyCariOS \
  -configuration Debug \
  -destination generic/platform=iOS \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Backend

The app currently points to:

```swift
https://caremycarapi-node.onrender.com/
```

The base URL is defined in `CareMyCariOS/Config/AppConfig.swift`.

## Portfolio Notes

This project is being prepared as a professional iOS portfolio sample. The current focus is maintainability, consistent UX, dependency injection, and clear evolution toward MVVM/Clean Architecture.

