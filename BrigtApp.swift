import SwiftUI
import AppKit

class SoftwareDimmer: ObservableObject {
    @Published var brightness: Double = 100 {
        didSet {
            // Trigger UI update explicitly if needed, 
            // though @Published handles this for the MenuBarExtra view.
            updateOverlays()
            saveState()
        }
    }
    
    private var windows: [NSWindow] = []
    private let stateFile = NSString(string: "~/.brigt_software_state").expandingTildeInPath
    
    init() {
        loadState()
        
        // Delay window setup slightly to ensure app is ready
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
            // If it's the built-in screen and we have others, skip it
            // On M1 MacBook Air/Pro, the first screen is usually the built-in.
            if NSScreen.screens.count > 1 && screen == NSScreen.screens.first {
                continue
            }
            
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            window.backgroundColor = .black
            window.alphaValue = alpha
            window.isReleasedWhenClosed = false
            window.ignoresMouseEvents = true
            
            // Using a extremely high level to ensure it's on top of everything
            window.level = NSWindow.Level(Int(CGWindowLevelForKey(.maximumWindow)))
            
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
            window.canHide = false
            window.hidesOnDeactivate = false
            
            window.orderFrontRegardless()
            windows.append(window)
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
                Button("Refresh Screens") {
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
        .frame(width: 250)
    }
}

@main
struct BrigtApp: App {
    @StateObject private var dimmer = SoftwareDimmer()
    
    var body: some Scene {
        MenuBarExtra {
            SettingsView(dimmer: dimmer)
        } label: {
            Image(systemName: "sun.max.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
