import SwiftUI

struct MetricsChip: View {
    var text: String
    var body: some View {
        Text(text.isEmpty ? "Analyzing…" : text)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 0.5))
            .foregroundColor(.white)
            .shadow(radius: 4)
            .accessibilityLabel("Swing metrics")
    }
}

// MARK: - Preview
#if DEBUG
struct MetricsChip_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            VStack(spacing: 20) {
                MetricsChip(text: "Tempo 3.1:1 • Plane 55° • Sway +7cm")
                MetricsChip(text: "Analyzing…")
                MetricsChip(text: "")
            }
        }
    }
}
#endif
