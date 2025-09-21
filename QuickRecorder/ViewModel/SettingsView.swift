//
//  SettingsView.swift
//  QuickRecorder
//
//  Created by apple on 2024/4/19.
//

import SwiftUI
import Sparkle
import ServiceManagement
import KeyboardShortcuts
import MatrixColorSelector

struct SettingsView: View {
    @State private var selectedItem: String? = "General"
    
    var body: some View {
        NavigationView {
            List(selection: $selectedItem) {
                NavigationLink(destination: GeneralView(), tag: "General", selection: $selectedItem) {
                    Label("General", image: "gear")
                }
                NavigationLink(destination: RecorderView(), tag: "Recorder", selection: $selectedItem) {
                    Label("Recorder", image: "record")
                }
                NavigationLink(destination: OutputView(), tag: "Output", selection: $selectedItem) {
                    Label("Output", image: "film")
                }
                NavigationLink(destination: HotkeyView(), tag: "Hotkey", selection: $selectedItem) {
                    Label("Hotkey", image: "hotkey")
                }
                NavigationLink(destination: BlocklistView(), tag: "Blaoklist", selection: $selectedItem) {
                    Label("Blocklist", image: "blacklist")
                }
            }
            .listStyle(.sidebar)
            .padding(.top, 9)
        }.frame(width: 600, height: 880)
    }
}

struct GeneralView: View {
    @AppStorage("countdown") private var countdown: Int = 0
    @AppStorage("poSafeDelay") private var poSafeDelay: Int = 1
    @AppStorage("showOnDock") private var showOnDock: Bool = true
    @AppStorage("showMenubar") private var showMenubar: Bool = false
    @AppStorage("disableFloatingPanel") private var disableFloatingPanel: Bool = false
    
    @State private var launchAtLogin = false

    var body: some View {
        SForm {
            SGroupBox(label: "Startup") {
                if #available(macOS 13, *) {
                    SToggle("Launch at Login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { newValue in
                            do {
                                if newValue {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            }catch{
                                print("Failed to \(newValue ? "enable" : "disable") launch at login: \(error.localizedDescription)")
                            }
                        }
                    SDivider()
                }
                SToggle("Show QuickRecorder on Dock", isOn: $showOnDock)
                    //.disabled(!showMenubar)
                SDivider()
                SToggle("Show QuickRecorder on Menu Bar", isOn: $showMenubar)
                    //.disabled(!showOnDock)
                SDivider()
                SToggle("Menu Bar Only (No Floating Panel)", isOn: $disableFloatingPanel)
                    .disabled(!showMenubar)
            }
            SGroupBox(label: "Update") { UpdaterSettingsView(updater: updaterController.updater) }
            VStack(spacing: 8) {
                CheckForUpdatesView(updater: updaterController.updater)
                if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("QuickRecorder v\(appVersion)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear{ if #available(macOS 13, *) { launchAtLogin = (SMAppService.mainApp.status == .enabled) }}
        .onChange(of: showMenubar) { _ in updateStatusBar() }
        .onChange(of: showOnDock) { newValue in
            if !newValue {
                NSApp.setActivationPolicy(.accessory)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                NSApp.setActivationPolicy(.regular)
            }
        }
    }
}

struct RecorderView: View {
    @AppStorage("countdown")        private var countdown: Int = 0
    @AppStorage("poSafeDelay")      private var poSafeDelay: Int = 1
    @AppStorage("highlightMouse")   private var highlightMouse: Bool = false
    @AppStorage("includeMenuBar")   private var includeMenuBar: Bool = true
    @AppStorage("hideDesktopFiles") private var hideDesktopFiles: Bool = false
    @AppStorage("trimAfterRecord")  private var trimAfterRecord: Bool = false
    @AppStorage("miniStatusBar")    private var miniStatusBar: Bool = false
    @AppStorage("hideSelf")         private var hideSelf: Bool = true
    @AppStorage("preventSleep")     private var preventSleep: Bool = true
    @AppStorage("showPreview")      private var showPreview: Bool = true
    @AppStorage("hideCCenter")      private var hideCCenter: Bool = false
    @AppStorage("recordingTimeout") private var recordingTimeout: Int = 0
    
    @State private var userColor: Color = Color.black

    private var timeoutStatusText: String {
        if recordingTimeout == 0 {
            return "Recording will not automatically stop"
        } else if recordingTimeout < 60 {
            return "Recording will stop after \(recordingTimeout) minute\(recordingTimeout == 1 ? "" : "s")"
        } else {
            let hours = recordingTimeout / 60
            let minutes = recordingTimeout % 60
            if minutes == 0 {
                return "Recording will stop after \(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                return "Recording will stop after \(hours)h \(minutes)m"
            }
        }
    }

    var body: some View {
        SForm(spacing: 10) {
            SGroupBox(label: "Recorder") {
                SSteper("Delay Before Recording", value: $countdown, min: 0, max: 99)
                SDivider()

                // Enhanced timeout configuration
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Auto-stop Recording (minutes)")
                        Spacer()
                        SSteper("", value: $recordingTimeout, min: 0, max: 1440)
                            .frame(width: 120)
                    }

                    // Quick preset buttons
                    HStack(spacing: 6) {
                        ForEach([
                            ("Off", 0),
                            ("30m", 30),
                            ("1h", 60),
                            ("2h", 120),
                            ("4h", 240),
                            ("8h", 480)
                        ], id: \.0) { preset in
                            Button(preset.0) {
                                recordingTimeout = preset.1
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                            .foregroundColor(recordingTimeout == preset.1 ? .white : .primary)
                            .background(recordingTimeout == preset.1 ? Color.accentColor : Color.clear)
                        }
                        Spacer()
                    }

                    Text(timeoutStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .help("Automatically stop recording after specified minutes. Set to 0 to disable timeout.")

                SDivider()
                if #available(macOS 14, *) {
                    SSteper("Presenter Overlay Delay", value: $poSafeDelay, min: 0, max: 99, tips: "If enabling Presenter Overlay causes recording failure, please increase this value.")
                    SDivider()
                }
                SItem(label: "Custom Background Color") {
                    if #unavailable(macOS 13) {
                        ColorPicker("", selection: $userColor)
                    } else {
                        MatrixColorSelector("", selection: $userColor)
                            .onChange(of: userColor) { userColor in ud.setColor(userColor, forKey: "userColor") }
                    }
                }
            }
            SGroupBox {
                SToggle("Mini size Menu Bar controller", isOn: $miniStatusBar)
                SDivider()
                SToggle("Prevent Mac from sleeping while recording", isOn: $preventSleep)
                SDivider()
                if #available(macOS 13, *) {
                    SToggle("Show floating preview after recording", isOn: $showPreview)
                    SDivider()
                }
                SToggle("Open video trimmer after recording", isOn: $trimAfterRecord)
            }
            SGroupBox {
                SToggle("Exclude QuickRecorder itself", isOn: $hideSelf)
                SDivider()
                if #available (macOS 13, *) {
                    SToggle("Include Menu Bar in Recording", isOn: $includeMenuBar)
                    SDivider()
                }
                SToggle("Hide Control Center Icons", isOn: $hideCCenter, tips: "Hide the clock, Wi-Fi, bluetooth, volume and other system icons in the menu bar.")
                SDivider()
                SToggle("Highlight the Mouse Cursor", isOn: $highlightMouse, tips: "Not available for \"Single Window Capture\"")
                SDivider()
                SToggle("Exclude Files on Desktop", isOn: $hideDesktopFiles, tips: "If enabled, all files on the Desktop will be hidden from the video when recording.")
            }
        }.onAppear{ userColor = ud.color(forKey: "userColor") ?? Color.black }
    }
}

struct OutputView: View {
    @AppStorage("encoder")          private var encoder: Encoder = .h265
    @AppStorage("videoFormat")      private var videoFormat: VideoFormat = .mp4
    @AppStorage("audioFormat")      private var audioFormat: AudioFormat = .aac
    @AppStorage("audioQuality")     private var audioQuality: AudioQuality = .high
    @AppStorage("pixelFormat")      private var pixelFormat: PixFormat = .delault
    @AppStorage("background")       private var background: BackgroundType = .wallpaper
    @AppStorage("remuxAudio")       private var remuxAudio: Bool = true
    @AppStorage("enableAEC")        private var enableAEC: Bool = false
    @AppStorage("AECLevel")         private var AECLevel: String = "mid"
    @AppStorage("withAlpha")        private var withAlpha: Bool = false
    @AppStorage("saveDirectory")    private var saveDirectory: String?
    @AppStorage("fileNamingPattern") private var fileNamingPattern: String = "Record at yyyy-MM-dd hh.mm.ss"
    @AppStorage("fileDeliveryDelay") private var fileDeliveryDelay: Int = 0

    var body: some View {
        SForm(spacing: 30) {
            SGroupBox(label: "Audio") {
                SPicker("Quality", selection: $audioQuality) {
                    if audioFormat == .alac || audioFormat == .flac {
                        Text("Lossless").tag(audioQuality)
                    }
                    Text("Normal - 128Kbps").tag(AudioQuality.normal)
                    Text("Good - 192Kbps").tag(AudioQuality.good)
                    Text("High - 256Kbps").tag(AudioQuality.high)
                    Text("Extreme - 320Kbps").tag(AudioQuality.extreme)
                }.disabled(audioFormat == .alac || audioFormat == .flac)
                SDivider()
                SPicker("Format", selection: $audioFormat) {
                    Text("MP3").tag(AudioFormat.mp3)
                    Text("AAC").tag(AudioFormat.aac)
                    Text("ALAC (Lossless)").tag(AudioFormat.alac)
                    Text("FLAC (Lossless)").tag(AudioFormat.flac)
                    Text("Opus").tag(AudioFormat.opus)
                }
                SDivider()
                if #available(macOS 13, *) {
                    SToggle("Record Microphone to Main Track", isOn: $remuxAudio)
                    SDivider()
                }
                SToggle("Enable Acoustic Echo Cancellation", isOn: $enableAEC)
                if #available(macOS 14, *) {
                    SDivider()
                    SPicker("Audio Ducking Level", selection: $AECLevel) {
                        Text("Min").tag("min")
                        Text("Mid").tag("mid")
                        Text("Max").tag("max")
                    }.disabled(!enableAEC)
                }
            }
            SGroupBox(label: "Video") {
                SPicker("Format", selection: $videoFormat) {
                    Text("MOV").tag(VideoFormat.mov)
                    Text("MP4").tag(VideoFormat.mp4)
                }.disabled(withAlpha)
                SDivider()
                SPicker("Encoder", selection: $encoder) {
                    Text("H.264").tag(Encoder.h264)
                    Text("H.265").tag(Encoder.h265)
                }.disabled(withAlpha)
                SDivider()
                SToggle("Recording with Alpha Channel", isOn: $withAlpha)
            }
            SGroupBox(label: "Save") {
                SItem(label: "Output Folder") {
                    Text(String(format: "Currently set to \"%@\"".local, saveDirectory!.lastPathComponent))
                        .font(.footnote)
                        .foregroundColor(Color.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Button("Select...", action: { updateOutputDirectory() })
                }
                SDivider()
                SItem(label: LocalizedStringKey("File Naming Pattern")) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("File naming pattern", text: $fileNamingPattern)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("Example: \(getPreviewFileName())")
                            .font(.caption)
                            .foregroundColor(Color.secondary)
                        Text("Tokens: yyyy (year), MM (month), dd (day), hh/HH (hour), mm (minute), ss (second)")
                            .font(.caption2)
                            .foregroundColor(Color.secondary)
                    }
                }
                SDivider()
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(LocalizedStringKey("Presets"))
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            HoverButton(color: .secondary, secondaryColor: .blue, action: {
                                fileNamingPattern = "Record at yyyy-MM-dd hh.mm.ss"
                            }) {
                                Text("Record at yyyy-MM-dd hh.mm.ss")
                                    .font(.caption)
                            }
                            
                            HoverButton(color: .secondary, secondaryColor: .blue, action: {
                                fileNamingPattern = "yyyy-MM-dd at hh.mm.ss"
                            }) {
                                Text("yyyy-MM-dd at hh.mm.ss")
                                    .font(.caption)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            HoverButton(color: .secondary, secondaryColor: .blue, action: {
                                fileNamingPattern = "Record_yyyy_MM_dd_hh_mm_ss"
                            }) {
                                Text("Record_yyyy_MM_dd_hh_mm_ss")
                                    .font(.caption)
                            }
                            
                            HoverButton(color: .secondary, secondaryColor: .blue, action: {
                                fileNamingPattern = "yyyy-MM-dd_hh-mm-ss_Record"
                            }) {
                                Text("yyyy-MM-dd_hh-mm-ss_Record")
                                    .font(.caption)
                            }
                        }
                    }
                }
                SDivider()
                SItem(label: "File Delivery Delay") {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Stepper(value: $fileDeliveryDelay, in: 0...60, step: 1) {
                                HStack {
                                    Text("\(fileDeliveryDelay) seconds")
                                    Spacer()
                                }
                            }
                        }
                        Text("Delay before moving files to destination folder (useful for folder watchers)")
                            .font(.caption2)
                            .foregroundColor(Color.secondary)
                    }
                }
            }
        }.onChange(of: withAlpha) {alpha in
            if alpha {
                encoder = Encoder.h265; videoFormat = VideoFormat.mov
            } else {
                if background == .clear { background = .wallpaper }
            }
        }
    }
    
    func getPreviewFileName() -> String {
        return SCContext.formatFileNamePattern(fileNamingPattern)
    }
    
    func updateOutputDirectory() { // todo: re-sandbox
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowedContentTypes = []
        openPanel.allowsOtherFileTypes = false
        if openPanel.runModal() == NSApplication.ModalResponse.OK {
            if let path = openPanel.urls.first?.path { saveDirectory = path }
        }
    }
}

struct HotkeyView: View {
    var body: some View {
        SForm(spacing: 10) {
            SGroupBox(label: "Hotkey") {
                SItem(label: "Open Main Panel") { KeyboardShortcuts.Recorder("", name: .showPanel) }
            }
            SGroupBox {
                SItem(label: "Stop Recording") { KeyboardShortcuts.Recorder("", name: .stop) }
                SDivider()
                SItem(label: "Pause / Resume") { KeyboardShortcuts.Recorder("", name: .pauseResume) }
            }
            SGroupBox {
                SItem(label: "Record System Audio") { KeyboardShortcuts.Recorder("", name: .startWithAudio) }
                SDivider()
                SItem(label: "Record Current Screen") { KeyboardShortcuts.Recorder("", name: .startWithScreen) }
                SDivider()
                SItem(label: "Record Topmost Window") { KeyboardShortcuts.Recorder("", name: .startWithWindow) }
                SDivider()
                SItem(label: "Select Area to Record") { KeyboardShortcuts.Recorder("", name: .startWithArea) }
            }
            SGroupBox {
                SItem(label: "Save Current Frame") { KeyboardShortcuts.Recorder("", name: .saveFrame) }
                SDivider()
                SItem(label: "Toggle Screen Magnifier") {KeyboardShortcuts.Recorder("", name: .screenMagnifier) }
            }
        }
    }
}

struct BlocklistView: View {
    var body: some View {
        SForm(spacing: 0, noSpacer: true) {
            SGroupBox(label: "Blocklist") {
                    BundleSelector()
                    Text("These apps will be excluded when recording \"Screen\" or \"Screen Area\"\nBut if the app is launched after the recording starts, it cannot be excluded.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.secondary)
            }
        }
    }
}

extension UserDefaults {
    func setColor(_ color: Color?, forKey key: String) {
        guard let color = color else {
            removeObject(forKey: key)
            return
        }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: NSColor(color), requiringSecureCoding: false)
            set(data, forKey: key)
        } catch {
            print("Error archiving color:", error)
        }
    }
    
    func color(forKey key: String) -> Color? {
        guard let data = data(forKey: key),
              let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) else {
            return nil
        }
        return Color(nsColor)
    }
    
    func cgColor(forKey key: String) -> CGColor? {
        guard let data = data(forKey: key),
              let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) else {
            return nil
        }
        return nsColor.cgColor
    }
}

extension KeyboardShortcuts.Name {
    static let startWithAudio = Self("startWithAudio")
    static let startWithScreen = Self("startWithScreen")
    static let startWithWindow = Self("startWithWindow")
    static let startWithArea = Self("startWithArea")
    static let screenMagnifier = Self("screenMagnifier")
    static let saveFrame = Self("saveFrame")
    static let pauseResume = Self("pauseResume")
    static let stop = Self("stop")
    static let showPanel = Self("showPanel")
}

extension AppDelegate {
    @available(macOS 13.0, *)
    @objc func setLoginItem(_ sender: NSMenuItem) {
        sender.state = sender.state == .on ? .off : .on
        do {
            if sender.state == .on { try SMAppService.mainApp.register() }
            if sender.state == .off { try SMAppService.mainApp.unregister() }
        }catch{
            print("Failed to \(sender.state == .on ? "enable" : "disable") launch at login: \(error.localizedDescription)")
        }
    }
}
