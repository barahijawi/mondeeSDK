import SwiftUI


public struct BrowserViewControllerWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = BrowserViewController

    func makeUIViewController(context: Context) -> BrowserViewController {
        return BrowserViewController(TabManager())
    }

    func updateUIViewController(_ uiViewController: BrowserViewController, context: Context) {
        // Update the view controller if needed
    }
}
