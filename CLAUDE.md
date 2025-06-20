# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application project named "meeting". It's currently a basic Flutter starter template with a counter demo app.

## Development Commands

### Running the Application
```bash
# Run the app in debug mode
flutter run

# Run on a specific device (list devices first)
flutter devices
flutter run -d <device_id>

# Run in release mode
flutter run --release

# Run on web
flutter run -d chrome

# Run on iOS simulator
flutter run -d iphone

# Run on Android emulator  
flutter run -d android
```

### Building the Application
```bash
# Build APK for Android
flutter build apk

# Build app bundle for Android (recommended for Play Store)
flutter build appbundle

# Build for iOS (requires macOS with Xcode)
flutter build ios

# Build for web
flutter build web

# Build for macOS (requires macOS)
flutter build macos

# Build for Windows (requires Windows)
flutter build windows

# Build for Linux
flutter build linux
```

### Testing and Code Quality
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run a specific test file
flutter test test/widget_test.dart

# Analyze code for issues
flutter analyze

# Format code
flutter format .

# Check formatting without making changes
flutter format --set-exit-if-changed .
```

### Dependencies and Setup
```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Clean build artifacts
flutter clean

# Recreate platform-specific folders
flutter create .
```

## Project Structure

- **lib/**: Main application code
  - `main.dart`: Entry point containing MyApp and MyHomePage widgets
- **test/**: Unit and widget tests
  - `widget_test.dart`: Basic widget test for the counter functionality
- **android/**: Android-specific configuration and native code
- **ios/**: iOS-specific configuration and native code
- **web/**: Web-specific assets and configuration
- **linux/**, **macos/**, **windows/**: Desktop platform configurations
- **pubspec.yaml**: Project dependencies and Flutter configuration
- **analysis_options.yaml**: Dart analyzer configuration with flutter_lints

## Key Configuration Details

- **Flutter SDK**: ^3.8.1 (specified in pubspec.yaml)
- **Linting**: Uses flutter_lints package for code quality
- **Material Design**: Enabled with `uses-material-design: true`

## Architecture Notes

The current codebase follows the standard Flutter starter template pattern:
- `MyApp` is a StatelessWidget that serves as the root widget
- `MyHomePage` is a StatefulWidget demonstrating basic state management
- Uses Material Design with a customizable theme
- Simple counter functionality demonstrates setState usage

When adding new features, consider:
- Following the existing widget structure pattern
- Maintaining the Material Design approach
- Adding corresponding tests in the test/ directory
- Using the established state management pattern (setState for simple cases)