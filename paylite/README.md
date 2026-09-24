# paylite
# PayLite

PayLite is a Flutter UPI-style payment app backed by an in-memory Node/Express mock API. It supports login, secure session restoration, biometric app locking, QR/VPA payments, payment status polling, receipts, collect requests, bill splitting, cursor-paged history, and notification deep links.

## Quick Start

Start the API:

```powershell
cd ..\backendAPIs
npm install
npm start
```

Start Flutter in another terminal:

```powershell
flutter pub get
flutter run -d chrome
```

Demo credentials:

```text
Customer ID: CUST1001
Login PIN:    1234
Payment PIN:  1234
```

## Documentation

See [docs/END_TO_END_GUIDE.md](docs/END_TO_END_GUIDE.md) for:

- Architecture and folder responsibilities
- Flutter and backend data flow
- Models and API contracts
- Session restoration and biometric locking
- QR/VPA payment flow and idempotency
- SUCCESS/PENDING/FAILED polling
- Receipts, collect requests, splitting, and history
- Notifications and deep links
- Loading/error/empty states
- Accessibility, reduced motion, testing, and known limitations

The backend API documentation is in [../backendAPIs/README.md](../backendAPIs/README.md).

## Validation

```powershell
flutter analyze
flutter test
```

The backend uses an in-memory store, so restarting it resets demo sessions, payments, and collect requests.