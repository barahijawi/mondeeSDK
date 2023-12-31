
import UIKit

class DataSource: UITableViewDiffableDataSource<SingleSection, BookmarkedPage> {
    // Enables swipe functionality on cells
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}

typealias Snapshot = NSDiffableDataSourceSnapshot<SingleSection, BookmarkedPage>

class BookmarksViewController: UIViewController {
    private lazy var headerStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Bookmarks"
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        return label
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(BookmarkTableViewCell.self, forCellReuseIdentifier: BookmarkTableViewCell.reuseIdentifier)
        table.separatorStyle = .singleLine
        table.delegate = self
        return table
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton()
        button.setTitle("Done", for: .normal)
        button.setTitleColor(.link, for: .normal)
        button.addTarget(self, action: #selector(donePressed), for: .touchUpInside)
        return button
    }()
    
    private lazy var divider: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .separator
        return view
    }()
    
    private lazy var dataSource = makeDataSource()
    
    private lazy var bookmarks: [BookmarkedPage] = {
        if let data = UserDefaults.standard.data(forKey: "bookmarks"), let bookmarks = try? JSONDecoder().decode([BookmarkedPage].self, from: data) {
            return bookmarks
        }
        return [BookmarkedPage]()
    }()
    
    weak var delegate: BrowserViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Favorites"
        view.backgroundColor = .white
        
        setupViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        applySnapshot()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        headerStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
        headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        
        divider.topAnchor.constraint(equalTo: headerStack.bottomAnchor).isActive = true
        divider.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        tableView.topAnchor.constraint(equalTo: divider.bottomAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    private func setupViews() {
        view.addSubview(tableView)
        view.addSubview(headerStack)
        view.addSubview(divider)
        tableView.dataSource = dataSource
        
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(doneButton)
    }
    
    private func makeDataSource() -> DataSource {
        let dataSource = DataSource(tableView: tableView, cellProvider: { (tableView, indexPath, bookmark) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: BookmarkTableViewCell.reuseIdentifier, for: indexPath) as? BookmarkTableViewCell
            cell?.populateCell(bookmark)
            return cell
        })
        return dataSource
    }
    
    
    private func applySnapshot() {
        var snapshot = Snapshot()
        snapshot.appendSections(SingleSection.allCases)
        snapshot.appendItems(bookmarks)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    @objc func donePressed() {
        dismiss(animated: true, completion: nil)
    }
}

extension BookmarksViewController: UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return delegate?.tabManager.tabs.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let bookmark = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        // Loads selected bookmark
        delegate?.updateWebViewContent(url: bookmark.url.absoluteString)
        
        // Adds selected page to history
        delegate?.tabManager.selectedTab.addPageToHistory(url: bookmark.url.absoluteString)
        
        // Pop back to the browser VC
        dismiss(animated: true, completion: nil)
    }
    
    // Enables user to swipe to delete a bookmark
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completionHandler in
            // If there are other bookmarks saved, decode them, remove the bookmark and save the updated array
            if let data = UserDefaults.standard.data(forKey: "bookmarks"),
                var bookmarkedPages = try? JSONDecoder().decode([BookmarkedPage].self, from: data) {
                bookmarkedPages.remove(at: indexPath.row)
                let data = try? JSONEncoder().encode(bookmarkedPages)
                UserDefaults.standard.setValue(data, forKey: "bookmarks")
            } else { // Otherwise delete the saved bookmark
                UserDefaults.standard.removeObject(forKey: "bookmarks")
            }
            
            self.bookmarks.remove(at: indexPath.row)
            self.applySnapshot()
            
            completionHandler(true)
        }
        deleteAction.backgroundColor = .red
        deleteAction.image = UIImage(systemName: "trash")
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}
