import SwiftUI

struct OverlayEditor: View {
    @AppStorage("targetLineY") private var targetLineY: Double = 0.65
    @AppStorage("planeStartX") private var planeStartX: Double = 0.10
    @AppStorage("planeStartY") private var planeStartY: Double = 0.85
    @AppStorage("planeEndX")   private var planeEndX:   Double = 0.90
    @AppStorage("planeEndY")   private var planeEndY:   Double = 0.40

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Target line
                Rectangle()
                    .fill(Color.fpGreen.opacity(0.9))
                    .frame(height: 2)
                    .position(x: geo.size.width/2, y: geo.size.height * targetLineY)
                    .gesture(DragGesture()
                        .onChanged { g in targetLineY = min(0.95, max(0.05, Double(g.location.y / geo.size.height))) })

                // Swing plane
                Path { p in
                    let s = CGPoint(x: geo.size.width * planeStartX, y: geo.size.height * planeStartY)
                    let e = CGPoint(x: geo.size.width * planeEndX,   y: geo.size.height * planeEndY)
                    p.move(to: s); p.addLine(to: e)
                }
                .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6,6]))

                // Drag handles
                handle(at: CGPoint(x: geo.size.width * planeStartX, y: geo.size.height * planeStartY))
                    .gesture(DragGesture().onChanged { g in
                        planeStartX = min(0.98, max(0.02, Double(g.location.x / geo.size.width)))
                        planeStartY = min(0.98, max(0.02, Double(g.location.y / geo.size.height)))
                    })
                handle(at: CGPoint(x: geo.size.width * planeEndX, y: geo.size.height * planeEndY))
                    .gesture(DragGesture().onChanged { g in
                        planeEndX = min(0.98, max(0.02, Double(g.location.x / geo.size.width)))
                        planeEndY = min(0.98, max(0.02, Double(g.location.y / geo.size.height)))
                    })
            }
        }
        .allowsHitTesting(true)
    }

    private func handle(at point: CGPoint) -> some View {
        Circle()
            .fill(.ultraThinMaterial)
            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
            .frame(width: 24, height: 24)
            .position(point)
            .shadow(radius: 3)
            .accessibilityHidden(true)
    }
}

// MARK: - Extensions


// MARK: - Preview
#if DEBUG
struct OverlayEditor_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            OverlayEditor()
        }
        .frame(width: 400, height: 600)
    }
}
#endif
