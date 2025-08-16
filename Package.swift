// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Mark",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Mark",
            targets: ["Mark"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Mark",
            dependencies: [],
            path: "Sources",
            sources: [
                "Models/Models.swift",
                "Models/Mark.swift",
                "Controllers/ScreenRecordingController.swift",
                "Views/AppDelegate.swift", 
                "Views/MainViewController.swift",
                "Managers/CaptureEngine.swift",
                "Managers/EncodingManager.swift",
                "Managers/FileManager.swift",
                "Managers/PermissionsManager.swift",
                "Managers/IconManager.swift"
            ]
        )
    ]
)
