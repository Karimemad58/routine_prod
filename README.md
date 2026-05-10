# Routine Application

Flutter frontend for the Routine skincare and wellness platform.

## Features

- Modular architecture (`core`, `services`, `data`, `features`)
- Backend-connected dashboard, routine tracking, scan simulation, and AI chat
- Supabase anonymous auth and persistence hooks
- Local routine reminder scheduling

## Run

```bash
flutter pub get
flutter run --dart-define=BACKEND_BASE_URL=http://localhost:4000
```

Optional Supabase:

```bash
flutter run \
  --dart-define=SUPABASE_URL=YOUR_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```
