import SwiftUI

struct GolfMicButton: View {
    var isListening: Bool
    var onPressStart: () -> Void
    var onPressEnd: () -> Void

    @State private var pressed = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.white, Color(white: 0.88)]),
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(dimplePattern.opacity(0.25).clipShape(Circle()))
                    .overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 1))
                    .scaleEffect(pressed ? 0.92 : 1.0)
                    .shadow(radius: 10)
                Image(systemName: isListening ? "waveform.circle.fill" : "mic.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(isListening ? .red : .fpNavy)
            }
            .frame(width: 84, height: 84)
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !pressed { pressed = true; onPressStart(); UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
                }
                .onEnded { _ in
                    pressed = false; onPressEnd()
                })

            Text(isListening ? "Listening…" : "Hold to talk")
                .font(.caption.bold())
                .foregroundColor(.white)
        }
        .accessibilityLabel("Hold to talk to CaDi")
    }

    private var dimplePattern: some View {
        GeometryReader { geo in
            let r: CGFloat = 4
            let spacing: CGFloat = 10
            let cols = Int(geo.size.width / spacing)
            let rows = Int(geo.size.height / spacing)
            ForEach(0..<(rows*cols), id: \.self) { i in
                let x = CGFloat(i % cols) * spacing + r/2
                let y = CGFloat(i / cols) * spacing + r/2
                Circle().fill(Color.black.opacity(0.08)).frame(width: r, height: r).position(x: x, y: y)
            }
        }
    }
}

// MARK: - Extensions
extension Color {
    static let fpNavy = Color(red: 0.043, green: 0.145, blue: 0.271)
}

// MARK: - Preview
#if DEBUG
struct GolfMicButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            GolfMicButton(
                isListening: false,
                onPressStart: {},
                onPressEnd: {}
            )
        }
    }
}
#endif
