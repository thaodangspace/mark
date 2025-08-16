import Foundation
import AppKit
import AVFoundation

class RecordingFileManager {
    static let shared = RecordingFileManager()
    
    private var recordingsDirectory: URL {
        let moviesURL = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first
        return moviesURL?.appendingPathComponent("Mark Recordings") ?? FileManager.default.homeDirectoryForCurrentUser
    }
    
    private init() {
        createRecordingsDirectoryIfNeeded()
    }
    
    private func createRecordingsDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: recordingsDirectory.path) {
            try? FileManager.default.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
        }
    }
    
    func generateOutputURL(format: VideoFormat = .mov) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let fileName = "ScreenRecording_\(timestamp).\(format.fileExtension)"
        return recordingsDirectory.appendingPathComponent(fileName)
    }
    
    @MainActor
    func generateOutputURLWithSettings() -> URL {
        let settings = AppSettings()
        return generateOutputURL(format: settings.videoFormat)
    }
    
    @MainActor
    func getRecordingsDirectory() -> URL {
        let settings = AppSettings()
        return settings.defaultSaveFolder
    }
    
    func getAllRecordings() -> [RecordingFile] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: recordingsDirectory, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey]) else {
            return []
        }
        
        let recordings = files.compactMap { url -> RecordingFile? in
            guard ["mov", "mp4"].contains(url.pathExtension.lowercased()) else { return nil }
            
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
            let size = attributes?[.size] as? Int64 ?? 0
            let creationDate = attributes?[.creationDate] as? Date ?? Date()
            
            return RecordingFile(url: url, size: size, creationDate: creationDate)
        }
        
        return recordings.sorted { $0.creationDate > $1.creationDate }
    }
    
    func deleteRecording(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
    
    func openRecordingsFolder() {
        NSWorkspace.shared.open(recordingsDirectory)
    }
    
    func getRecordingInfo(at url: URL) -> RecordingInfo? {
        let asset = AVAsset(url: url)
        
        // Use the newer async API in a sync context
        let group = DispatchGroup()
        var recordingInfo: RecordingInfo?
        
        group.enter()
        Task {
            do {
                let tracks = try await asset.loadTracks(withMediaType: .video)
                guard let videoTrack = tracks.first else {
                    group.leave()
                    return
                }
                
                let duration = try await asset.load(.duration)
                let size = try await videoTrack.load(.naturalSize)
                let frameRate = try await videoTrack.load(.nominalFrameRate)
                
                recordingInfo = RecordingInfo(
                    duration: duration,
                    resolution: size,
                    frameRate: frameRate,
                    fileSize: getFileSize(at: url)
                )
            } catch {
                // Fallback to synchronous deprecated API if async fails
                if let videoTrack = asset.tracks(withMediaType: .video).first {
                    recordingInfo = RecordingInfo(
                        duration: asset.duration,
                        resolution: videoTrack.naturalSize,
                        frameRate: videoTrack.nominalFrameRate,
                        fileSize: getFileSize(at: url)
                    )
                }
            }
            group.leave()
        }
        
        group.wait()
        return recordingInfo
    }
    
    private func getFileSize(at url: URL) -> Int64 {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.size] as? Int64 ?? 0
    }
}

