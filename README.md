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

Run Web, Android, or iOS with `API_BASE_URL` supplied through
`--dart-define` for the backend you want to target. This runs against
the **real** `/api/...` endpoints by default (see [Environment
Values](#environment-values)); no other flag is needed.

### Running against mock data instead

To develop screens without a backend, add `--dart-define=USE_MOCK_DATA=true`
to switch `RepositoryScope` to `MockSegueRepository`:

## Build

Build Web, Android, or iOS with `APP_ENV` and `API_BASE_URL` supplied
through `--dart-define` for the target environment.

## Routes

- `/` redirects to the customer mobile entry screen for now.
- `/mobile` is the customer mobile app route group.
- `/staff` is the staff web route group.

## Environment Values

Runtime configuration is read through Dart compile-time defines.

| Key | Default | Description |
| --- | --- | --- |
| `APP_ENV` | `local` | Current frontend environment name |
| `API_BASE_URL` | `` (empty) | Backend API base URL. Empty means every request is built as a same-origin relative path (`/api/...`, `/images/...`) — required for the Vercel deploy, whose `vercel.json` rewrites those paths to the real backend. Pass `--dart-define=API_BASE_URL=http://localhost:8080` (or another host) for local runs against a real backend. |
| `USE_MOCK_DATA` | `false` | `true` switches `RepositoryScope` to `MockSegueRepository` instead of the real `RealSegueRepository` (HTTP calls to `API_BASE_URL`) |
| `STORE_ID` | `1` | Store id sent with cart/consultation requests |

## Project Contracts

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
- `RepositoryScope` switches between mock and real repositories with `--dart-define=USE_MOCK_DATA=true` (real backend is the default).
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
