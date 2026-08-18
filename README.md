# Segue Frontend

Flutter frontend for the MCM Last Intent hackathon project.

This project is set up for Android, iOS, and Web from the first setup issue.
For the hackathon, production-style deployment is expected to use Web, while Android/iOS runners remain available for app demos.

## Requirements

- Flutter stable 3.38.x
- Dart 3.10.x
- Chrome or Edge for Web runs
- Android Studio or Android SDK for Android runs
- Xcode and CocoaPods on macOS for iOS runs

## Local Run

Install dependencies first.

```powershell
flutter pub get
```

Run Web.

```powershell
flutter run -d chrome --web-port 5173 --dart-define=API_BASE_URL=http://localhost:8080 --dart-define=APP_ENV=local
```

Run Android.

```powershell
flutter devices
flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://localhost:8080 --dart-define=APP_ENV=local
```

Run iOS on macOS.

```bash
flutter devices
flutter run -d <ios-device-id> --dart-define=API_BASE_URL=http://localhost:8080 --dart-define=APP_ENV=local
```

### Running against the real backend

The commands above default to `USE_MOCK_DATA=true` (see [Environment
Values](#environment-values)), so they run against `MockSegueRepository`
with no backend required. To exercise the real `/api/...` endpoints
instead, add `--dart-define=USE_MOCK_DATA=false` and point
`API_BASE_URL` at a running backend:

```powershell
flutter run -d chrome --web-port 5173 --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=http://localhost:8080 --dart-define=APP_ENV=local
```

`RealSegueRepository`/`HttpSegueApiClient` implement every method on
`SegueRepository` (see `lib/repositories/real_segue_repository.dart`) —
no code change is needed to switch over, only this flag. Test with the
demo accounts in [Demo Accounts](#demo-accounts) once the backend is up.

## Build

Build Web.

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com --dart-define=APP_ENV=production
```

Build Android.

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com --dart-define=APP_ENV=production
```

Build iOS on macOS.

```bash
flutter build ios --release --dart-define=API_BASE_URL=https://api.example.com --dart-define=APP_ENV=production
```

Release builds should always add `--dart-define=USE_MOCK_DATA=false`
alongside the real `API_BASE_URL` — otherwise the shipped build still
runs against `MockSegueRepository`.

## Routes

- `/` redirects to the customer mobile entry screen for now.
- `/mobile` is the customer mobile app route group.
- `/staff` is the staff web route group.

## Environment Values

Runtime configuration is read through Dart compile-time defines.

| Key | Default | Description |
| --- | --- | --- |
| `APP_ENV` | `local` | Current frontend environment name |
| `API_BASE_URL` | `http://localhost:8080` | Backend API base URL |
| `USE_MOCK_DATA` | `true` | `false` switches `RepositoryScope` to `RealSegueRepository` (real HTTP calls) instead of `MockSegueRepository` |
| `STORE_ID` | `1` | Store id sent with cart/consultation requests |

## Project Contracts

- Backend local base URL: `http://localhost:8080`
- Customer mobile app starts the flow with `POST /api/cart`.
- Staff web continues with customer lookup, consent, cart/inventory, Last Intent, execution, and status updates.
- Backend does not keep a consultation session. The frontend keeps `structuredIntent` and `/decide` response values locally and sends them to the next request.
- API integration should follow `API.md`; schema and demo scenario assumptions should follow `SCHEMA.md`.
- Final API integration should happen after the mock UI flow is complete.

## Demo Accounts

| Name | Phone | Purpose |
| --- | --- | --- |
| 김세계 | `010-1234-5678` | Consent already completed, main happy-path demo |
| 이수현 | `010-9876-5432` | No consent record, 403 consent-required demo |

## UI Foundation

- Design tokens live in `lib/utils/app_design_tokens.dart`.
- The shared Material theme lives in `lib/utils/app_theme.dart`.
- Common loading, empty, error, retry, and success states use `lib/widgets/app_state_view.dart`.
- Route-level screens should use tokens and theme values instead of ad hoc colors, spacing, or radii.

## Data & State Foundation

- API DTOs live in `lib/models` and keep `productId` and `skuId` separate.
- Cart save requests use `customerId`, `productId`, `color`, and `size`; the backend resolves `skuId`.
- Inventory UI models expose only API booleans. Reliability fields such as `confirmed` and `checked_at` stay backend decision-engine inputs.
- Repository contracts live in `lib/repositories`; `MockSegueRepository` supports screen work before final API integration.
- `RepositoryScope` switches between mock and real repositories with `--dart-define=USE_MOCK_DATA=false`.
- Session state lives in `lib/providers`, so screens consume controllers instead of HTTP details.

## Folder Structure

- `android`: Android runner project
- `ios`: iOS runner project
- `web`: Web runner project
- `lib/exceptions`: shared exception and error models
- `lib/models`: shared API and screen data models
- `lib/providers`: screen and session state
- `lib/repositories`: mock and real data adapters
- `lib/screens`: route-level screens
- `lib/utils`: formatters, validators, and pure helpers
- `lib/widgets`: reusable UI components

New feature files should follow this structure so customer mobile app, staff web, and final API integration work can grow without mixing responsibilities.
