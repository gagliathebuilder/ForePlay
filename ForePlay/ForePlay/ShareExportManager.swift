import Foundation
import AVFoundation
import UIKit

enum ShareExportManager {
    static func exportWithOverlays(source url: URL, caption: String, completion: @escaping (URL?) -> Void) {
        // MVP: just forward original url for now; later draw burn-ins via AVVideoCompositionCoreAnimationTool
        DispatchQueue.main.async { completion(url) }
    }

    static func presentShareSheet(url: URL, from vc: UIViewController) {
        let ac = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        vc.present(ac, animated: true)
    }
}
