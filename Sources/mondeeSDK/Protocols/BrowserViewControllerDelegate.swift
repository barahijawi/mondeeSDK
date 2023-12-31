

import UIKit
import WebKit

// MARK: - BrowserViewControllerDelegate: This delegate is used by the browser view to call the button press actions
@objc protocol BrowserViewControllerDelegate: WKNavigationDelegate, UITextFieldDelegate {
    // References from our BrowserView buttons
    @objc func reloadPage()
    @objc func forwardPressed()
    @objc func backPressed()
    @objc func tabPressed()
    @objc func newTabPressed()
    @objc func bookmarksPressed()
    @objc func sharePressed()
    func updateWebViewContent(url: String)
    var tabManager: TabManager { get }
}
