import SwiftUI

struct VoiceStateChip: View {
    var listening: Bool
    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(spacing: 6) {
            if listening {
                Rectangle()
                    .frame(width: 2, height: 10 + 6 * sin(phase))
                    .animation(.linear(duration: 0.18), value: phase)
                    .onAppear { withAnimation(.linear(duration: 0.18).repeatForever(autoreverses: true)) { phase += .pi } }
                Rectangle().frame(width: 2, height: 12)
                Rectangle()
                    .frame(width: 2, height: 10 + 6 * sin(phase + .pi/2))
            } else {
                Image(systemName: "dot.radiowaves.left.and.right")
            }
            Text(listening ? "Listening…" : "CaDi ready")
        }
        .font(.footnote.weight(.semibold))
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .foregroundColor(.white)
    }
}

// MARK: - Preview
#if DEBUG
struct VoiceStateChip_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            VStack(spacing: 20) {
                VoiceStateChip(listening: false)
                VoiceStateChip(listening: true)
            }
        }
    }
}
#endif
