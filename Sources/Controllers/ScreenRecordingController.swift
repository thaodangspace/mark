import Foundation
import SwiftUI
import ScreenCaptureKit
import Combine

/// Controller layer that mediates between the View and Model layers
/// Handles all business logic and user interactions
@MainActor
class ScreenRecordingController: ObservableObject {
    // MARK: - Published Properties for View Binding
    @Published var isRecording = false
    @Published var recordingStatus: RecordingStatus = .ready
    @Published var selectedCaptureArea: CaptureAreaType = .fullScreen
    @Published var isPaused = false
    @Published var recordings: [RecordingFile] = []
    
    // MARK: - Alert States
    @Published var showingPermissionAlert = false
    @Published var showingErrorAlert = false
    @Published var showingCompletedAlert = false
    @Published var showingRecordingsManager = false
    @Published var alertMessage = ""
    
    // MARK: - Models and Managers
    private let screenRecorder: Mark
    private let permissionsManager: PermissionsManager
    private let fileManager: RecordingFileManager
    @StateObject private var settings = AppSettings()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var recordingStatusText: String {
        recordingStatus.displayText
    }
    
    var recordingStatusColor: Color {
        switch recordingStatus {
        case .ready, .completed:
            return .green
        case .starting, .stopping:
            return .orange
        case .recording:
            return .red
        case .paused:
            return .yellow
        case .error:
            return .red
        }
    }
    
    var startButtonTitle: String {
        isRecording ? "Recording..." : "Start Recording"
    }
    
    var pauseButtonTitle: String {
        isPaused ? "Resume" : "Pause"
    }
    
    // MARK: - Initialization
    init(
        screenRecorder: Mark = Mark(),
        permissionsManager: PermissionsManager = .shared,
        fileManager: RecordingFileManager = .shared
    ) {
        self.screenRecorder = screenRecorder
        self.permissionsManager = permissionsManager
        self.fileManager = fileManager
        
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind model changes to controller state
        screenRecorder.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.isRecording = value
            }
            .store(in: &cancellables)
        
        screenRecorder.$recordingStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.recordingStatus = RecordingStatus(from: status)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Interface for Views
    
    /// Called when the app appears to check permissions
    func onAppear() {
        Task {
            await checkPermissions()
            await loadRecordings()
        }
    }
    
    /// Handles start recording action
    func startRecording() {
        Task {
            do {
                try await screenRecorder.startRecording()
                recordingStatus = .recording
            } catch {
                await handleError(error)
            }
        }
    }
    
    /// Handles stop recording action
    func stopRecording() {
        Task {
            do {
                try await screenRecorder.stopRecording()
                recordingStatus = .completed
                showingCompletedAlert = true
                await loadRecordings()
            } catch {
                await handleError(error)
            }
        }
    }
    
    /// Handles pause/resume recording action
    func togglePauseRecording() {
        if isPaused {
            screenRecorder.resumeRecording()
            recordingStatus = .recording
            isPaused = false
        } else {
            screenRecorder.pauseRecording()
            recordingStatus = .paused
            isPaused = true
        }
    }
    
    /// Handles capture area selection change
    func selectCaptureArea(_ areaType: CaptureAreaType) {
        selectedCaptureArea = areaType
        
        switch areaType {
        case .selectWindow:
            alertMessage = "Window selection will be implemented in the next version."
            showingErrorAlert = true
        case .customRegion:
            alertMessage = "Custom region selection will be implemented in the next version."
            showingErrorAlert = true
        case .fullScreen:
            // Full screen is supported
            break
        }
    }
    
    /// Shows the recordings manager
    func showRecordingsManager() {
        Task {
            await loadRecordings()
            showingRecordingsManager = true
        }
    }
    
    /// Opens the recordings folder in Finder
    func openRecordingsFolder() {
        fileManager.openRecordingsFolder()
    }
    
    /// Gets the current app settings
    var appSettings: AppSettings {
        return settings
    }
    
    /// Deletes a recording file
    func deleteRecording(_ recording: RecordingFile) {
        Task {
            do {
                try fileManager.deleteRecording(at: recording.url)
                await loadRecordings()
            } catch {
                await handleError(error)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func checkPermissions() async {
        let permissions = await permissionsManager.requestAllPermissions()
        
        if !permissions.screenRecording {
            showingPermissionAlert = true
        }
    }
    
    private func loadRecordings() async {
        recordings = fileManager.getAllRecordings()
    }
    
    private func handleError(_ error: Error) async {
        alertMessage = error.localizedDescription
        showingErrorAlert = true
        recordingStatus = .error
    }
}


