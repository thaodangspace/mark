# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mark is a macOS screen recording application built with SwiftUI using Swift Package Manager. It follows an MVC architecture and uses ScreenCaptureKit for screen capture functionality.

## Build & Development Commands

### Building the Project
```bash
# Build the executable
swift build

# Build for release
swift build -c release

# Run the application
swift run
```

### Development
```bash
# Clean build artifacts
swift package clean

# Update dependencies (none currently)
swift package update

# Generate Xcode project (if needed)
swift package generate-xcodeproj
```

## Architecture Overview

The codebase follows a strict MVC pattern with clear separation of concerns:

### Models (`Sources/Models/`)
- `Models.swift`: Core data models including RecordingStatus, CaptureAreaType, RecordingFile, RecordingInfo, MarkError, and PermissionStatus
- `Mark.swift`: Main recording model with ObservableObject conformance for SwiftUI binding

### Views (`Sources/Views/`)
- `AppDelegate.swift`: SwiftUI App entry point (MarkApp)
- `MainViewController.swift`: Main content view and UI components

### Controllers (`Sources/Controllers/`)
- `ScreenRecordingController.swift`: Main controller managing app state and user interactions

### Managers (`Sources/Managers/`)
- `CaptureEngine.swift`: ScreenCaptureKit functionality
- `EncodingManager.swift`: Video encoding using AVFoundation
- `FileManager.swift`: File system operations for recordings
- `PermissionsManager.swift`: System permission requests (screen recording, microphone)

## Key Dependencies

- **SwiftUI**: UI framework
- **ScreenCaptureKit**: Screen recording (macOS 13+)
- **AVFoundation**: Video encoding and media handling
- **Combine**: Reactive programming and data binding

## Platform Requirements

- macOS 13.0+ (specified in Package.swift)
- Screen recording permissions required
- Microphone permissions for audio recording

## Data Flow

User interactions flow: Views → Controllers → Models → Managers, with state updates propagating back through SwiftUI bindings and Combine publishers.

## Error Handling

The app uses a custom `MarkError` enum for centralized error management covering recording states, permissions, capture failures, encoding issues, and file system operations.