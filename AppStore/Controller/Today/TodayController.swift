//
//  TodayController.swift
//  AppStore
//
//  Created by horkimlong on 28/4/21.
//

import UIKit

class TodayController: BaseListController, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    
    var items = [TodayItem]()
    
    var activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(style: .whiteLarge)
        aiv.color = .darkGray
        aiv.startAnimating()
        aiv.hidesWhenStopped = true
        return aiv
    }()
    
    var startingFrame: CGRect?
    
    var appFullscreenController: AppFullscreenController!
    
    var anchoredConstraint: AnchoredConstraints?
    
    let blurVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(blurVisualEffectView)
        blurVisualEffectView.fillSuperview()
        blurVisualEffectView.alpha = 0
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.centerInSuperview()
        
        fetchData()
        
        collectionView.backgroundColor = #colorLiteral(red: 0.941790998, green: 0.9136702418, blue: 0.9132861495, alpha: 1)
        
        collectionView.register(TodayCell.self, forCellWithReuseIdentifier: TodayItem.CellType.single.rawValue)
        collectionView.register(TodayMultipleAppCell.self, forCellWithReuseIdentifier: TodayItem.CellType.multiple.rawValue)
    }
    
    fileprivate func fetchData() {
        // dispatchGroup
        
        let dispatchGroup = DispatchGroup()
        
        var topGrossingGroup: AppGroup?
        var gamesGroup: AppGroup?
        
        dispatchGroup.enter()
        Service.shared.fetchTopGrossing { (appGroup, error) in
            dispatchGroup.leave()
            if let error = error {
                print("Failed fetching topGrossing", error.localizedDescription)
                return
            }
            
            topGrossingGroup = appGroup
        }
        
        dispatchGroup.enter()
        Service.shared.fetchGames { (appGroup, error) in
            dispatchGroup.leave()
            if let error = error {
                print("Failed fetching games", error.localizedDescription)
                return
            }
            
            gamesGroup = appGroup
        }
        
        dispatchGroup.notify(queue: .main) {
            print("Finished fetching")
            self.activityIndicatorView.stopAnimating()
            
            self.items = [
                TodayItem.init(category: "LIFE HACK", title: "Utilizing your Time", image: #imageLiteral(resourceName: "garden"), description: "All the tools and apps you need to intelligently organize your life the right way.", backgroundColor: .white, cellType: .single, apps: []),

                TodayItem.init(category: "THE DAILY LIST", title: topGrossingGroup?.feed.title ?? "", image: #imageLiteral(resourceName: "garden"), description: "", backgroundColor: .white, cellType: .multiple, apps: topGrossingGroup?.feed.results ?? []),

                TodayItem.init(category: "HOLIDAYS", title: "Travel on a Budget", image: #imageLiteral(resourceName: "holiday"), description: "Find out all your need to know on how to travel without packing everything!", backgroundColor: #colorLiteral(red: 0.9853913188, green: 0.9642749429, blue: 0.7255596519, alpha: 1), cellType: .single, apps: []),

                TodayItem.init(category: "THE DAILY LIST", title: gamesGroup?.feed.title ?? "", image: #imageLiteral(resourceName: "garden"), description: "", backgroundColor: .white, cellType: .multiple, apps: gamesGroup?.feed.results ?? []),
            ]
            
            self.collectionView.reloadData()
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cellId = items[indexPath.item].cellType.rawValue
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! BaseTodayCell
        
        cell.todayItem = items[indexPath.item]
        
        (cell as? TodayMultipleAppCell)?.multipleAppsController.collectionView.addGestureRecognizer(UIGestureRecognizer(target: self, action: #selector(handleMultipleAppsTap)))
        
//        (cell as? TodayMultipleAppCell)?.multipleAppsController.collectionView.isUserInteractionEnabled = false

        return cell
    }
    
    @objc fileprivate func handleMultipleAppsTap(gesture: UIGestureRecognizer) {

        let collectionView = gesture.view

        var superview = collectionView?.superview

        while superview != nil {
            if let cell = superview as? TodayMultipleAppCell {

                guard let indexPath = self.collectionView.indexPath(for: cell) else {return}

                let apps = self.items[indexPath.item].apps

                let fullController = TodayMultipleAppsController(mode: .fullscreen)
                fullController.apps = apps

                present(fullController, animated: true)
                return
            }
            superview = superview?.superview
        }
    }
    
    fileprivate func showDailyListFullScreen(_ indexPath: IndexPath) {
        let fullController = TodayMultipleAppsController(mode: .fullscreen)
        fullController.apps = self.items[indexPath.item].apps
        
        // BackEnabledNavigationController is a custom navigationController.
        // If we dont want to use this, just use a normal UINavigationController
        let navigationController = BackEnabledNavigationController(rootViewController: fullController)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        switch items[indexPath.item].cellType {
        case .multiple:
            showDailyListFullScreen(indexPath)
        default:
            showSingleAppFullscreen(indexPath)
        }
    }
    
    fileprivate func setupAppFullscreenController(_ indexPath: IndexPath) {
        let appFullscreenController = AppFullscreenController()
        appFullscreenController.todayItem = items[indexPath.row]
        appFullscreenController.dismissHandler = {
            self.handleAppFullscreenDismissal()
        }
        
        self.appFullscreenController = appFullscreenController
        
        
        
        // Step 1: setup our pan gesture
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleDrag))
            // We conform this delegate and call gestureReconizer(shouldRecognizeSimultaneouslyWith), because we dont want the new gesture to override the tableview scrolling gesture
        gesture.delegate = self
        appFullscreenController.view.addGestureRecognizer(gesture)
        
        // Step 2: add a blur effect view
        
        
        // Step 3: not to interfere with our UITableView scrolling
        
        
    }
    
    var appFullscreenBeginOffset: CGFloat = 0
    
    @objc fileprivate func handleDrag(gesture: UIPanGestureRecognizer) {
        
        if gesture.state == .began {
            appFullscreenBeginOffset = appFullscreenController.tableView.contentOffset.y
        }
        
        if appFullscreenController.tableView.contentOffset.y > 0 {
            return
        }
        
        let translationY = gesture.translation(in: appFullscreenController.view).y
        print(translationY)
        
        if gesture.state == .changed {
            if translationY > 0 {
                let trueOffset = translationY - appFullscreenBeginOffset
                
                var scale = 1 - trueOffset / 1000
                scale = min(1, scale)
                scale = max(0.5, scale)
                
                let transform: CGAffineTransform = .init(scaleX: scale, y: scale)
                self.appFullscreenController.view.transform = transform
            }
        } else if gesture.state == .ended {
            if translationY > 0 {
                handleAppFullscreenDismissal()
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    fileprivate func startingCellFrame(_ indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else {return}
        
        // absolute coordinates of cell
        guard let startingFrame = cell.superview?.convert(cell.frame, to: nil) else {return}
        
        self.startingFrame = startingFrame
    }
    
    fileprivate func setupAppFullscreenStartingPosition(_ indexPath: IndexPath) {
        let fullscreenView = appFullscreenController.view!
        fullscreenView.layer.cornerRadius = 16
        view.addSubview(fullscreenView)
        
        // We need to use this function because we dont use navbar.push to push this controller.
        // Also note that, if we add a child controller, we need to clean it afterward. (look at handleRemoveRedView func to see how to clean it)
        addChild(appFullscreenController)
        
        self.collectionView.isUserInteractionEnabled = false
        
        
        startingCellFrame(indexPath)
        
        guard let startingFrame = self.startingFrame else {return}
        
        // auto layout constraint animations --
        
        self.anchoredConstraint = fullscreenView.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: startingFrame.origin.y, left: startingFrame.origin.x, bottom: 0, right: 0), size: .init(width: startingFrame.width, height: startingFrame.height))
        
//        fullscreenView.translatesAutoresizingMaskIntoConstraints = false
//        topConstraint = fullscreenView.topAnchor.constraint(equalTo: view.topAnchor, constant: startingFrame.origin.y)
//        leadingConstraint = fullscreenView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: startingFrame.origin.x)
//        widthConstraint = fullscreenView.widthAnchor.constraint(equalToConstant: startingFrame.width)
//        heightConstraint = fullscreenView.heightAnchor.constraint(equalToConstant: startingFrame.height)
//
//
//        [topConstraint, leadingConstraint, widthConstraint, heightConstraint].forEach({$0?.isActive = true})
        
        self.view.layoutIfNeeded()
        
        // -- end
    }
    
    fileprivate func beginAnimationAppFullscreen() {
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {

            self.blurVisualEffectView.alpha = 1
            
            self.anchoredConstraint?.top?.constant = 0
            self.anchoredConstraint?.leading?.constant = 0
            self.anchoredConstraint?.width?.constant = self.view.frame.width
            self.anchoredConstraint?.height?.constant = self.view.frame.height
            
            self.view.layoutIfNeeded() // starts animation
            
            self.tabBarController?.tabBar.frame.origin.y = self.view.frame.size.height
            
            guard let cell = self.appFullscreenController.tableView.cellForRow(at: [0,0]) as? AppFullscreenHeaderCell else {return}
            
            cell.todayCell.topConstraint.constant = 48
            cell.layoutIfNeeded()
            
        }, completion: nil)
    }
    
    fileprivate func showSingleAppFullscreen( _ indexPath: IndexPath) {
        
        // Step 1:
        setupAppFullscreenController(indexPath)
        
        // Step 2: setup fullscreen in its starting position
        setupAppFullscreenStartingPosition(indexPath)
        
        // Setp 3: begin the fullscreen animation
        beginAnimationAppFullscreen()

    }
    
    @objc func handleAppFullscreenDismissal() {
        
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
            
            self.appFullscreenController.tableView.scrollToRow(at: [0,0], at: .top, animated: true)
            
            self.blurVisualEffectView.alpha = 0
            
            self.appFullscreenController.view.transform = .identity
            
            guard let startingFrame = self.startingFrame else {return}
            
            self.anchoredConstraint?.top?.constant = startingFrame.origin.y
            self.anchoredConstraint?.leading?.constant = startingFrame.origin.x
            self.anchoredConstraint?.width?.constant = startingFrame.width
            self.anchoredConstraint?.height?.constant = startingFrame.height
            self.view.layoutIfNeeded()
            
            if let tabBarFrame = self.tabBarController?.tabBar.frame {
                self.tabBarController?.tabBar.frame.origin.y = self.view.frame.size.height - tabBarFrame.height
            }
            
            
            guard let cell = self.appFullscreenController.tableView.cellForRow(at: [0,0]) as? AppFullscreenHeaderCell else {return}
            
//            cell.closeButton.alpha = 0
            self.appFullscreenController.closeButton.alpha = 0
            cell.todayCell.topConstraint.constant = 24
            cell.layoutIfNeeded()
            
            
            
        }, completion: { _ in
            self.appFullscreenController.view.removeFromSuperview()
            self.appFullscreenController.removeFromParent()
            self.collectionView.isUserInteractionEnabled = true
        })
    }
    
    static let cellSize: CGFloat = 500
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: view.frame.width - 64, height: TodayController.cellSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 32
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 32, left: 0, bottom: 32, right: 0)
    }
}
