
import Foundation

// MARK: - TabViewControllerDelegate: This delegate communicates to the TabVC to TabTableViewCell
protocol TabViewControllerDelegate {
    func removeTab(index: Int)
}
