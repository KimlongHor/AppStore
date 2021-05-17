//
//  AppsCompositionalViewDiffableDatasource.swift
//  AppStore
//
//  Created by horkimlong on 15/5/21.
//

import SwiftUI

class AppCompositionalController: UICollectionViewController {
    
    var groups = [AppGroup]()
    var socialApps = [SocialApp]()
    let headerId = "headerId"
    var games: AppGroup?
    
    init() {
        
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, _) -> NSCollectionLayoutSection? in
            
            if sectionNumber == 0 {
                return AppCompositionalController.topSection()
            } else {
                return AppCompositionalController.secondSection()
            }
        }
        
        super.init(collectionViewLayout: layout)
    }
    
    static func secondSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1/3)))
        item.contentInsets = .init(top: 0, leading: 0, bottom: 16, trailing: 16)
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(0.8), heightDimension: .absolute(300)), subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        section.contentInsets.leading = 16
        
        let kind = UICollectionView.elementKindSectionHeader
        section.boundarySupplementaryItems = [
            .init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50)), elementKind: kind, alignment: .topLeading)
        ]
        
        return section
    }
    
    static func topSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
        item.contentInsets = .init(top: 0, leading: 0, bottom: 16, trailing: 16)
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(0.8), heightDimension: .absolute(300)), subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        section.contentInsets.leading = 16
        return section
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(CompositionalHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerId)
        collectionView.register(AppsHeaderCell.self, forCellWithReuseIdentifier: "cellId")
        collectionView.register(AppRowCell.self, forCellWithReuseIdentifier: "smallCellId")
        
        collectionView.backgroundColor = .systemBackground
        navigationItem.title = "Apps"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.rightBarButtonItem = .init(title: "Fetch Top Free", style: .plain, target: self, action: #selector(handleFetchTopFree))
        
//        fetchApp ()
        
        setupRefreshControl()
        
        setupDiffableDatasource()
    }
    
    fileprivate func setupRefreshControl() {
        collectionView.refreshControl = UIRefreshControl()
        collectionView.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    }
    
    @objc func handleRefresh() {
        collectionView.refreshControl?.endRefreshing()
        
        var snapshot = diffableDatasource.snapshot()
        snapshot.deleteSections([.topFree])
        
        diffableDatasource.apply(snapshot)
    }
    
    @objc func handleFetchTopFree() {
        Service.shared.fetchTopFreeApp { (appGroup, error) in
            var snapshot = self.diffableDatasource.snapshot()
            snapshot.insertSections([.topFree], afterSection: .topSocial)
            snapshot.appendItems(appGroup?.feed.results ?? [], toSection: .topFree)
            
            self.diffableDatasource.apply(snapshot)
        }
    }
    
    enum AppSection {
        case topSocial
        case grossing
        case freeGames
        case topFree
    }
    
    // lazy var allow us to declare a variable that can access to self properties. In this case we can access to "self.collectionView"
    lazy var diffableDatasource: UICollectionViewDiffableDataSource<AppSection, AnyHashable> = .init(collectionView: self.collectionView) { (collectionView, indexPath, object) -> UICollectionViewCell? in
        
        if let object = object as? SocialApp {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath) as! AppsHeaderCell
            
            cell.app = object
            return cell
        } else if let object = object as? FeedResult {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "smallCellId", for: indexPath) as! AppRowCell
            
            cell.app = object
            cell.getButton.addTarget(self, action: #selector(self.handleGet), for: .primaryActionTriggered)
            
            return cell
        }
        
        return nil
    }
    
    @objc func handleGet(button: UIView) {
        
        var superview = button.superview
        
        // i want to reach the parent cell of the get button
        while superview != nil {
            if let cell = superview as? UICollectionViewCell {
                guard let indexPath = self.collectionView.indexPath(for: cell) else {
                    return
                }
                guard let objectIClickOnto = diffableDatasource.itemIdentifier(for: indexPath) else {return}
                
                var snapshot = diffableDatasource.snapshot()
                snapshot.deleteItems([objectIClickOnto])
                diffableDatasource.apply(snapshot)
            }
            superview = superview?.superview
        }
        
        
    }
    
    private func setupDiffableDatasource() {
        
        collectionView.dataSource = diffableDatasource
        diffableDatasource.supplementaryViewProvider = .some({ (collectionView, kind, indexPath) -> UICollectionReusableView? in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.headerId, for: indexPath) as! CompositionalHeader
            
            let snapshot = self.diffableDatasource.snapshot()
            let object = self.diffableDatasource.itemIdentifier(for: indexPath)
            
            let section = snapshot.sectionIdentifier(containingItem: object!)!
            
            if section == .freeGames {
                header.label.text = "Games"
            } else if section == .grossing {
                header.label.text = "Top Grossing"
            } else {
                header.label.text = "Top Free"
            }
            
            
            return header
        })
        
        Service.shared.fetchSocialApps { (socialApps, error) in
            
            if let error = error {
                print("Failed fetching social apps", error)
                return
            }
            
            Service.shared.fetchTopGrossing { (appGroup, error) in
                if let error = error {
                    print("Failed fetching topGrossing apps", error)
                    return
                }
                
                Service.shared.fetchGames { (gamesGroup, error) in
                    if let error = error {
                        print("Failed fetching games apps", error)
                        return
                    }
                    
                    var snapshot = self.diffableDatasource.snapshot()
                    snapshot.appendSections([.topSocial, .grossing, .freeGames])
                    
                    // top social
                    snapshot.appendItems(socialApps ?? [], toSection: .topSocial)
                    
                    // top grossing
                    let appoObjects = appGroup?.feed.results ?? []
                    snapshot.appendItems(appoObjects, toSection: .grossing)
                    
                    // game
                    let gameObjects = gamesGroup?.feed.results ?? []
                    snapshot.appendItems(gameObjects, toSection: .freeGames)
                    
                    self.diffableDatasource.apply(snapshot)
                }
                
            }
        }
    }
        
    private func fetchApp () {
        var group1: AppGroup?
        var group2: AppGroup?
        var group3: AppGroup?
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        Service.shared.fetchSocialApps { (apps, error) in
            dispatchGroup.leave()
            if let error = error {
                print("Failed fetching social app", error)
                return
            }
            
            self.socialApps = apps ?? []
        }
        
        dispatchGroup.enter()
        Service.shared.fetchGames { (appGroup, error) in
            dispatchGroup.leave()
            if let error = error {
                print("Failed fetching games", error)
                return
            }
            group1 = appGroup
        }
        
        dispatchGroup.enter()
        Service.shared.fetchTopGrossing { (appGroup, error) in
            dispatchGroup.leave()
            if let error = error {
                print("Failed fetching top grossing", error)
                return
            }
            group2 = appGroup
        }
        
        dispatchGroup.enter()
        Service.shared.fetchTopFreeApp { (appGroup, error) in
            dispatchGroup.leave()
            if let error = error {
                print("Failed fetching top free app", error)
                return
            }
            group3 = appGroup
        }
        
        dispatchGroup.notify(queue: .main) {
            if let group = group1 {
                self.groups.append(group)
            }
            
            if let group = group2 {
                self.groups.append(group)
            }
            
            if let group = group3 {
                self.groups.append(group)
            }
            
            self.collectionView.reloadData()
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var appId = ""
        
        let object = diffableDatasource.itemIdentifier(for: indexPath)
        if let object = object as? SocialApp {
            appId = object.id
        } else if let object = object as? FeedResult {
            appId = object.id
        }
        
        let appDetailController = AppDetailController(appId: appId)
        navigationController?.pushViewController(appDetailController, animated: true)
    }
    
//    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        if section == 0 {
//            return socialApps.count
//        } else {
//            return groups[section - 1].feed.results.count
//        }
//    }
    
//    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//
//        switch indexPath.section {
//        case 0:
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath) as! AppsHeaderCell
//
//            let socialApp = self.socialApps[indexPath.item]
//            cell.titleLabel.text = socialApp.tagline
//            cell.companyLabel.text = socialApp.name
//            cell.imageView.sd_setImage(with: URL(string: socialApp.imageUrl))
//
//            return cell
//        default:
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "smallCellId", for: indexPath) as! AppRowCell
//
//            let app = groups[indexPath.section - 1].feed.results[indexPath.item]
//            cell.companyLabel.text = app.artistName
//            cell.nameLabel.text = app.name
//            cell.imageView.sd_setImage(with: URL(string: app.artworkUrl100))
//            return cell
//        }
//    }
    
//    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//
//        let appId: String
//
//        if indexPath.section == 0 {
//            appId = socialApps[indexPath.item].id
//
//        } else {
//            appId = groups[indexPath.section - 1].feed.results[indexPath.item].id
//        }
//
//        let appDetailController = AppDetailController(appId: appId)
//        navigationController?.pushViewController(appDetailController, animated: true)
//    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath)

        return headerCell
    }
    
    class CompositionalHeader: UICollectionReusableView {
        
        let label = UILabel(text: "Editor's Choice Games", font: .boldSystemFont(ofSize: 32))
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(label)
            label.fillSuperview()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

struct AppView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = AppCompositionalController()
        
        return UINavigationController(rootViewController: controller)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
    
    typealias UIViewControllerType = UIViewController
}

struct AppCompositionalView_Previews: PreviewProvider {
    static var previews: some View {
        AppView()
            .edgesIgnoringSafeArea(.all)
    }
}
