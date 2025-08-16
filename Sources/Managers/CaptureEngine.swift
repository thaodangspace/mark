import Foundation
import ScreenCaptureKit
import AVFoundation
import CoreMedia

class CaptureEngine: NSObject, SCStreamDelegate, SCStreamOutput {
    private var stream: SCStream?
    private var contentFilter: SCContentFilter?
    private var streamConfiguration: SCStreamConfiguration?
    
    private var isCapturing = false
    private var isPaused = false
    
    weak var delegate: CaptureEngineDelegate?
    
    override init() {
        super.init()
        setupConfiguration()
    }
    
    private func setupConfiguration() {
        streamConfiguration = SCStreamConfiguration()
        streamConfiguration?.width = 1920
        streamConfiguration?.height = 1080
        streamConfiguration?.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        streamConfiguration?.queueDepth = 8
        streamConfiguration?.showsCursor = true
        streamConfiguration?.capturesAudio = true
        streamConfiguration?.excludesCurrentProcessAudio = true
        streamConfiguration?.pixelFormat = kCVPixelFormatType_32BGRA
        streamConfiguration?.scalesToFit = false
        
        if #available(macOS 14.0, *) {
            streamConfiguration?.presenterOverlayPrivacyAlertSetting = .never
        }
    }
    
    func startCapture() async throws {
        guard !isCapturing else { return }
        
        let availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        
        guard let display = availableContent.displays.first else {
            throw CaptureEngineError.noDisplaysAvailable
        }
        
        contentFilter = SCContentFilter(display: display, excludingWindows: [])
        
        guard let filter = contentFilter, let config = streamConfiguration else {
            throw CaptureEngineError.configurationError
        }
        
        stream = SCStream(filter: filter, configuration: config, delegate: self)
        
        try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: DispatchQueue(label: "ScreenCaptureQueue", qos: .userInteractive))
        try stream?.addStreamOutput(self, type: .audio, sampleHandlerQueue: DispatchQueue(label: "AudioCaptureQueue", qos: .userInteractive))
        
        try await stream?.startCapture()
        isCapturing = true
    }
    
    func stopCapture() {
        guard isCapturing else { return }
        
        Task {
            try? await stream?.stopCapture()
            stream = nil
            isCapturing = false
            isPaused = false
        }
    }
    
    func pauseCapture() {
        isPaused = true
    }
    
    func resumeCapture() {
        isPaused = false
    }
    
    func updateCaptureArea(to captureArea: CaptureArea) async throws {
        guard let config = streamConfiguration else { return }
        
        switch captureArea {
        case .fullScreen:
            let availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = availableContent.displays.first else { return }
            contentFilter = SCContentFilter(display: display, excludingWindows: [])
            
        case .window(let windowID):
            let availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let window = availableContent.windows.first(where: { $0.windowID == windowID }) else { return }
            contentFilter = SCContentFilter(desktopIndependentWindow: window)
            
        case .customRegion(let rect):
            config.sourceRect = rect
        }
        
        if let filter = contentFilter {
            try await stream?.updateContentFilter(filter)
        }
        try await stream?.updateConfiguration(config)
    }
    
    // MARK: - SCStreamDelegate
    
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("Stream stopped with error: \(error)")
        delegate?.captureEngine(self, didFailWithError: error)
    }
    
    // MARK: - SCStreamOutput
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard !isPaused else { return }
        
        switch type {
        case .screen:
            delegate?.captureEngine(self, didCaptureVideoSampleBuffer: sampleBuffer)
        case .audio:
            delegate?.captureEngine(self, didCaptureAudioSampleBuffer: sampleBuffer)
        case .microphone:
            delegate?.captureEngine(self, didCaptureAudioSampleBuffer: sampleBuffer)
        @unknown default:
            break
        }
    }
}

// MARK: - Supporting Types

enum CaptureArea {
    case fullScreen
    case window(windowID: CGWindowID)
    case customRegion(rect: CGRect)
}

enum CaptureEngineError: Error {
    case noDisplaysAvailable
    case configurationError
    case permissionDenied
    case captureSessionError
}

protocol CaptureEngineDelegate: AnyObject {
    func captureEngine(_ engine: CaptureEngine, didCaptureVideoSampleBuffer sampleBuffer: CMSampleBuffer)
    func captureEngine(_ engine: CaptureEngine, didCaptureAudioSampleBuffer sampleBuffer: CMSampleBuffer)
    func captureEngine(_ engine: CaptureEngine, didFailWithError error: Error)
}