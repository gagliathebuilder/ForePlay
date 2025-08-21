import SwiftUI

struct TeeRecordButton: View {
    var isRecording: Bool
    var onTap: () -> Void
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if isRecording {
                    Circle()
                        .stroke(Color.red.opacity(0.7), lineWidth: 3)
                        .frame(width: 94, height: 94)
                        .scaleEffect(pulse ? 1.08 : 0.96)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
                        .onAppear { pulse = true }
                }
                teeShape
                    .fill(isRecording ? Color.red : Color.fpGreen)
                    .overlay(teeShape.stroke(Color.white.opacity(0.9), lineWidth: 2))
                    .frame(width: 84, height: 84)
                    .shadow(radius: 10)
            }
            .contentShape(Rectangle())
            .onTapGesture { onTap() }

            Text(isRecording ? "Stop" : "Record")
                .font(.caption.bold())
                .foregroundColor(.white)
        }
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
    }

    private var teeShape: Path {
        var p = Path()
        // simple tee silhouette: head + stem
        p.addRoundedRect(in: CGRect(x: 22, y: 12, width: 40, height: 26), cornerSize: CGSize(width: 12, height: 12))
        p.move(to: CGPoint(x: 42, y: 38))
        p.addLine(to: CGPoint(x: 42, y: 76))
        p.addLine(to: CGPoint(x: 46, y: 76))
        p.addLine(to: CGPoint(x: 46, y: 38))
        return p
    }
}

// MARK: - Extensions


// MARK: - Preview
#if DEBUG
struct TeeRecordButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            VStack(spacing: 20) {
                TeeRecordButton(
                    isRecording: false,
                    onTap: {}
                )
                TeeRecordButton(
                    isRecording: true,
                    onTap: {}
                )
            }
        }
    }
}
#endif
