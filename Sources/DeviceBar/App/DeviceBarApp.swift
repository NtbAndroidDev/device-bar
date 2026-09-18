import SwiftUI
import AppKit

@main
struct DeviceBarApp: App {
    @StateObject private var viewModel = AppViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MainView(viewModel: viewModel)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "macbook.and.iphone")
                if viewModel.bootedSimulatorsCount > 0 {
                    Text("\(viewModel.bootedSimulatorsCount)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensures app behaves cleanly as a MenuBar accessory without Dock clutter
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}

