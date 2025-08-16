# 📱 Screen Recorder App - MVC Architecture

## 🏗️ Project Structure

```
Sources/
├── 📁 Models/                    # Data Models & Business Logic
│   ├── Models.swift              # Core data models and enums
│   └── Mark.swift                # Main recording model
│
├── 🎮 Controllers/               # Business Logic Controllers
│   └── ScreenRecordingController.swift # Main app controller
│
├── 🎨 Views/                     # User Interface Components
│   ├── AppDelegate.swift         # App entry point
│   └── MainViewController.swift  # Main UI views and components
│
└── ⚙️ Managers/                  # Utility & Service Classes
    ├── CaptureEngine.swift       # Screen capture functionality
    ├── EncodingManager.swift     # Video encoding logic
    ├── FileManager.swift         # File operations
    └── PermissionsManager.swift  # System permissions handling
```

## 🎯 Architecture Overview

### **Models Layer** (`Sources/Models/`)

-   **Purpose**: Contains data structures, business logic, and core functionality
-   **Files**:
    -   `Models.swift`: Core data models (RecordingStatus, CaptureAreaType, RecordingFile, etc.)
    -   `Mark.swift`: Main recording model with ObservableObject conformance

### **Controllers Layer** (`Sources/Controllers/`)

-   **Purpose**: Mediates between Views and Models, handles business logic
-   **Files**:
    -   `ScreenRecordingController.swift`: Main controller managing app state and user interactions

### **Views Layer** (`Sources/Views/`)

-   **Purpose**: User interface components and presentation logic
-   **Files**:
    -   `AppDelegate.swift`: SwiftUI App entry point
    -   `MainViewController.swift`: Main content view and UI components

### **Managers Layer** (`Sources/Managers/`)

-   **Purpose**: Utility classes and service managers
-   **Files**:
    -   `CaptureEngine.swift`: Handles ScreenCaptureKit functionality
    -   `EncodingManager.swift`: Manages video encoding using AVFoundation
    -   `FileManager.swift`: File system operations for recordings
    -   `PermissionsManager.swift`: System permission requests and management

## 🔄 Data Flow

```
User Interaction → Views → Controllers → Models → Managers
                    ↑                              ↓
                    ← ← ← ← Updates ← ← ← ← ← ← ← ←
```

1. **User Action**: User interacts with Views
2. **Controller Processing**: Views call Controller methods
3. **Model Updates**: Controllers update Models
4. **Manager Operations**: Models use Managers for system operations
5. **State Updates**: Changes propagate back through binding

## 🎨 SwiftUI MVC Benefits

### ✅ **Separation of Concerns**

-   Models handle data and business logic
-   Controllers manage state and user interactions
-   Views focus purely on UI presentation
-   Managers handle system-level operations

### ✅ **Maintainability**

-   Clear folder structure makes navigation easy
-   Each component has a single responsibility
-   Easy to locate and modify specific functionality

### ✅ **Testability**

-   Each layer can be tested independently
-   Controllers can be tested without UI
-   Models can be tested without views or controllers

### ✅ **Scalability**

-   Easy to add new features without breaking existing code
-   New views can reuse existing controllers
-   New models can be added without affecting UI

## 🚀 Key Features

-   **Reactive State Management**: Uses Combine for data binding
-   **Error Handling**: Centralized error management through controllers
-   **Modular Components**: Reusable view components
-   **Type Safety**: Strong typing with custom error types and data models
-   **Modern SwiftUI**: Latest SwiftUI patterns and best practices

## 📦 Dependencies

-   **SwiftUI**: User interface framework
-   **ScreenCaptureKit**: Screen recording functionality
-   **AVFoundation**: Video encoding and media handling
-   **Combine**: Reactive programming and data binding

This architecture provides a solid foundation for maintaining and extending the screen recording application while following iOS/macOS development best practices.
