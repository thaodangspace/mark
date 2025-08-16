import Foundation
import CoreMedia
import SwiftUI
import AVFoundation

// MARK: - Recording Status Model

enum RecordingStatus {
    case ready
    case starting
    case recording
    case paused
    case stopping
    case completed
    case error
    
    var displayText: String {
        switch self {
        case .ready: return "Ready"
        case .starting: return "Starting..."
        case .recording: return "Recording"
        case .paused: return "Paused"
        case .stopping: return "Stopping..."
        case .completed: return "Completed"
        case .error: return "Error"
        }
    }
    
    init(from status: String) {
        switch status.lowercased() {
        case "ready": self = .ready
        case "starting", "starting...": self = .starting
        case "recording": self = .recording
        case "paused": self = .paused
        case "stopping", "stopping...": self = .stopping
        case "completed": self = .completed
        default: self = .ready
        }
    }
}

// MARK: - Capture Area Model

enum CaptureAreaType: String, CaseIterable, Hashable {
    case fullScreen = "Full Screen"
    case selectWindow = "Select Window"
    case customRegion = "Custom Region"
    
    var displayName: String {
        return rawValue
    }
}

// MARK: - Recording File Model

struct RecordingFile: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let size: Int64
    let creationDate: Date
    
    var name: String {
        return url.lastPathComponent
    }
    
    var formattedSize: String {
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    static func == (lhs: RecordingFile, rhs: RecordingFile) -> Bool {
        return lhs.url == rhs.url
    }
}

// MARK: - Recording Information Model

struct RecordingInfo {
    let duration: CMTime
    let resolution: CGSize
    let frameRate: Float
    let fileSize: Int64
    
    var formattedDuration: String {
        let seconds = CMTimeGetSeconds(duration)
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    var formattedResolution: String {
        return "\(Int(resolution.width)) × \(Int(resolution.height))"
    }
    
    var formattedFileSize: String {
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

// MARK: - Screen Recorder Errors

enum MarkError: Error, LocalizedError {
    case alreadyRecording
    case notRecording
    case permissionDenied
    case configurationError
    case captureFailed
    case encodingFailed
    case fileSystemError
    
    var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "Recording is already in progress"
        case .notRecording:
            return "No recording session is active"
        case .permissionDenied:
            return "Screen recording permission is required"
        case .configurationError:
            return "Failed to configure recording settings"
        case .captureFailed:
            return "Screen capture failed"
        case .encodingFailed:
            return "Video encoding failed"
        case .fileSystemError:
            return "File system operation failed"
        }
    }
}

// MARK: - Permissions Model

struct PermissionStatus {
    let screenRecording: Bool
    let microphone: Bool
    
    var allGranted: Bool {
        return screenRecording && microphone
    }
    
    init(screenRecording: Bool, microphone: Bool) {
        self.screenRecording = screenRecording
        self.microphone = microphone
    }
    
    init(screenRecording: Bool, microphoneStatus: AVAuthorizationStatus) {
        self.screenRecording = screenRecording
        self.microphone = microphoneStatus == .authorized
    }
}

// MARK: - Settings Model

enum VideoFormat: String, CaseIterable, Hashable {
    case mov = "mov"
    case mp4 = "mp4"
    
    var displayName: String {
        switch self {
        case .mov: return "MOV"
        case .mp4: return "MP4"
        }
    }
    
    var fileExtension: String {
        return rawValue
    }
}

enum VideoQuality: String, CaseIterable, Hashable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case lossless = "lossless"
    
    var displayName: String {
        switch self {
        case .low: return "Low (720p)"
        case .medium: return "Medium (1080p)"
        case .high: return "High (1440p)"
        case .lossless: return "Lossless"
        }
    }
}

@MainActor
class AppSettings: ObservableObject {
    @Published var defaultSaveFolder: URL
    @Published var videoFormat: VideoFormat = .mov
    @Published var videoQuality: VideoQuality = .high
    @Published var includeAudio: Bool = true
    @Published var showMouseCursor: Bool = true
    @Published var framerate: Int = 60
    @Published var autoOpenFolder: Bool = false
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        // Set default save folder to Movies directory
        let moviesURL = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first
        self.defaultSaveFolder = moviesURL?.appendingPathComponent("Mark Recordings") ?? FileManager.default.homeDirectoryForCurrentUser
        
        loadSettings()
    }
    
    private func loadSettings() {
        // Load saved settings from UserDefaults
        if let folderData = userDefaults.data(forKey: "defaultSaveFolder"),
           let url = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSURL.self, from: folderData) as URL? {
            defaultSaveFolder = url
        }
        
        if let formatString = userDefaults.object(forKey: "videoFormat") as? String,
           let format = VideoFormat(rawValue: formatString) {
            videoFormat = format
        }
        
        if let qualityString = userDefaults.object(forKey: "videoQuality") as? String,
           let quality = VideoQuality(rawValue: qualityString) {
            videoQuality = quality
        }
        
        includeAudio = userDefaults.object(forKey: "includeAudio") as? Bool ?? true
        showMouseCursor = userDefaults.object(forKey: "showMouseCursor") as? Bool ?? true
        framerate = userDefaults.object(forKey: "framerate") as? Int ?? 60
        autoOpenFolder = userDefaults.object(forKey: "autoOpenFolder") as? Bool ?? false
    }
    
    func saveSettings() {
        // Save settings to UserDefaults
        if let folderData = try? NSKeyedArchiver.archivedData(withRootObject: defaultSaveFolder, requiringSecureCoding: true) {
            userDefaults.set(folderData, forKey: "defaultSaveFolder")
        }
        
        userDefaults.set(videoFormat.rawValue, forKey: "videoFormat")
        userDefaults.set(videoQuality.rawValue, forKey: "videoQuality")
        userDefaults.set(includeAudio, forKey: "includeAudio")
        userDefaults.set(showMouseCursor, forKey: "showMouseCursor")
        userDefaults.set(framerate, forKey: "framerate")
        userDefaults.set(autoOpenFolder, forKey: "autoOpenFolder")
    }
    
    func selectFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.directoryURL = defaultSaveFolder
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                defaultSaveFolder = url
                saveSettings()
            }
        }
    }
}
