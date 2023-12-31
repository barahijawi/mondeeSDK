
import UIKit
import WebKit

public class BrowserViewController: UIViewController{
    
    // This view contains all of the UI elements of the BrowserViewController
    private lazy var browserView: BrowserView = {
        let view = BrowserView()
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    // Create a loading view
        private let loadingView: UIActivityIndicatorView = {
            let view = UIActivityIndicatorView(style: .large)
            view.color = .gray
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }()
    // An array of domain extensions used to deduce if a user is searching for specific url or wants to search by keyword
    // Ideally this would be have a more robust deduction of whether a user is looking to use a search engine vs.
    // Manually adding a site by URL
    private lazy var domainExtensions: [String] = {
        if let path = Bundle.main.path(forResource: "DomainExtensions", ofType: "txt") {
            do {
                let data = try String(contentsOfFile: path, encoding: .utf8)
                return data.components(separatedBy: .newlines).map { $0.lowercased() }
            } catch {
                print(error)
            }
        }
        return [ ".com", ".net", ".org", ".co" ]
    }()
    
    public var tabManager: TabManager
    
    @objc public func newWindowButtonPressed() {
           // Create a new browser window with one tab
           let tabManager = TabManager() // Initialize a new TabManager
           let newBrowserViewController = BrowserViewController(tabManager) // Initialize a new BrowserViewController with the TabManager

           // Optionally, you can customize the appearance of the new window
           newBrowserViewController.view.backgroundColor = .white // Example background color

           navigationController?.pushViewController(newBrowserViewController, animated: true)
       }
    public func openNewTab() {
        tabManager.newTab(url: "https://google.com")
        reloadPage()
    }

   public init(_ tabManager: TabManager) {
        self.tabManager = tabManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the default url
        if let url = URL(string: tabManager.homePage) {
            browserView.urlTextField.text = url.absoluteString
            browserView.webView.load(URLRequest(url: url))
        }
        
   
        // Add the browser view
        view.addSubview(browserView)
        view.addSubview(loadingView)
        loadingView.center = view.center

    }
    
    // When this view controller is presented, hide the nav bar to maximize screen real estate
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // When this view controller disappears, enable the navigation bar
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Check if the back button should be enabled or not (when on new tab, shouldn't be able to go back)
        if tabManager.selectedTab.history.count == 1 || tabManager.selectedTab.historyIndex == 0 {
            browserView.backButton.isEnabled = false
        } else {
            browserView.backButton.isEnabled = true
        }
        // Check if the forward button should be enabled or not (when on most recent page, shouldn't be able to go forward)
        if tabManager.selectedTab.history.count - 1 == tabManager.selectedTab.historyIndex {
            browserView.forwardButton.isEnabled = false
        } else {
            browserView.forwardButton.isEnabled = true
        }
        
        browserView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        browserView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        browserView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        browserView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    // Updates webView's content and updates the user input textfield
    func updateWebViewContent(url: String) {
        if let url = URL(string: url) {
            browserView.webView.load(URLRequest(url: url))
        } else {
            browserView.webView.load(URLRequest(url: URL(string: tabManager.homePage)!))
        }
        browserView.urlTextField.text = url
    }
}

// MARK: - BrowserViewControllerDelegate methods, used to handle button presses
extension BrowserViewController: BrowserViewControllerDelegate {
    // Reloads the current page
    @objc func reloadPage() {
        updateWebViewContent(url: tabManager.selectedTab.getCurrentPage())
    }
    // Moves forward in the history stack
    @objc func forwardPressed() {
        tabManager.selectedTab.moveForwardHistory()
        updateWebViewContent(url: tabManager.selectedTab.getCurrentPage())
    }
    // Moves backward in the history stack
    @objc func backPressed() {
        tabManager.selectedTab.moveBackHistory()
        updateWebViewContent(url: tabManager.selectedTab.getCurrentPage())
    }
    // Tab manager `VC` is opened
    @objc func tabPressed() {
        let vc = TabViewController()
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    // New tab is added
    @objc func newTabPressed() {
        tabManager.newTab(url: "https://google.com")
        reloadPage()
        navigationController?.popViewController(animated: true)
    }
@objc public func openNewTab(url :String) {
        tabManager.newTab(url: url)
        reloadPage()
        navigationController?.popViewController(animated: true)
    }
    // Bookmarks view controller presented
    @objc func bookmarksPressed() {
        let vc = BookmarksViewController()
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }
    // Share view presented
    @objc func sharePressed() {
        guard let currentUrl = tabManager.selectedTab.getCurrentPageUrl() else { return }
        
        // Allows for the user to add currentUrl to bookmarks
        let bookmarkActivity = BookmarkActivity(title: tabManager.selectedTab.pageTitle, currentUrl: currentUrl)

        let vc = UIActivityViewController(activityItems: [currentUrl], applicationActivities: [bookmarkActivity])
        
        // Excluded certain types of activities to improve performance
        vc.excludedActivityTypes = [ .airDrop, .assignToContact, .markupAsPDF, .openInIBooks, .postToFlickr, .postToTencentWeibo, .saveToCameraRoll, .postToVimeo, .postToWeibo, .print ]
        
        vc.popoverPresentationController?.sourceView = self.browserView
        
        present(vc, animated: true, completion: nil)
    }
}

// MARK: - WKNavigationDelegate methods
extension BrowserViewController: WKNavigationDelegate {
    // Check if the user navigated to a new page from within the webView content (not search bar)
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingView.startAnimating()
        let currentPage = tabManager.selectedTab.getCurrentPage()
        
        if let url = webView.url?.absoluteString, url != currentPage {
            print("User navigated from \(url) to \(currentPage)")
            tabManager.selectedTab.history.append(url)
            tabManager.selectedTab.historyIndex += 1
            browserView.urlTextField.text = url
        }
    }
    
    // Each time a page is done loading, add a snapshot of the content to the tab manager
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if #available(iOS 11.0, *) {
            loadingView.stopAnimating()
                   loadingView.isHidden = true
            webView.takeSnapshot(with: nil, completionHandler: { (image, error) in
                if let snapshotImage = image {
                    self.tabManager.selectedTab.contentSnapshot = snapshotImage
                }
            })
        }
        // Update with the current website title
        tabManager.selectedTab.updatePageTitle(webView.title)
    }
    
    // Handle errors
      public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
          loadingView.stopAnimating()
          loadingView.isHidden = true
      }
}

// MARK: - UITextFieldDelegate methods
extension BrowserViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let url = textField.text {
            var formattedURL = url.lowercased()
            
            // If I were to work on this project longer, I would make a robust Regex to handle user input
            
            // If there is no user input, direct to the home page
            if formattedURL == "" {
                formattedURL = tabManager.homePage
                // If the url does not appear to be a valid web address
            } else if !formattedURL.contains("https://") && !formattedURL.contains("www.") {
                // Check if it was meant to be a valid address (if user did not add https:// or www.) check if it contains a domain extension
                if let pathExtension = URL(string: formattedURL)?.pathExtension, pathExtension != "", domainExtensions.contains(pathExtension) {
                    formattedURL = "https://\(formattedURL)"
                    // Presumed the user wanted to search a keyword
                } else {
                    formattedURL = "http://www.google.com/search?q=\(formattedURL.replacingOccurrences(of: " ", with: "+"))"
                }
            }
            // Make sure all urls end in a '/'
            if !formattedURL.hasSuffix("/") {
                formattedURL = "\(formattedURL)/"
            }
            
            // Add new search to history
            tabManager.selectedTab.addPageToHistory(url: formattedURL)
            // Update web view
            updateWebViewContent(url: formattedURL)
            // Hide keyboard
            browserView.urlTextField.resignFirstResponder()
        }
        return true
    }
}
