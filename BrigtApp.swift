import SwiftUI
import AppKit

class SoftwareDimmer: ObservableObject {
    @Published var brightness: Double = 100 {
        didSet {
            updateOverlays()
            saveState()
        }
    }
    
    private var windows: [NSPanel] = []
    private let stateFile = NSString(string: "~/.brigt_software_state").expandingTildeInPath
    
    init() {
        loadState()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setupWindows()
        }
        
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            self?.setupWindows()
        }
    }
    
    func setupWindows() {
        windows.forEach { $0.close() }
        windows.removeAll()
        
        let alpha = CGFloat(1.0 - (brightness / 100.0))
        
        for screen in NSScreen.screens {
            if NSScreen.screens.count > 1 && screen == NSScreen.screens.first {
                continue
            }
            
            let panel = NSPanel(
                contentRect: screen.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            panel.backgroundColor = .black
            panel.alphaValue = alpha
            panel.isReleasedWhenClosed = false
            panel.ignoresMouseEvents = true
            panel.level = NSWindow.Level(Int(CGWindowLevelForKey(.maximumWindow)))
            panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
            panel.canHide = false
            panel.hidesOnDeactivate = false
            
            panel.orderFrontRegardless()
            windows.append(panel)
        }
    }
    
    private func updateOverlays() {
        let alpha = CGFloat(1.0 - (brightness / 100.0))
        DispatchQueue.main.async {
            for window in self.windows {
                window.alphaValue = alpha
            }
        }
    }
    
    private func loadState() {
        if let content = try? String(contentsOfFile: stateFile),
           let value = Double(content.trimmingCharacters(in: .whitespacesAndNewlines)) {
            self.brightness = value
        }
    }
    
    private func saveState() {
        try? String(brightness).write(toFile: stateFile, atomically: true, encoding: .utf8)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var dimmer: SoftwareDimmer?
    var popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        dimmer = SoftwareDimmer()
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sun.max.fill", accessibilityDescription: "Brightness")
            button.action = #selector(togglePopover)
        }
        
        let settingsView = SettingsView(dimmer: dimmer!)
        popover.contentSize = NSSize(width: 250, height: 180)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: settingsView)
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem?.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var dimmer: SoftwareDimmer
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.yellow)
                Text("Brightness")
                    .font(.headline)
                Spacer()
                Text("\(Int(dimmer.brightness))%")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $dimmer.brightness, in: 10...100, step: 1)
                .accentColor(.blue)
            
            Text("Software dimming active for external display")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            
            Divider()
            
            HStack {
                Button("Refresh") {
                    dimmer.setupWindows()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
    }
}

@main
struct BrigtApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
