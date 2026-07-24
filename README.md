# Glean Faith App

> Bible Quiz App — leaderboard, audio, blogs, PDF, videos, articles

[![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter)](https://flutter.dev)
[![Maestro](https://img.shields.io/badge/Maestro-Tested-6C5CE7?logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBkPSJNMTIgMkM2LjQ4IDIgMiA2LjQ4IDIgMTJzNC40OCAxMCAxMCAxMCAxMC00LjQ4IDEwLTEwUzE3LjUyIDIgMTIgMnptLTEgMTcuOTNjLTQuMjUtLjQ5LTcuNi00LjI3LTcuNi04LjkzIDAtLjQ2LjA0LS45MS4xLTEuMzVMNyAxM2wxLjUgMy41IDIuNS0xVjYuNWwxLjc1LTIuNzVjMi4zOC4zNSA0LjI1IDIuMzUgNC4yNSA0Ljc1IDAgMS4zOC0uNTYgMi42My0xLjQ2IDMuNTRsLS4yOS4yOWMtLjM5LjM5LS42My45MS0uNjMgMS40N3YyLjFjMCAxLjEtLjkgMi0yIDJ2LTMuOTJ6IiBmaWxsPSIjNkM1Q0U3Ii8+PC9zdmc+)](maestro/)

A Flutter mobile application built with **CLEAN Architecture**, **Riverpod** state management, and **fpdart** functional programming.

## Quick Start

```bash
flutter pub get
flutter run
```

## Testing

### Unit & Widget Tests

```bash
flutter test
```

### Maestro UI Tests

See [MAESTRO.md](MAESTRO.md) for full documentation.

```bash
# Prerequisites: emulator/simulator running with app installed
maestro test maestro/flows/
```

## Architecture

- **State Management:** Riverpod (StateNotifier + AsyncValue)
- **Routing:** GoRouter
- **Networking:** Dio with auth/logging/refresh interceptors
- **Storage:** flutter_secure_storage
- **Database:** ObjectBox (init)
- **Functional:** fpdart (TaskEither<Failure, T>)

## Project Structure

```
lib/
├── main.dart                     # Entry point
├── app.dart                      # MaterialApp.router
├── bootstrap.dart                # Init (logger, DB)
├── core/                         # Shared infrastructure
│   ├── theme/                    # Colors, text styles, dimensions
│   ├── error/                    # Failures, exceptions, handler
│   ├── network/                  # Dio client, interceptors
│   ├── services/                 # Logger, storage, database
│   ├── router/                   # GoRouter config
│   ├── constants/                # API, app, asset constants
│   └── common/                   # Widgets, providers, extensions
│       └── features/             # Presentation-only features
│           ├── home/             # Home tab with mock data
│           ├── quiz/             # Placeholder
│           ├── leaderboard/      # Placeholder
│           └── profile/          # Profile tab
└── features/                     # Full CLEAN feature modules
    ├── auth/                     # Auth: signin, signup, OTP, reset
    └── settings/                 # Settings: theme, notifications
```

## Key Commands

| Command | Description |
|---------|-------------|
| `flutter pub get` | Install dependencies |
| `flutter run` | Run on connected device |
| `flutter test` | Run all widget/unit tests |
| `flutter build apk --debug` | Build APK for Maestro |
| `maestro test maestro/flows/` | Run Maestro UI tests |
| `dart run build_runner build --delete-conflicting-outputs` | Code generation |
