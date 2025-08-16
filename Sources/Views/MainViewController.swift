import SwiftUI

/// Main content view following MVC architecture
/// This view is responsible only for UI rendering and user interaction forwarding
struct ContentView: View {
    @StateObject private var controller = ScreenRecordingController()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Recording Tab
            RecordingTabView(controller: controller)
                .tabItem {
                    Label("Record", systemImage: "record.circle")
                }
                .tag(0)
            
            // Settings Tab
            SettingsView(settings: controller.appSettings)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(1)
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

// MARK: - Recording Tab View

struct RecordingTabView: View {
    @ObservedObject var controller: ScreenRecordingController
    
    private let captureAreaOptions = CaptureAreaType.allCases
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HeaderView(
                status: controller.recordingStatusText,
                statusColor: controller.recordingStatusColor
            )
            
            // Capture Area Picker
            CaptureAreaPickerView(
                selectedArea: $controller.selectedCaptureArea,
                options: captureAreaOptions,
                onSelectionChange: controller.selectCaptureArea
            )
            
            // Recording Controls
            RecordingControlsView(
                isRecording: controller.isRecording,
                isPaused: controller.isPaused,
                startButtonTitle: controller.startButtonTitle,
                pauseButtonTitle: controller.pauseButtonTitle,
                onStart: controller.startRecording,
                onPause: controller.togglePauseRecording,
                onStop: controller.stopRecording
            )
            
            // View Recordings Button
            Button("View Recordings") {
                controller.showRecordingsManager()
            }
            .buttonStyle(.bordered)
        }
        .padding(30)
        .onAppear {
            controller.onAppear()
        }
        .alert("Screen Recording Permission Required", isPresented: $controller.showingPermissionAlert) {
            Button("Open System Preferences") {
                PermissionsManager.shared.openSystemPreferences()
            }
            Button("Cancel") { }
        } message: {
            Text("This app requires screen recording permission to function. Please grant permission in System Preferences.")
        }
        .alert("Error", isPresented: $controller.showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(controller.alertMessage)
        }
        .alert("Recording Completed", isPresented: $controller.showingCompletedAlert) {
            Button("OK") { 
                if controller.appSettings.autoOpenFolder {
                    controller.openRecordingsFolder()
                }
            }
            Button("View Recordings") {
                controller.showRecordingsManager()
            }
            Button("Open Folder") {
                controller.openRecordingsFolder()
            }
        } message: {
            Text("Your screen recording has been saved successfully.")
        }
        .sheet(isPresented: $controller.showingRecordingsManager) {
            RecordingsManagerView(controller: controller)
        }
    }
}

// MARK: - Supporting View Components

struct HeaderView: View {
    let status: String
    let statusColor: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Screen Recorder")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(status)
                .font(.headline)
                .foregroundColor(statusColor)
        }
    }
}

struct CaptureAreaPickerView: View {
    @Binding var selectedArea: CaptureAreaType
    let options: [CaptureAreaType]
    let onSelectionChange: (CaptureAreaType) -> Void
    
    var body: some View {
        Picker("Capture Area", selection: $selectedArea) {
            ForEach(options, id: \.self) { option in
                Text(option.displayName).tag(option)
            }
        }
        .pickerStyle(.menu)
        .onChange(of: selectedArea) { newValue in
            onSelectionChange(newValue)
        }
    }
}

struct RecordingControlsView: View {
    let isRecording: Bool
    let isPaused: Bool
    let startButtonTitle: String
    let pauseButtonTitle: String
    let onStart: () -> Void
    let onPause: () -> Void
    let onStop: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            Button(startButtonTitle) {
                onStart()
            }
            .disabled(isRecording)
            .buttonStyle(.borderedProminent)
            
            Button(pauseButtonTitle) {
                onPause()
            }
            .disabled(!isRecording)
            .buttonStyle(.bordered)
            
            Button("Stop") {
                onStop()
            }
            .disabled(!isRecording)
            .buttonStyle(.bordered)
        }
    }
}

struct RecordingsManagerView: View {
    @Environment(\.dismiss) private var dismiss
    let controller: ScreenRecordingController
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Screen Recordings")
                .font(.title)
                .fontWeight(.bold)
            
            if controller.recordings.isEmpty {
                Text("No recordings found")
                    .foregroundColor(.secondary)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(controller.recordings, id: \.url) { recording in
                            RecordingRowView(
                                recording: recording,
                                onDelete: { controller.deleteRecording(recording) }
                            )
                        }
                    }
                }
            }
            
            HStack {
                Button("Open Folder") {
                    controller.openRecordingsFolder()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct RecordingRowView: View {
    let recording: RecordingFile
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(recording.name)
                    .font(.headline)
                
                let info = RecordingFileManager.shared.getRecordingInfo(at: recording.url)
                let duration = info?.formattedDuration ?? "Unknown"
                let resolution = info?.formattedResolution ?? "Unknown"
                
                Text("\(duration) • \(resolution) • \(recording.formattedSize)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Delete") {
                onDelete()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Output Settings Section
                    SettingsSectionView(title: "Output Settings") {
                        VStack(alignment: .leading, spacing: 15) {
                            // Default Save Folder
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Default Save Folder")
                                    .font(.headline)
                                
                                HStack {
                                    Text(settings.defaultSaveFolder.path)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    
                                    Spacer()
                                    
                                    Button("Choose Folder") {
                                        settings.selectFolder()
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            // Video Format
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Video Format")
                                    .font(.headline)
                                
                                Picker("Video Format", selection: $settings.videoFormat) {
                                    ForEach(VideoFormat.allCases, id: \.self) { format in
                                        Text(format.displayName).tag(format)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            // Video Quality
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Video Quality")
                                    .font(.headline)
                                
                                Picker("Video Quality", selection: $settings.videoQuality) {
                                    ForEach(VideoQuality.allCases, id: \.self) { quality in
                                        Text(quality.displayName).tag(quality)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            
                            // Framerate
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Framerate: \(settings.framerate) fps")
                                    .font(.headline)
                                
                                Slider(value: Binding(
                                    get: { Double(settings.framerate) },
                                    set: { settings.framerate = Int($0) }
                                ), in: 15...60, step: 15)
                                .accentColor(.blue)
                                
                                HStack {
                                    Text("15 fps")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("60 fps")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Recording Settings Section
                    SettingsSectionView(title: "Recording Settings") {
                        VStack(alignment: .leading, spacing: 15) {
                            Toggle("Include Audio", isOn: $settings.includeAudio)
                                .font(.headline)
                            
                            Toggle("Show Mouse Cursor", isOn: $settings.showMouseCursor)
                                .font(.headline)
                        }
                    }
                    
                    // Behavior Settings Section
                    SettingsSectionView(title: "Behavior") {
                        VStack(alignment: .leading, spacing: 15) {
                            Toggle("Auto-open folder after recording", isOn: $settings.autoOpenFolder)
                                .font(.headline)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .onChange(of: settings.videoFormat) { _ in settings.saveSettings() }
        .onChange(of: settings.videoQuality) { _ in settings.saveSettings() }
        .onChange(of: settings.includeAudio) { _ in settings.saveSettings() }
        .onChange(of: settings.showMouseCursor) { _ in settings.saveSettings() }
        .onChange(of: settings.framerate) { _ in settings.saveSettings() }
        .onChange(of: settings.autoOpenFolder) { _ in settings.saveSettings() }
    }
}

struct SettingsSectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            content
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
        }
    }
}