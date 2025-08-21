import Foundation
import AVFoundation

enum VoiceEngine {
    static func speak(_ text: String) {
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
           !apiKey.trimmingCharacters(in: .whitespaces).isEmpty {
            Task { await speakOpenAI(text: text, apiKey: apiKey) }
        } else {
            speakLocal(text)
        }
    }

    private static func speakLocal(_ text: String) {
        let parts = text.split(separator: "\n").map(String.init)
        let synth = AVSpeechSynthesizer()
        let best = bestVoice() ?? AVSpeechSynthesisVoice(language: "en-US")
        for (i, p) in parts.enumerated() {
            let u = AVSpeechUtterance(string: p)
            u.voice = best
            u.rate = 0.44
            u.pitchMultiplier = 1.05
            u.preUtteranceDelay = i == 0 ? 0.05 : 0.12
            u.postUtteranceDelay = 0.10
            synth.speak(u)
        }
    }

    private static func bestVoice(locale: String = "en-US") -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == locale }
        return voices.sorted { a, b in
            let qa = a.quality.rawValue, qb = b.quality.rawValue
            if qa != qb { return qa > qb }        // premium > enhanced > default
            return (a.name.contains("Siri") ? 1:0) > (b.name.contains("Siri") ? 1:0)
        }.first
    }

    private static func buildTTSRequest(text: String, apiKey: String) -> URLRequest {
        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/speech")!)
        req.httpMethod = "POST"
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": "gpt-4o-mini-tts",
            "voice": "alloy",     // can be customized
            "input": text,
            "format": "mp3"
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return req
    }

    private static func playAudioData(_ data: Data) {
        // Simple playback; keep a strong reference externally if needed
        _ = try? AVAudioSession.sharedInstance().setCategory(.playback)
        let player = try? AVAudioPlayer(data: data)
        player?.prepareToPlay()
        player?.play()
        // NOTE: keep 'player' retained on a singleton if you cut audio early
    }

    private static func handleTTSError(_ text: String) {
        // Fallback to local voice on any error
        speakLocal(text)
    }

    static func speakOpenAI(text: String, apiKey: String) async {
        do {
            let req = buildTTSRequest(text: text, apiKey: apiKey)
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            playAudioData(data)
        } catch {
            handleTTSError(text)
        }
    }
}
