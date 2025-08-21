import SwiftUI
import AVKit

struct ComparisonView: View {
    let left: URL
    let right: URL
    @State private var leftPlayer = AVPlayer()
    @State private var rightPlayer = AVPlayer()

    var body: some View {
        VStack {
            HStack {
                VideoPlayer(player: leftPlayer).frame(maxWidth: .infinity, maxHeight: 260)
                VideoPlayer(player: rightPlayer).frame(maxWidth: .infinity, maxHeight: 260)
            }
            Slider(value: Binding(
                get: { leftPlayer.currentTime().seconds },
                set: { t in
                    let time = CMTime(seconds: t, preferredTimescale: 600)
                    leftPlayer.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
                    rightPlayer.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
                }
            ), in: 0...(max(leftPlayer.currentItem?.asset.duration.seconds ?? 0,
                             rightPlayer.currentItem?.asset.duration.seconds ?? 0)))
            .padding()
        }
        .onAppear {
            leftPlayer.replaceCurrentItem(with: AVPlayerItem(url: left))
            rightPlayer.replaceCurrentItem(with: AVPlayerItem(url: right))
        }
    }
}
