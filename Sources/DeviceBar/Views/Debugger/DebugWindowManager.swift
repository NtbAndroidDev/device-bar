import AppKit
import SwiftUI

@MainActor
public final class DebugWindowManager {
    public static let shared = DebugWindowManager()
    
    private var networkWindows: [String: NSWindowController] = [:]
    private var crashWindows: [String: NSWindowController] = [:]
    
    private init() {}
    
    // MARK: - Network Inspector Window
    public func openNetworkInspector(deviceName: String = "Device", serial: String = "default", isAndroid: Bool = false) {
        let windowKey = "network-\(serial)"
        
        if let controller = networkWindows[windowKey], let window = controller.window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let contentView = NetworkInspectorView(deviceName: deviceName, serial: serial, isAndroid: isAndroid)
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Network & API Inspector — \(deviceName) (\(serial))"
        window.contentViewController = hostingController
        window.minSize = NSSize(width: 780, height: 480)
        window.isReleasedWhenClosed = false
        
        let windowController = NSWindowController(window: window)
        networkWindows[windowKey] = windowController
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.networkWindows.removeValue(forKey: windowKey)
            }
        }
        
        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Crash Inspector Window
    public func openCrashInspector(deviceName: String = "Device", serial: String = "default", isAndroid: Bool = false) {
        let windowKey = "crash-\(serial)"
        
        if let controller = crashWindows[windowKey], let window = controller.window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let contentView = CrashInspectorView(deviceName: deviceName, serial: serial, isAndroid: isAndroid)
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Crash Detective — \(deviceName)"
        window.contentViewController = hostingController
        window.minSize = NSSize(width: 580, height: 380)
        window.isReleasedWhenClosed = false
        
        let windowController = NSWindowController(window: window)
        crashWindows[windowKey] = windowController
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.crashWindows.removeValue(forKey: windowKey)
            }
        }
        
        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
