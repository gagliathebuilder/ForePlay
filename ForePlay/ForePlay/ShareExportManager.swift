import Foundation
import AVFoundation
import UIKit
import SwiftUI

enum ShareExportManager {
    static func exportWithOverlays(source url: URL, caption: String, completion: @escaping (URL?) -> Void) {
        // MVP: just forward original url for now; later draw burn-ins via AVVideoCompositionCoreAnimationTool
        DispatchQueue.main.async { completion(url) }
    }

    static func presentShareSheet(url: URL, from vc: UIViewController) {
        let ac = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        vc.present(ac, animated: true)
    }
    
    struct ShareSheet: UIViewControllerRepresentable {
        let activityItems: [Any]
        
        func makeUIViewController(context: Context) -> UIActivityViewController {
            UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        }
        
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
            // Nothing to update
        }
    }
}
