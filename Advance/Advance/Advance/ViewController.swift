//
//  ViewController.swift
//  Advance
//
//  Created by 김재만 on 7/29/25.
//
import UIKit

// MARK: - 모델
struct BookResponse: Codable {
    let documents: [Book]
}

struct Book: Codable, Equatable {
    let title: String
    let authors: [String]
    let contents: String
    let thumbnail: String
}

class BookStorage {
    static let shared = BookStorage()

    private let savedKey = "SavedBooks"
    private let recentKey = "RecentBooks"

    var savedBooks: [Book] = []
    var recentBooks: [Book] = []

    private init() {
        load()
    }

    func saveBook(_ book: Book) {
        if !savedBooks.contains(book) {
            savedBooks.append(book)
            persist()
        }
    }

    func deleteBook(at index: Int) {
        savedBooks.remove(at: index)
        persist()
    }

    func clearAll() {
        savedBooks.removeAll()
        persist()
    }

    func addRecent(_ book: Book) {
        recentBooks.removeAll { $0 == book }
        recentBooks.insert(book, at: 0)
        if recentBooks.count > 10 {
            recentBooks = Array(recentBooks.prefix(10))
        }
        persist()
    }

    private func persist() {
        if let saved = try? JSONEncoder().encode(savedBooks) {
            UserDefaults.standard.set(saved, forKey: savedKey)
        }
        if let recent = try? JSONEncoder().encode(recentBooks) {
            UserDefaults.standard.set(recent, forKey: recentKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: savedKey),
           let books = try? JSONDecoder().decode([Book].self, from: data) {
            savedBooks = books
        }
        if let data = UserDefaults.standard.data(forKey: recentKey),
           let books = try? JSONDecoder().decode([Book].self, from: data) {
            recentBooks = books
        }
    }
}

// MARK: - API

class BookAPIManager {
    static func search(query: String, completion: @escaping ([Book]) -> Void) {
        let apiKey = "5b261477a60858673c978c8e47892231"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://dapi.kakao.com/v3/search/book?query=\(encodedQuery)"
        
        guard let url = URL(string: urlString) else {
            print("❌ URL 생성 실패")
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("KakaoAK \(apiKey)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error:", error.localizedDescription)
                completion([])
                return
            }
            guard let data = data else {
                print("❌ No data")
                completion([])
                return
            }
            
            // JSON 파싱 예시 (BookResponse 타입 필요)
            do {
                let decodedResponse = try JSONDecoder().decode(BookResponse.self, from: data)
                completion(decodedResponse.documents)
            } catch {
                print("❌ JSON 디코딩 실패:", error.localizedDescription)
                completion([])
            }
            
        }.resume()
    }
}


// MARK: - 확장

extension UIImageView {
    func load(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
    }
}

// MARK: - 뷰컨트롤러: 책 검색

class BookSearchViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate {

    var books: [Book] = []
    var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "책 검색"

        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "책 제목을 입력하세요"
        navigationItem.titleView = searchBar

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.bounds.width - 40, height: 100)
        layout.sectionInset = .init(top: 10, left: 20, bottom: 10, right: 20)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(BookCell.self, forCellWithReuseIdentifier: "BookCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .white

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    // 나머지 함수 그대로...
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        BookAPIManager.search(query: text) { [weak self] results in
            DispatchQueue.main.async {
                self?.books = results
                self?.collectionView.reloadData()
            }
        }
        searchBar.resignFirstResponder()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        BookStorage.shared.recentBooks.isEmpty ? 1 : 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        section == 0 && !BookStorage.shared.recentBooks.isEmpty
            ? BookStorage.shared.recentBooks.count
            : books.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BookCell", for: indexPath) as! BookCell
        let book = indexPath.section == 0 && !BookStorage.shared.recentBooks.isEmpty
            ? BookStorage.shared.recentBooks[indexPath.item]
            : books[indexPath.item]
        cell.configure(book)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let book = indexPath.section == 0 && !BookStorage.shared.recentBooks.isEmpty
            ? BookStorage.shared.recentBooks[indexPath.item]
            : books[indexPath.item]

        BookStorage.shared.addRecent(book)
        let vc = BookDetailViewController(book: book)
        vc.onAdd = { [weak self] in
            self?.collectionView.reloadData()
        }
        present(vc, animated: true)
    }
}

// MARK: - 셀

class BookCell: UICollectionViewCell {
    let titleLabel = UILabel()
    let thumbnailImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .systemGray6
        contentView.layer.cornerRadius = 10

        thumbnailImageView.contentMode = .scaleAspectFit
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thumbnailImageView)

        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            thumbnailImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 60),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 80),

            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(_ book: Book) {
        titleLabel.text = book.title
        thumbnailImageView.load(urlString: book.thumbnail)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


// MARK: - 책 상세 화면

class BookDetailViewController: UIViewController {
    let book: Book
    var onAdd: (() -> Void)?

    init(book: Book) {
        self.book = book
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .formSheet
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let titleLabel = UILabel()
        titleLabel.text = book.title
        titleLabel.font = .boldSystemFont(ofSize: 20)

        let authorLabel = UILabel()
        authorLabel.text = "지은이: \(book.authors.joined(separator: ", "))"

        let contentLabel = UILabel()
        contentLabel.text = book.contents
        contentLabel.numberOfLines = 0

        let imageView = UIImageView()
        imageView.load(urlString: book.thumbnail)
        imageView.contentMode = .scaleAspectFit
        imageView.heightAnchor.constraint(equalToConstant: 200).isActive = true

        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel, authorLabel, contentLabel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        let addButton = UIButton(type: .system)
        addButton.setTitle("담기", for: .normal)
        addButton.backgroundColor = .systemBlue
        addButton.setTitleColor(.white, for: .normal)
        addButton.layer.cornerRadius = 10
        addButton.addTarget(self, action: #selector(addBook), for: .touchUpInside)

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("X", for: .normal)
        closeButton.addTarget(self, action: #selector(closeModal), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [closeButton, addButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 20
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(buttonStack)
        NSLayoutConstraint.activate([
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc func addBook() {
        BookStorage.shared.saveBook(book)
        onAdd?()
        dismiss(animated: true)
    }

    @objc func closeModal() {
        dismiss(animated: true)
    }
}

// MARK: - 담은 책 화면

class SavedBookListViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "담은 책 목록"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "전체 삭제", style: .plain, target: self, action: #selector(clearAll))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        BookStorage.shared.savedBooks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let book = BookStorage.shared.savedBooks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = book.title
        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            BookStorage.shared.deleteBook(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    @objc func clearAll() {
        BookStorage.shared.clearAll()
        tableView.reloadData()
    }
}


// MARK: - App/Scene

class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let searchNav = UINavigationController(rootViewController: BookSearchViewController())
        searchNav.tabBarItem = UITabBarItem(title: "검색", image: UIImage(systemName: "magnifyingglass"), tag: 0)

        let savedNav = UINavigationController(rootViewController: SavedBookListViewController())
        savedNav.tabBarItem = UITabBarItem(title: "담은 책", image: UIImage(systemName: "book"), tag: 1)

        viewControllers = [searchNav, savedNav]
    }
}


