import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var menuBarController: MenuBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application did finish launching")
        
        // Set activation policy to accessory (menu bar only app)
        NSApp.setActivationPolicy(.accessory)
        print("Set activation policy to accessory")
        
        setupMenuBar()
        
        print("Application setup complete")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't terminate when windows close - keep running as menu bar app
        return false
    }
    
    private func setupMenuBar() {
        print("Setting up menu bar...")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        print("Created status item: \(statusItem != nil)")
        
        if let statusButton = statusItem?.button {
            print("Got status button, setting up icon...")
            // Try different icon options in order of preference
            var iconSet = false
            
            // Start with simplest approach - just text  
            statusButton.title = "🔴"
            statusButton.font = NSFont.systemFont(ofSize: 16)
            statusButton.imagePosition = .noImage
            print("Menu bar icon set with red circle emoji")
            iconSet = true
            
            statusButton.toolTip = "Mark Screen Recorder"
            
            if iconSet {
                print("Menu bar button created successfully")
            } else {
                print("Failed to set menu bar icon")
            }
        } else {
            print("Failed to create menu bar button")
        }
        
        Task { @MainActor in
            menuBarController = MenuBarController()
            statusItem?.menu = menuBarController?.createMenu()
            print("Menu bar setup completed")
        }
    }
    
}

@MainActor
class MenuBarController: NSObject {
    private let controller = ScreenRecordingController()
    
    func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        let statusMenuItem = NSMenuItem(title: "Ready to Record", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let startRecordingItem = NSMenuItem(title: "Start Recording", action: #selector(startRecording), keyEquivalent: "r")
        startRecordingItem.target = self
        menu.addItem(startRecordingItem)
        
        let pauseRecordingItem = NSMenuItem(title: "Pause Recording", action: #selector(pauseRecording), keyEquivalent: "p")
        pauseRecordingItem.target = self
        menu.addItem(pauseRecordingItem)
        
        let stopRecordingItem = NSMenuItem(title: "Stop Recording", action: #selector(stopRecording), keyEquivalent: "s")
        stopRecordingItem.target = self
        menu.addItem(stopRecordingItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let viewRecordingsItem = NSMenuItem(title: "View Recordings", action: #selector(viewRecordings), keyEquivalent: "")
        viewRecordingsItem.target = self
        menu.addItem(viewRecordingsItem)
        
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit Mark", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        return menu
    }
    
    @objc private func startRecording() {
        Task { @MainActor in
            controller.startRecording()
        }
    }
    
    @objc private func pauseRecording() {
        Task { @MainActor in
            controller.togglePauseRecording()
        }
    }
    
    @objc private func stopRecording() {
        Task { @MainActor in
            controller.stopRecording()
        }
    }
    
    @objc private func viewRecordings() {
        Task { @MainActor in
            openWindow(with: RecordingsManagerView(controller: controller))
        }
    }
    
    @objc private func showSettings() {
        Task { @MainActor in
            openWindow(with: SettingsView(settings: controller.appSettings))
        }
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    private func openWindow<Content: View>(with view: Content) {
        let hostingController = NSHostingController(rootView: view)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingController
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}