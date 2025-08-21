import SwiftUI
import AVFoundation
import AVFAudio
import AVKit
import Speech
#if canImport(UIKit)
// UIKit guarded import (top)
#if canImport(UIKit)
// UIKit guarded import (StorageManager section)
#if canImport(UIKit)
#if canImport(UIKit)
import UIKit
#endif
#endif
#endif
#endif
import Vision
import CoreMedia


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
import AVKit

struct ComparisonView: View {
    let aURL: URL // current
    let bURL: URL // previous
    @State private var opacity: Double = 0.5
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                VideoPlayer(player: AVPlayer(url: bURL))
                VideoPlayer(player: AVPlayer(url: aURL))
                    .opacity(opacity)
            }
            .frame(height: 360)
            .clipped()
            
            HStack { Text("A"); Slider(value: $opacity, in: 0...1); Text("B") }
                .padding(.horizontal)
            Text("Overlay your last swing vs current one.").font(.footnote).foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }
}

// =============================================================
// File: HoldToTalkButton.swift (push-to-talk mic UI)
// =============================================================
import SwiftUI

struct HoldToTalkButton: View {
    @Binding var isListening: Bool
    var onRelease: () -> Void
    var label: String = "Hold to talk"

    var body: some View {
        VStack(spacing: 8) {
            GolfBallCircle(fillColor: isListening ? .red : .white)
                .frame(width: 80, height: 80)
                .overlay(
                    ZStack {
                        Circle().stroke(Color.fpGold.opacity(0.8), lineWidth: 2)
                        Image(systemName: "mic.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(isListening ? .white : .fpNavy)
                    }
                )
                .scaleEffect(isListening ? 1.06 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isListening)
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isListening {
                                isListening = true
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        }
                        .onEnded { _ in
                            isListening = false
                            onRelease()
                        }
                )
                .accessibilityLabel("Hold to talk to CaDi")
            Text(label)
                .font(.caption.bold())
                .foregroundColor(.white)
                .shadow(radius: 4)
        }
    }
}

// Golf ball look-and-feel
struct GolfBallCircle: View {
    var fillColor: Color = .white
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(colors: [fillColor, fillColor.opacity(0.85)], center: .topLeading, startRadius: 6, endRadius: 60)
                )
            // Dimples grid
            DimplesPattern()
                .clipShape(Circle())
                .opacity(fillColor == .white ? 0.35 : 0.15)
        }
    }
}

struct DimplesPattern: View {
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let step: CGFloat = max(6, min(size.width, size.height) / 8)
            Path { p in
                var y: CGFloat = step * 0.6
                var row = 0
                while y < size.height {
                    let offset = (row % 2 == 0) ? 0 : step / 2
                    var x: CGFloat = step * 0.6 + offset
                    while x < size.width {
                        p.addEllipse(in: CGRect(x: x - 1.2, y: y - 1.2, width: 2.4, height: 2.4))
                        x += step
                    }
                    row += 1
                    y += step * 0.85
                }
            }
            .fill(Color.black.opacity(0.15))
        }
    }
}


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
    private let voiceEngine: VoiceEngine

    // Playback rate state mirrored for UI label
    @Published var playbackRateLabel: String = "0.5x"
    private var currentRateIndex = 1 // 0:0.25, 1:0.5, 2:1.0
    private let rates: [String] = ["0.25x","0.5x","1.0x"]

    func togglePlaybackRate() {
        currentRateIndex = (currentRateIndex + 1) % rates.count
        playbackRateLabel = rates[currentRateIndex]
    }

    init() {
        let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String
        if let key, !key.isEmpty {
            self.voiceEngine = OpenAIVoiceEngine(apiKey: key)
        } else {
            self.voiceEngine = SystemTTSVoiceEngine()
        }
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
    private func bestVoice(locale: String = "en-US") -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == locale }
        let ranked = voices.sorted { a, b in
            let qa = a.quality.rawValue, qb = b.quality.rawValue
            if qa != qb { return qa > qb } // premium > enhanced > default
            return (a.name.contains("Siri") ? 1 : 0) > (b.name.contains("Siri") ? 1 : 0)
        }
        return ranked.first ?? AVSpeechSynthesisVoice(language: locale)
    }

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
protocol VoiceEngine {
    func speak(_ text: String)
}

final class SystemTTSVoiceEngine: VoiceEngine {
    private let synthesizer = AVSpeechSynthesizer()
    private func bestVoice(locale: String = "en-US") -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == locale }
        let ranked = voices.sorted { a, b in
            let qa = a.quality.rawValue, qb = b.quality.rawValue
            if qa != qb { return qa > qb }
            return (a.name.contains("Siri") ? 1 : 0) > (b.name.contains("Siri") ? 1 : 0)
        }
        return ranked.first ?? AVSpeechSynthesisVoice(language: locale)
    }
    func speak(_ text: String) {
        let parts = text.split(separator: "\n").map(String.init)
        for (i, p) in parts.enumerated() {
            let u = AVSpeechUtterance(string: p)
            u.voice = bestVoice() ?? AVSpeechSynthesisVoice(language: "en-US")
            u.rate = 0.44
            u.pitchMultiplier = 1.05
            u.preUtteranceDelay = i == 0 ? 0.05 : 0.12
            u.postUtteranceDelay = 0.10
            synthesizer.speak(u)
        }
    }
}

final class OpenAIVoiceEngine: NSObject, VoiceEngine, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private let apiKey: String?
    private let voice: String
    private let model: String
    init(apiKey: String?, voice: String = "alloy", model: String = "tts-1") {
        self.apiKey = apiKey
        self.voice = voice
        self.model = model
    }
    func speak(_ text: String) {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            SystemTTSVoiceEngine().speak(text)
            return
        }
        Task { await requestAndPlay(text: text, apiKey: apiKey) }
    }
    private func requestAndPlay(text: String, apiKey: String) async {
        guard let url = URL(string: "https://api.openai.com/v1/audio/speech") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "model": model,
            "voice": voice,
            "input": text,
            "format": "mp3"
        ]
        
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            try await MainActor.run {
                self.player = try? AVAudioPlayer(data: data)
                self.player?.delegate = self
                self.player?.prepareToPlay()
                self.player?.play()
            }
        } catch {
            print("OpenAI TTS failed: \(error), falling back to system voice")
            SystemTTSVoiceEngine().speak(text)
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio decode error: \(error?.localizedDescription ?? "unknown")")
        self.player = nil
    }
}

// =============================================================
// File: SwingAnalyzer.swift (Vision pose scaffolding + overlay model)
// =============================================================
import Vision

// MARK: - Analysis Models
struct AnalysisResult {
    let tempo: TempoMetric
    let plane: PlaneMetric
    let sway: SwayMetric
    let confidence: Float
    let processingTime: TimeInterval
    
    var summaryChip: String {
        let tempoStr = String(format: "%.1f:1", tempo.ratio)
        let planeStr = String(format: "%.0f°", plane.angleAtTop)
        let swayStr = String(format: "%+.0fcm", sway.deltaCm)
        return "Tempo \(tempoStr) • Plane \(planeStr) • Sway \(swayStr)"
    }
}

struct TempoMetric {
    let backswingTime: TimeInterval
    let downswingTime: TimeInterval
    let ratio: Float
    
    var isGood: Bool { ratio >= 2.5 && ratio <= 3.5 }
    var feedback: String {
        if ratio < 2.5 { return "Too fast on the way down" }
        if ratio > 3.5 { return "Slow down your transition" }
        return "Good tempo rhythm"
    }
}

struct PlaneMetric {
    let angleAtTop: Float // degrees from horizontal
    var isSteep: Bool { angleAtTop > 60 }
    var isFlat: Bool { angleAtTop < 45 }
    
    var feedback: String {
        if isSteep { return "Shaft too steep at top" }
        if isFlat { return "Shaft too flat at top" }
        return "Good shaft angle"
    }
}

struct SwayMetric {
    let startX: Float
    let impactX: Float
    let deltaCm: Float // positive = sway right, negative = sway left
    
    var isExcessive: Bool { abs(deltaCm) > 8 }
    var feedback: String {
        if deltaCm > 8 { return "Too much rightward hip sway" }
        if deltaCm < -8 { return "Too much leftward hip sway" }
        return "Good hip stability"
    }
}

struct SwingPose {
    let joints: [VNHumanBodyPoseObservation.JointName: CGPoint] // normalized [0,1]
    
    init(from observation: VNHumanBodyPoseObservation) {
        var map: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        
        let allJoints: [VNHumanBodyPoseObservation.JointName] = [
            .neck, .rightShoulder, .rightElbow, .rightWrist,
            .leftShoulder, .leftElbow, .leftWrist,
            .root, .rightHip, .rightKnee, .rightAnkle,
            .leftHip, .leftKnee, .leftAnkle
        ]
        
        for joint in allJoints {
            if let point = try? observation.recognizedPoint(joint), point.confidence > 0.2 {
                map[joint] = CGPoint(x: CGFloat(point.x), y: CGFloat(1 - point.y))
            }
        }
        
        self.joints = map
    }
}

@MainActor
final class SwingAnalyzer: ObservableObject {
    @Published var currentPose: SwingPose?
    @Published var isAnalyzing: Bool = false
    @Published var lastAnalysis: AnalysisResult?
    
    private let request = VNDetectHumanBodyPoseRequest()
    private let handlerQueue = DispatchQueue(label: "swing.analyzer.queue", qos: .userInitiated)
    private var lastProcessTime: CFTimeInterval = 0
    private let throttle: CFTimeInterval = 1.0 / 12.0 // ~12 fps for live view
    
    // MARK: - Live Pose Processing
    func process(sampleBuffer: CMSampleBuffer) {
        let now = CACurrentMediaTime()
        if now - lastProcessTime < throttle { return }
        lastProcessTime = now
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        
        handlerQueue.async {
            do {
                try handler.perform([self.request])
                guard let obs = self.request.results?.first as? VNHumanBodyPoseObservation else { return }
                
                let pose = SwingPose(from: obs)
                DispatchQueue.main.async {
                    self.currentPose = pose
                }
            } catch { /* ignore for MVP */ }
        }
    }
    
    // MARK: - Recorded Clip Analysis
    func analyzeRecordedClip(url: URL) async -> AnalysisResult? {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        let startTime = CACurrentMediaTime()
        
        do {
            let asset = AVAsset(url: url)
            let duration = try await asset.load(.duration)
            let durationSeconds = CMTimeGetSeconds(duration)
            
            // Sample 24 frames evenly across the swing
            let frameCount = 24
            let frameInterval = durationSeconds / Double(frameCount - 1)
            
            var poses: [SwingPose] = []
            var times: [TimeInterval] = []
            
            for i in 0..<frameCount {
                let time = Double(i) * frameInterval
                let cmTime = CMTime(seconds: time, preferredTimescale: 600)
                
                if let pose = try await extractPose(from: asset, at: cmTime) {
                    poses.append(pose)
                    times.append(time)
                }
            }
            
            guard poses.count >= 12 else { return nil } // Need minimum frames
            
            // Calculate metrics
            let tempo = calculateTempo(poses: poses, times: times)
            let plane = calculatePlane(poses: poses, times: times)
            let sway = calculateSway(poses: poses, times: times)
            
            let confidence = Float(poses.count) / Float(frameCount)
            let processingTime = CACurrentMediaTime() - startTime
            
            let result = AnalysisResult(
                tempo: tempo,
                plane: plane,
                sway: sway,
                confidence: confidence,
                processingTime: processingTime
            )
            
            lastAnalysis = result
            return result
            
        } catch {
            print("Analysis failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Private Analysis Methods
    private func extractPose(from asset: AVAsset, at time: CMTime) async throws -> SwingPose? {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        
        let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
        let ciImage = CIImage(cgImage: cgImage)
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        try handler.perform([request])
        
        guard let obs = request.results?.first as? VNHumanBodyPoseObservation else { return nil }
        return SwingPose(from: obs)
    }
    
    private func calculateTempo(poses: [SwingPose], times: [TimeInterval]) -> TempoMetric {
        // Find backswing top (highest hands position)
        var maxHandY: Float = 0
        var topIndex = 0
        
        for (i, pose) in poses.enumerated() {
            let handY = (pose.joints[.leftWrist]?.y ?? 0) + (pose.joints[.rightWrist]?.y ?? 0) / 2
            if handY > maxHandY {
                maxHandY = handY
                topIndex = i
            }
        }
        
        let backswingTime = times[topIndex]
        let downswingTime = times.last! - backswingTime
        let ratio = Float(backswingTime / downswingTime)
        
        return TempoMetric(
            backswingTime: backswingTime,
            downswingTime: downswingTime,
            ratio: ratio
        )
    }
    
    private func calculatePlane(poses: [SwingPose], times: [TimeInterval]) -> PlaneMetric {
        // Find top of backswing (highest hands)
        var maxHandY: Float = 0
        var topIndex = 0
        
        for (i, pose) in poses.enumerated() {
            let handY = (pose.joints[.leftWrist]?.y ?? 0) + (pose.joints[.rightWrist]?.y ?? 0) / 2
            if handY > maxHandY {
                maxHandY = handY
                topIndex = i
            }
        }
        
        let topPose = poses[topIndex]
        
        // Calculate shaft angle from shoulder to hands
        guard let leftShoulder = topPose.joints[.leftShoulder],
              let leftWrist = topPose.joints[.leftWrist] else {
            return PlaneMetric(angleAtTop: 45) // Default
        }
        
        let dx = leftWrist.x - leftShoulder.x
        let dy = leftWrist.y - leftShoulder.y
        let angle = atan2(dy, dx) * 180 / .pi
        
        return PlaneMetric(angleAtTop: Float(angle))
    }
    
    private func calculateSway(poses: [SwingPose], times: [TimeInterval]) -> SwayMetric {
        guard let startPose = poses.first,
              let impactPose = poses.last,
              let startHip = startPose.joints[.root],
              let impactHip = impactPose.joints[.root] else {
            return SwayMetric(startX: 0, impactX: 0, deltaCm: 0)
        }
        
        // Convert normalized coordinates to approximate cm
        // Assuming 1.0 = ~100cm for typical swing view
        let startX = startHip.x * 100
        let impactX = impactHip.x * 100
        let deltaCm = (impactX - startX) * 100 // Convert to cm
        
        return SwayMetric(startX: startX, impactX: impactX, deltaCm: deltaCm)
    }
    
    // MARK: - Coaching Feedback
    func getCoachingFeedback(for result: AnalysisResult) -> (cue: String, drill: String) {
        var cues: [String] = []
        var drills: [String] = []
        
        // Tempo feedback
        if !result.tempo.isGood {
            cues.append(result.tempo.feedback)
            if result.tempo.ratio < 2.5 {
                drills.append("Count 1-2 to top, 3 through impact")
            } else {
                drills.append("Pause at top for 1 count")
            }
        }
        
        // Plane feedback
        if result.plane.isSteep || result.plane.isFlat {
            cues.append(result.plane.feedback)
            drills.append("Practice half-swings with alignment stick")
        }
        
        // Sway feedback
        if result.sway.isExcessive {
            cues.append(result.sway.feedback)
            drills.append("Keep trail hip back through impact")
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
}

// PoseOverlayView removed - replaced by OverlayEditor
// =============================================================
// File: StorageManager.swift (local videos + thumbnails)
// =============================================================
import UIKit
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
final class ShareExportManager {
    func exportWithCaption(videoURL: URL, caption: String, completion: @escaping (URL?) -> Void) {
        let asset = AVAsset(url: videoURL)
        let mixComposition = AVMutableComposition()
        guard
            let assetVideoTrack = asset.tracks(withMediaType: .video).first,
            let compVideoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        else { completion(nil); return }
        do {
            try compVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: assetVideoTrack, at: .zero)
        } catch { completion(nil); return }

        // Video composition with CoreAnimation overlay
        let videoSize = assetVideoTrack.naturalSize
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: videoSize)
        videoLayer.frame = parentLayer.frame
        parentLayer.addSublayer(videoLayer)

        let textLayer = CATextLayer()
        textLayer.string = caption
        textLayer.font = UIFont.boldSystemFont(ofSize: 20)
        textLayer.fontSize = 20
        textLayer.alignmentMode = .center
        textLayer.foregroundColor = UIColor.white.cgColor
        textLayer.shadowColor = UIColor.black.cgColor
        textLayer.shadowOpacity = 0.6
        textLayer.shadowRadius = 4
        let margin: CGFloat = 24
        textLayer.frame = CGRect(x: margin, y: 20, width: videoSize.width - margin*2, height: 60)
        textLayer.contentsScale = UIScreen.main.scale
        parentLayer.addSublayer(textLayer)

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compVideoTrack)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)

        let outputURL = StorageManager.shared.newVideoURL().deletingPathExtension().appendingPathExtension("mp4")
        if FileManager.default.fileExists(atPath: outputURL.path) { try? FileManager.default.removeItem(at: outputURL) }

        guard let export = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else { completion(nil); return }
        export.videoComposition = videoComposition
        export.outputURL = outputURL
        export.outputFileType = .mp4
        export.exportAsynchronously {
            DispatchQueue.main.async { completion(export.status == .completed ? outputURL : nil) }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
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
