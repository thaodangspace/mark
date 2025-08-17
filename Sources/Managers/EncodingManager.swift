import Foundation
import AVFoundation
import CoreMedia

class EncodingManager: NSObject, CaptureEngineDelegate {
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    private var outputURL: URL?
    private var isRecording = false
    private var sessionStartTime: CMTime?
    
    private let videoQueue = DispatchQueue(label: "VideoEncodingQueue", qos: .userInteractive)
    private let audioQueue = DispatchQueue(label: "AudioEncodingQueue", qos: .userInteractive)
    
    override init() {
        super.init()
    }
    
    func startRecording() async throws {
        guard !isRecording else { return }
        
        outputURL = await createOutputURL()
        guard let url = outputURL else {
            throw EncodingError.invalidOutputURL
        }
        
        let fileType = await getFileType()
        assetWriter = try AVAssetWriter(outputURL: url, fileType: fileType)
        
        setupVideoInput()
        setupAudioInput()
        
        guard let writer = assetWriter else {
            throw EncodingError.writerCreationFailed
        }
        
        guard writer.startWriting() else {
            throw EncodingError.writingStartFailed
        }
        
        isRecording = true
        sessionStartTime = nil
    }
    
    func stopRecording() async throws {
        guard isRecording else { return }
        
        isRecording = false
        
        videoInput?.markAsFinished()
        audioInput?.markAsFinished()
        
        await assetWriter?.finishWriting()
        
        if let error = assetWriter?.error {
            throw error
        }
        
        cleanup()
    }
    
    private func setupVideoInput() {
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1920,
            AVVideoHeightKey: 1080,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 8_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCABAC,
                AVVideoExpectedSourceFrameRateKey: 60,
                AVVideoMaxKeyFrameIntervalKey: 60,
                AVVideoAllowFrameReorderingKey: false
            ]
        ]
        
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput?.expectsMediaDataInRealTime = true
        
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: 1920,
            kCVPixelBufferHeightKey as String: 1080
        ]
        
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput!,
            sourcePixelBufferAttributes: pixelBufferAttributes
        )
        
        if let videoInput = videoInput, assetWriter?.canAdd(videoInput) == true {
            assetWriter?.add(videoInput)
        }
    }
    
    private func setupAudioInput() {
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 128000
        ]
        
        audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioInput?.expectsMediaDataInRealTime = true
        
        if let audioInput = audioInput, assetWriter?.canAdd(audioInput) == true {
            assetWriter?.add(audioInput)
        }
    }
    
    private func createOutputURL() async -> URL? {
        return await RecordingFileManager.shared.generateOutputURLWithSettings()
    }
    
    @MainActor
    private func getFileType() -> AVFileType {
        let settings = AppSettings()
        switch settings.videoFormat {
        case .mov:
            return .mov
        case .mp4:
            return .mp4
        }
    }
    
    private func cleanup() {
        assetWriter = nil
        videoInput = nil
        audioInput = nil
        pixelBufferAdaptor = nil
        outputURL = nil
        sessionStartTime = nil
    }
    
    // MARK: - CaptureEngineDelegate
    
    func captureEngine(_ engine: CaptureEngine, didCaptureVideoSampleBuffer sampleBuffer: CMSampleBuffer) {
        guard isRecording, let videoInput = videoInput, videoInput.isReadyForMoreMediaData else { return }
        
        videoQueue.async { [weak self] in
            self?.processVideoSampleBuffer(sampleBuffer)
        }
    }
    
    func captureEngine(_ engine: CaptureEngine, didCaptureAudioSampleBuffer sampleBuffer: CMSampleBuffer) {
        guard isRecording, let audioInput = audioInput, audioInput.isReadyForMoreMediaData else { return }
        
        audioQueue.async { [weak self] in
            self?.processAudioSampleBuffer(sampleBuffer)
        }
    }
    
    func captureEngine(_ engine: CaptureEngine, didFailWithError error: Error) {
        print("Capture engine failed with error: \(error)")
        Task {
            try? await stopRecording()
        }
    }
    
    private func processVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        if sessionStartTime == nil {
            sessionStartTime = presentationTime
            assetWriter?.startSession(atSourceTime: presentationTime)
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let adaptor = pixelBufferAdaptor else { return }
        
        adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
    
    private func processAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        if sessionStartTime == nil {
            sessionStartTime = presentationTime
            assetWriter?.startSession(atSourceTime: presentationTime)
        }
        
        audioInput?.append(sampleBuffer)
    }
}

// MARK: - Supporting Types

enum EncodingError: Error {
    case invalidOutputURL
    case writerCreationFailed
    case writingStartFailed
    case encodingFailed
}