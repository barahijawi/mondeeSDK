
import Foundation

// MARK: BookmarkedPage - This represents a bookmarked page
class BookmarkedPage: Codable, Hashable {
    var title: String
    var url: URL
    
    init(title: String, url: URL) {
        self.title = title
        self.url = url
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(url)
    }

    static func == (lhs: BookmarkedPage, rhs: BookmarkedPage) -> Bool {
        return lhs.title == rhs.title && rhs.url == lhs.url
    }
}

// Convenience functions to store bookmarks from UserDefaults
extension BookmarkedPage {
    func storeBookmark() {
        // If there are other bookmarks saved, decode them, add the new bookmark and save the updated array
        if let data = UserDefaults.standard.data(forKey: "bookmarks"),
            var bookmarkedPages = try? JSONDecoder().decode([BookmarkedPage].self, from: data) {
            bookmarkedPages.append(self)
            let data = try? JSONEncoder().encode(bookmarkedPages)
            UserDefaults.standard.setValue(data, forKey: "bookmarks")
        } else { // Otherwise save the new bookmark in an array
            let data = try? JSONEncoder().encode([self])
            UserDefaults.standard.setValue(data, forKey: "bookmarks")
        }
    }
}
