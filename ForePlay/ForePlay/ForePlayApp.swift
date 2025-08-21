import SwiftUI
import AVFoundation
import AVFAudio
import AVKit
import Speech
import Vision
import CoreMedia
#if canImport(UIKit)
import UIKit
#endif


@main
struct ForePlayApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

final class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
}

// =============================================================
// File: Theme.swift (colors + fonts)
// =============================================================
import SwiftUI

extension Color {
    // PGA-inspired
    static let fpNavy = Color(red: 0.043, green: 0.145, blue: 0.271)   // #0B2545 approx
    static let fpGreen = Color(red: 0.173, green: 0.478, blue: 0.173) // #2C7A2C approx
    static let fpGold = Color(red: 0.839, green: 0.686, blue: 0.345)   // #D6AF58 approx
}

struct FPButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.fpGreen.opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// =============================================================
// File: RootView.swift (tabs)
// =============================================================
import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            CaptureView()
                .tabItem { Label("Record", systemImage: "video") }
            LibraryView()
                .tabItem { Label("Library", systemImage: "film") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .tint(.fpGreen)
    }
}

// =============================================================
// File: CaptureView.swift (UI wrapper around camera + overlays + CaDi)
// =============================================================
import SwiftUI

struct CaptureView: View {
    @StateObject private var camera = CameraController()
    @State private var showOverlay: Bool = true
    @State private var isRecording: Bool = false
    @State private var showPlayer: Bool = false
    @State private var lastRecordedURL: URL?
    @StateObject private var cadi = CaDiKit()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            CameraView(controller: camera)
                .ignoresSafeArea()
            
            if showOverlay {
                OverlayEditor()
                    .allowsHitTesting(true)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 10) {
                HStack {
                    Toggle(isOn: $showOverlay) { Text("Guides").font(.caption).foregroundColor(.white) }
                        .tint(.fpGreen)
                        .padding(8)
                        .background(.black.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Spacer()
                    Text(cadi.playbackRateLabel)
                        .font(.caption.bold()).foregroundColor(.white)
                        .padding(8)
                        .background(.black.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                // Chips above the bar
                HStack {
                    MetricsChip(text: cadi.lastAnalysis?.formatted ?? "")
                    Spacer()
                    VoiceStateChip(listening: cadi.isListening)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 6)

                // Bottom blurred bar with mic + record
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .frame(height: 120)
                        .padding(.horizontal, 16)
                        .shadow(radius: 10)
                    
                    HStack(spacing: 28) {
                        if cadi.speechAuthorized {
                            GolfMicButton(
                                isListening: cadi.isListening,
                                onPressStart: { cadi.isListening = true },
                                onPressEnd: {
                                    cadi.isListening = false
                                    Task { await cadi.handlePushToTalk(getContext: camera.latestQuickSummary) }
                                }
                            )
                        } else {
                            // Disabled mic with hint
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 80, height: 80)
                                    .overlay(Image(systemName: "mic.slash.fill").font(.system(size: 28, weight: .bold)).foregroundColor(.white))
                                Text("Enable Speech & Mic in Settings")
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white.opacity(0.9))
                                    .frame(width: 120)
                            }
                        }
                        
                        TeeRecordButton(
                            isRecording: isRecording,
                            onTap: {
                                if isRecording {
                                    camera.stopRecording { url in
                                        lastRecordedURL = url
                                        isRecording = false
                                        if let u = url {
                                            Task {
                                                let result = await AnalysisKit.analyze(url: u)
                                                cadi.updateAnalysis(result)
                                                VoiceEngine.speak("Quick read: \(result.formatted). Want a cue?")
                                            }
                                            showPlayer = true
                                        }
                                    }
                                } else {
                                    camera.startRecording()
                                    isRecording = true
                                }
                            }
                        )
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $showPlayer) {
            if let url = lastRecordedURL {
                PlayerView(videoURL: url)
                    .environmentObject(cadi)
            } else { Text("No video available") }
        }
        .task {
            await cadi.prepareSpeech()
        }
    }
}

// =============================================================
// File: SwingOverlayView.swift (simple guides)
// =============================================================
import SwiftUI

struct SwingOverlayView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Target line (horizontal)
                Rectangle()
                    .fill(Color.fpGreen.opacity(0.8))
                    .frame(height: 2)
                    .position(x: geo.size.width/2, y: geo.size.height * 0.65)
                // Swing plane guide (diagonal)
                Path { p in
                    p.move(to: CGPoint(x: geo.size.width * 0.1, y: geo.size.height * 0.85))
                    p.addLine(to: CGPoint(x: geo.size.width * 0.9, y: geo.size.height * 0.4))
                }
                .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6,6]))
            }
        }
        .allowsHitTesting(false)
    }
}

// =============================================================
// File: CameraController.swift (AVFoundation capture to local file)
// =============================================================
import AVFoundation
import SwiftUI

final class CameraController: NSObject, ObservableObject {
    private let session = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    var onSampleBuffer: ((CMSampleBuffer) -> Void)?
    
    override init() {
        super.init()
        configureSession()
    }
    
    func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else { return }
        session.addInput(videoInput)
        
        if session.canAddOutput(movieOutput) { session.addOutput(movieOutput) }
        // Live frames for analysis
        if session.canAddOutput(videoDataOutput) {
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frames.queue"))
            session.addOutput(videoDataOutput)
        }
        session.commitConfiguration()
        session.startRunning()
    }
    
    func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
        if let layer = previewLayer { return layer }
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        self.previewLayer = layer
        return layer
    }
    
    func startRecording() {
        let url = StorageManager.shared.newVideoURL()
        movieOutput.startRecording(to: url, recordingDelegate: self)
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        self.completion = completion
        movieOutput.stopRecording()
    }
    
    private var completion: ((URL?) -> Void)?
    
    // Quick context summary stub for CaDi
    func latestQuickSummary() -> String {
        // In a later version, compute simple metrics and return.
        return "tempo ~3:1, likely in-to-out path, contact slightly toe-side (placeholder)"
    }
}

extension CameraController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        completion?(error == nil ? outputFileURL : nil)
        completion = nil
    }
}

extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        onSampleBuffer?(sampleBuffer)
    }
}

struct CameraView: UIViewControllerRepresentable {
    let controller: CameraController
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        let layer = controller.makePreviewLayer()
        layer.frame = UIScreen.main.bounds
        vc.view.layer.addSublayer(layer)
        return vc
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        controller.makePreviewLayer().frame = uiViewController.view.bounds
    }
}

// =============================================================
// File: PlayerView.swift (AVPlayer + scrub + rate toggle via CaDi + share)
// =============================================================
import SwiftUI
import AVKit

struct PlayerView: View {
    let videoURL: URL
    @State private var player: AVPlayer = AVPlayer()
    @State private var rate: Float = 0.5
    @EnvironmentObject var cadi: CaDiKit
    @State private var showCompare: Bool = false
    @State private var compareWithURL: URL?
    @State private var showShare: Bool = false
    @State private var exportedURL: URL?
    
    var body: some View {
        VStack(spacing: 12) {
            VideoPlayer(player: player)
                .onAppear {
                    player.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
                    player.play()
                    player.rate = rate
                }
                .frame(maxHeight: 360)
            
            HStack(spacing: 12) {
                Button("0.25x") { setRate(0.25) }.buttonStyle(FPButtonStyle())
                Button("0.5x")  { setRate(0.5)  }.buttonStyle(FPButtonStyle())
                Button("1.0x")  { setRate(1.0)  }.buttonStyle(FPButtonStyle())
                Spacer()
                Button {
                    compareWithURL = LibraryHelper.previousClip(before: videoURL)
                    showCompare = (compareWithURL != nil)
                } label: {
                    Label("Compare", systemImage: "rectangle.on.rectangle")
                }
                .buttonStyle(FPButtonStyle())
            }
            .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CaDi says:").font(.headline).foregroundColor(.fpNavy)
                    if let last = cadi.lastResponse {
                        Text(last).foregroundColor(.primary)
                    } else {
                        Text("Press and hold the mic, tell me what you felt.").foregroundColor(.secondary)
                    }
                }.padding()
            }
            
            // CaDi mic on Player (optional)
            HoldToTalkButton(isListening: $cadi.isListening, onRelease: {
                Task { await cadi.handlePushToTalk(getContext: { "Reviewing last swing clip" }) }
            }, label: "Ask CaDi")
            .padding(.top, 8)
            
            HStack {
                Button {
                    ShareExportManager().exportWithCaption(videoURL: videoURL, caption: cadi.lastResponse ?? "ForePlay – Swing Review") { url in
                        self.exportedURL = url
                        self.showShare = (url != nil)
                    }
                } label: {
                    Label("Export with Caption", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(FPButtonStyle())
            }

            Spacer()
        }
        .background(Color(UIColor.systemBackground))
        .onDisappear { player.pause() }
        .sheet(isPresented: $showCompare) {
            if let other = compareWithURL {
                ComparisonView(aURL: videoURL, bURL: other)
            }
        }
        .sheet(isPresented: $showShare) {
            if let u = exportedURL {
                ShareSheet(activityItems: [u])
            }
        }
    }
    
    private func setRate(_ newRate: Float) {
        rate = newRate
        player.rate = newRate
    }
}

// =============================================================
// File: ComparisonView.swift (overlay A over B with slider)
// =============================================================
// This has been moved to ComparisonView.swift

// =============================================================
// File: HoldToTalkButton.swift (push-to-talk mic UI)
// =============================================================
// HoldToTalkButton removed - now using GolfMicButton from GolfMicButton.swift

// Golf ball look-and-feel components removed - now in GolfMicButton.swift


// =============================================================
// File: CaDiKit.swift (STT + TTS + LLM stub with OpenAI voices fallback)
// =============================================================
import Foundation
import Speech
import AVFoundation

@MainActor
final class CaDiKit: ObservableObject {
    @Published var isListening: Bool = false {
        didSet { isListening ? startListening() : stopListening() }
    }
    @Published var lastResponse: String?
    @Published var speechAuthorized: Bool = false

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let synthesizer = AVSpeechSynthesizer()
    // Playback rate state mirrored for UI label
    @Published var playbackRateLabel: String = "0.5x"
    private var currentRateIndex = 1 // 0:0.25, 1:0.5, 2:1.0
    private let rates: [String] = ["0.25x","0.5x","1.0x"]

    func togglePlaybackRate() {
        currentRateIndex = (currentRateIndex + 1) % rates.count
        playbackRateLabel = rates[currentRateIndex]
    }

    init() {
        // VoiceEngine is now a static utility, no initialization needed
    }

    func prepareSpeech() async {
        // Speech recognition permission (completion-handler API)
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                let ok = (status == .authorized)
                self?.speechAuthorized = ok
                if !ok {
                    self?.lastResponse = "Enable Speech Recognition & Microphone in Settings to use CaDi."
                }
            }
        }

        // Microphone permission (iOS 17+: AVAudioApplication, else AVAudioSession)
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if !granted {
                        self?.lastResponse = "Microphone access is required for CaDi push-to-talk."
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if !granted {
                        self?.lastResponse = "Microphone access is required for CaDi push-to-talk."
                    }
                }
            }
        }

        // Configure audio session (AirPods/Bluetooth supported)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
        try? session.setActive(true)
    }

    private func startListening() {
        stopListening()
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        audioEngine.prepare()
        try? audioEngine.start()

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result = result, result.isFinal {
                Task { await self.respond(to: result.bestTranscription.formattedString) }
            }
            if error != nil { self.stopListening() }
        }
    }

    private func stopListening() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        recognitionTask?.cancel()
        recognitionTask = nil
        request = nil
    }

    func handlePushToTalk(getContext: () -> String) async {
        let ctx = getContext()
        
        // Use analysis results if available, otherwise fall back to generic coaching
        if let analysis = lastAnalysis {
            let (cue, drill) = getCoachingFeedback(for: analysis)
            let reply = "Feel: \(cue)\nDrill: \(drill)"
            self.lastResponse = reply
            speak(reply)
        } else {
            // Fallback to generic coaching
            let cue = "Feel: Keep the trail elbow closer to the body through impact."
            let drill = "Drill: Split-hands half-swings; focus on clubface staying square to the target line for 20 reps."
            let reply = "Feel: \(cue)\nDrill: \(drill)"
            self.lastResponse = reply
            speak(reply)
        }
    }
    
    // MARK: - Analysis Integration
    @Published var lastAnalysis: AnalysisResult?
    
    func updateAnalysis(_ analysis: AnalysisResult) {
        lastAnalysis = analysis
    }
    
    private func getCoachingFeedback(for result: AnalysisResult) -> (cue: String, drill: String) {
        var cues: [String] = []
        var drills: [String] = []
        
        // Tempo feedback
        if let tempo = result.tempoRatio {
            if tempo < 2.5 {
                cues.append("Too fast on the way down")
                drills.append("Count 1-2 to top, 3 through impact")
            } else if tempo > 3.5 {
                cues.append("Slow down your transition")
                drills.append("Pause at top for 1 count")
            }
        }
        
        // Plane feedback
        if let plane = result.shaftPlaneDeg {
            if plane > 60 {
                cues.append("Shaft too steep at top")
                drills.append("Practice half-swings with alignment stick")
            } else if plane < 45 {
                cues.append("Shaft too flat at top")
                drills.append("Practice half-swings with alignment stick")
            }
        }
        
        // Sway feedback
        if let sway = result.hipSwayCm {
            if abs(sway) > 8 {
                if sway > 0 {
                    cues.append("Too much rightward hip sway")
                } else {
                    cues.append("Too much leftward hip sway")
                }
                drills.append("Keep trail hip back through impact")
            }
        }
        
        // Default if no issues
        if cues.isEmpty {
            cues.append("Good swing fundamentals")
            drills.append("Continue with current form")
        }
        
        return (
            cue: cues.first ?? "Keep practicing",
            drill: drills.first ?? "Focus on tempo"
        )
    }

    private func respond(to text: String) async {
        let reply = CaDiHeuristics.reply(for: text)
        self.lastResponse = reply
        speak(reply)
    }

    // MARK: - Voice quality helpers
    // bestVoice method removed - now handled by VoiceEngine.swift

    private func speak(_ text: String) { 
        VoiceEngine.speak(text)
    }
}

enum CaDiHeuristics {
    static func reply(for userText: String) -> String {
        // Ultra-simple mapping; expand over time
        let t = userText.lowercased()
        if t.contains("hook") || t.contains("left") { return "Feel: Exit left with chest; keep face passive.\nDrill: Hit nine-to-three with alignment stick outside the ball to neutralize path." }
        if t.contains("slice") || t.contains("right") { return "Feel: Close the face earlier with lead wrist flex.\nDrill: Towel under both arms; half-swings focusing on body turn, 15 reps." }
        return "Feel: Smooth tempo—count 1-2 to top, 3 through impact.\nDrill: Metronome 60 bpm; three-to-one tempo with waist-high swings, 20 reps."
    }
}

// =============================================================
// File: OpenAIVoice.swift (native voices via TTS API, with fallback)
// =============================================================
// This has been moved to VoiceEngine.swift

// =============================================================
// File: SwingAnalyzer.swift (Vision pose scaffolding + overlay model)
// =============================================================
// This has been replaced by the new AnalysisKit.swift file

// PoseOverlayView removed - replaced by OverlayEditor
// =============================================================
// File: StorageManager.swift (local videos + thumbnails)
// =============================================================
import AVFoundation

final class StorageManager {
    static let shared = StorageManager()
    private init() {}
    
    func newVideoURL() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let name = "swing_\(Int(Date().timeIntervalSince1970)).mov"
        return dir.appendingPathComponent(name)
    }
    
    func generateThumbnail(for url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        if let cg = try? imgGenerator.copyCGImage(at: CMTime(seconds: 0.1, preferredTimescale: 600), actualTime: nil) {
            return UIImage(cgImage: cg)
        }
        return nil
    }
}

// =============================================================
// File: LibraryView.swift (simple list of recorded swings)
// =============================================================
import SwiftUI

struct LibraryView: View {
    @State private var items: [URL] = []
    
    var body: some View {
        NavigationView {
            List(items, id: \.self) { url in
                HStack {
                    if let img = StorageManager.shared.generateThumbnail(for: url) {
                        Image(uiImage: img).resizable().scaledToFill().frame(width: 64, height: 64).clipped().cornerRadius(8)
                    }
                    Text(url.lastPathComponent).lineLimit(1)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture { selectedURL = url; showPlayer = true }
            }
            .navigationTitle("Library")
            .onAppear { load() }
            .sheet(isPresented: $showPlayer) { if let u = selectedURL { PlayerView(videoURL: u) } }
        }
    }
    @State private var showPlayer = false
    @State private var selectedURL: URL?
    
    private func load() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        items = files.filter { $0.pathExtension.lowercased() == "mov" }.sorted { $0.lastPathComponent > $1.lastPathComponent }
    }
}

enum LibraryHelper {
    static func allClips() -> [URL] {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        return files.filter { $0.pathExtension.lowercased() == "mov" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
    static func previousClip(before url: URL) -> URL? {
        let clips = allClips()
        guard let idx = clips.firstIndex(of: url), idx > 0 else { return nil }
        return clips[idx - 1]
    }
}

// =============================================================
// File: ShareExportManager.swift (caption overlay export)
// =============================================================
// This has been moved to ShareExportManager.swift
// =============================================================
// File: SettingsView.swift (permissions + delete data)
// =============================================================
import SwiftUI

struct SettingsView: View {
    @State private var showConfirm = false
    @State private var useOpenAIVoices = false
    @State private var alwaysListenMode = false
    @State private var showPrivacyPolicy = false
    
    var body: some View {
        Form {
            Section(header: Text("Permissions")) {
                Text("Camera & Microphone are used to record swings and talk to CaDi.")
            }
            
            Section(header: Text("Voice Settings")) {
                Toggle("Use OpenAI Voices", isOn: $useOpenAIVoices)
                    .onChange(of: useOpenAIVoices) { newValue in
                        // This would be implemented in CaDiKit
                        print("OpenAI voices toggled: \(newValue)")
                    }
                
                Toggle("Always Listen (AirPods/Bluetooth)", isOn: $alwaysListenMode)
                    .onChange(of: alwaysListenMode) { newValue in
                        // This would be implemented in CaDiKit for future AirPods integration
                        print("Always listen mode toggled: \(newValue)")
                    }
                
                if useOpenAIVoices {
                    Text("Requires OPENAI_API_KEY in Info.plist")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Data")) {
                Button("Delete all local videos", role: .destructive) { showConfirm = true }
            }
            
            Section(header: Text("About")) {
                Text("ForePlay v1.0.0")
                Text("No analytics. No ads. Your swings stay on this device.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                
                Button("Privacy Policy") {
                    showPrivacyPolicy = true
                }
                .foregroundColor(.fpGreen)
            }
        }
        .alert("Delete all local videos?", isPresented: $showConfirm) {
            Button("Delete", role: .destructive) { deleteAll() }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .navigationTitle("Settings")
        .onAppear {
            // Check if OpenAI API key is available
            if let _ = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String {
                useOpenAIVoices = true
            }
        }
    }
    private func deleteAll() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        for f in files where f.pathExtension.lowercased() == "mov" { try? FileManager.default.removeItem(at: f) }
    }
}

// =============================================================
// App Store / Review Prep (copy into your metadata)
// =============================================================
/*
App Name: ForePlay
Subtitle: Record. See. Fix. Fast.
Promotional text: Tap to record a golf swing, get a quick cue from CaDi, and try a simple drill—on the spot.
Keywords: golf, swing, analyzer, slow motion, practice, drill, coach, tempo
Description:
ForePlay is the quickest way to record your golf swing, review it in slow motion, and get one actionable cue from CaDi—your on-device voice caddie. No accounts. No ads. Your swings stay on your phone.

What’s in v1:
• One-tap recording (1080p)
• Slow-motion playback (0.25x/0.5x/1.0x)
• Simple guides: target line + swing plane
• CaDi: push-to-talk voice tips with a single cue and one drill
• Local storage library

Privacy:
• Camera/Mic strictly for recording and voice features
• No tracking, no ads, no analytics

Support: your-email@yourdomain.com

App Privacy (Nutrition Label):
• Data Not Collected (User Content stored on device)
• Camera, Microphone: Required for core features
*/

// =============================================================
// Privacy Policy (drop this as a Markdown page on your site)
// =============================================================
/*
Privacy Policy – ForePlay (v1)

ForePlay records golf swing videos and provides optional voice guidance via CaDi on your device. We do not collect personal data, and your content remains stored locally unless you choose to export it.

Data We Access
- Camera: to record swings.
- Microphone: for push-to-talk with CaDi.
- Local Storage: to save your videos and settings.

What We Do Not Do
- No analytics SDKs.
- No advertising or tracking.
- No cloud storage by default.

Your Choices
- Delete all local videos anytime in Settings.
- Revoke camera/microphone permissions in iOS Settings.

Children’s Privacy
ForePlay is not intended for children under 13.

Contact
For questions or requests: your-email@yourdomain.com

Changes
We may update this policy; we will post revisions with the effective date.
*/
