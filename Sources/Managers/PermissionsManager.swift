import Foundation
import ScreenCaptureKit
import AVFoundation

class PermissionsManager: NSObject, ObservableObject {
    static let shared = PermissionsManager()
    
    private override init() {
        super.init()
    }
    
    func requestScreenRecordingPermission() async -> Bool {
        let content = try? await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        return content != nil
    }
    
    func checkScreenRecordingPermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }
    
    func requestMicrophonePermission() async -> Bool {
        // For macOS, we'll use AVCaptureDevice authorization
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func checkMicrophonePermission() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .audio)
    }
    
    func requestAllPermissions() async -> PermissionStatus {
        async let screenPermission = requestScreenRecordingPermission()
        async let microphonePermission = requestMicrophonePermission()
        
        return await PermissionStatus(
            screenRecording: screenPermission,
            microphone: microphonePermission
        )
    }
    
    func openSystemPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }
}