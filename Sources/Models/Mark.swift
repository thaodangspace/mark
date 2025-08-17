import Foundation
import ScreenCaptureKit
import AVFoundation
import Combine

/// Main Model class responsible for screen recording functionality
/// Follows the Model layer responsibilities in MVC architecture
class Mark: ObservableObject {
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var recordingStatus: String = "Ready"
    @Published var captureArea: CaptureArea = .fullScreen
    
    // MARK: - Private Properties
    private var captureEngine: CaptureEngine?
    private var encodingManager: EncodingManager?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupComponents()
        setupDelegates()
    }
    
    // MARK: - Setup
    private func setupComponents() {
        captureEngine = CaptureEngine()
        encodingManager = EncodingManager()
    }
    
    private func setupDelegates() {
        // Connect the capture engine to the encoding manager
        captureEngine?.delegate = encodingManager
    }
    
    // MARK: - Public Interface
    
    /// Starts screen recording
    func startRecording() async throws {
        guard !isRecording else { 
            throw MarkError.alreadyRecording 
        }
        
        await updateStatus("Starting...")
        
        do {
            try await captureEngine?.startCapture()
            try await encodingManager?.startRecording()
            
            await MainActor.run {
                isRecording = true
                recordingStatus = "Recording"
            }
        } catch {
            await updateStatus("Ready")
            throw error
        }
    }
    
    /// Stops screen recording
    func stopRecording() async throws {
        guard isRecording else { 
            throw MarkError.notRecording 
        }
        
        await updateStatus("Stopping...")
        
        do {
            captureEngine?.stopCapture()
            try await encodingManager?.stopRecording()
            
            await MainActor.run {
                isRecording = false
                recordingStatus = "Ready"
            }
        } catch {
            await MainActor.run {
                isRecording = false
                recordingStatus = "Error"
            }
            throw error
        }
    }
    
    /// Pauses screen recording
    func pauseRecording() {
        guard isRecording else { return }
        captureEngine?.pauseCapture()
        recordingStatus = "Paused"
    }
    
    /// Resumes screen recording
    func resumeRecording() {
        guard isRecording else { return }
        captureEngine?.resumeCapture()
        recordingStatus = "Recording"
    }
    
    /// Updates the capture area for recording
    func updateCaptureArea(_ area: CaptureArea) async throws {
        captureArea = area
        try await captureEngine?.updateCaptureArea(to: area)
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func updateStatus(_ status: String) {
        recordingStatus = status
    }
}

