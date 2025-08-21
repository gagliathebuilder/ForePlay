import AVFoundation
import Vision

struct AnalysisResult {
    let tempoRatio: Double?     // ~3:1 target
    let shaftPlaneDeg: Double?  // deviation at top
    let hipSwayCm: Double?      // +right / -left vs setup
    var formatted: String {
        [
            tempoRatio.map { String(format: "Tempo %.1f:1", $0) },
            shaftPlaneDeg.map { String(format: "Plane %.0f°", $0) },
            hipSwayCm.map { String(format: "Sway %.0fcm", $0) }
        ].compactMap { $0 }.joined(separator: " • ")
    }
}

enum AnalysisKit {
    static func analyze(url: URL, frameCount: Int = 24) async -> AnalysisResult {
        let asset = AVURLAsset(url: url)
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        let duration = CMTimeGetSeconds(asset.duration)
        guard duration > 0 else { return AnalysisResult(tempoRatio: nil, shaftPlaneDeg: nil, hipSwayCm: nil) }

        let times: [NSValue] = (0..<frameCount).map { i in
            NSValue(time: CMTime(seconds: Double(i) / Double(frameCount - 1) * duration, preferredTimescale: 600))
        }

        var samples: [(t: Double, obs: VNRecognizedPointsObservation?)] = []
        for tv in times {
            if let cg = try? gen.copyCGImage(at: tv.timeValue) {
                let req = VNDetectHumanBodyPoseRequest()
                let handler = VNImageRequestHandler(cgImage: cg, options: [:])
                try? handler.perform([req])
                samples.append((CMTimeGetSeconds(tv.timeValue), req.results?.first))
            }
        }

        // Tempo via left wrist height curve (very rough placeholder)
        let ys: [(Double, Double)] = samples.compactMap { (t, o) in
            guard let p = try? o?.recognizedPoint(.leftWrist), p?.confidence ?? 0 > 0.3 else { return nil }
            return (t, p!.location.y)
        }
        let start = ys.first?.0
        let top = ys.max(by: { $0.1 < $1.1 })?.0
        let impact = ys.last?.0
        let tempo = (start != nil && top != nil && impact != nil) ? ((top! - start!) / max(impact! - top!, 0.001)) : nil

        // Plane: angle between lead shoulder -> hands at top vs horizontal
        var plane: Double? = nil
        if let (_, topObs) = samples.max(by: {
            let ya = (try? $0.obs?.recognizedPoint(.leftWrist)?.location.y) ?? 0
            let yb = (try? $1.obs?.recognizedPoint(.leftWrist)?.location.y) ?? 0
            return ya < yb
        }), let obs = topObs,
           let shoulder = try? obs.recognizedPoint(.leftShoulder),
           let hands = try? obs.recognizedPoint(.leftWrist),
           shoulder.confidence > 0.3, hands.confidence > 0.3 {
            let dx = Double(hands.location.x - shoulder.location.x)
            let dy = Double(hands.location.y - shoulder.location.y)
            plane = atan2(dy, dx) * 180.0 / .pi
        }

        // Hip sway: pelvis x start → impact
        let pelvisStartX = try? samples.first??.recognizedPoint(.root)?.location.x
        let pelvisImpactX = try? samples.last??.recognizedPoint(.root)?.location.x
        let sway = (pelvisStartX != nil && pelvisImpactX != nil) ? Double(pelvisImpactX! - pelvisStartX!) * 100.0 : nil

        return AnalysisResult(tempoRatio: tempo, shaftPlaneDeg: plane, hipSwayCm: sway)
    }
}
