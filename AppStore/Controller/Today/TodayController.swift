//
//  TodayController.swift
//  AppStore
//
//  Created by horkimlong on 28/4/21.
//

import UIKit

class TodayController: BaseListController, UICollectionViewDelegateFlowLayout {
    
    fileprivate let cellId = "cellId"
    
    let items = [
        TodayItem.init(category: "LIFE HACK", title: "Utilizing your Time", image: #imageLiteral(resourceName: "garden"), description: "All the tools and apps you need to intelligently organize your life the right way.", backgroundColor: .white),
        
        TodayItem.init(category: "HOLIDAYS", title: "Travel on a Budget", image: #imageLiteral(resourceName: "holiday"), description: "Find out all your need to know on how to travel without packing everything!", backgroundColor: #colorLiteral(red: 0.9853913188, green: 0.9642749429, blue: 0.7255596519, alpha: 1))
    ]
    
    var startingFrame: CGRect?
    
    var appFullscreenController: AppFullscreenController!
    
    var topConstraint: NSLayoutConstraint?
    var leadingConstraint: NSLayoutConstraint?
    var heightConstraint: NSLayoutConstraint?
    var widthConstraint: NSLayoutConstraint?
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = #colorLiteral(red: 0.941790998, green: 0.9136702418, blue: 0.9132861495, alpha: 1)
        
        collectionView.register(TodayCell.self, forCellWithReuseIdentifier: cellId)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! TodayCell
        
        cell.todayItem = items[indexPath.item]
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let appFullscreenController = AppFullscreenController()
        appFullscreenController.todayItem = items[indexPath.row]
        appFullscreenController.dismissHandler = {
            self.handleRemoveRedView()
        }
        
        let fullscreenView = appFullscreenController.view!
        fullscreenView.layer.cornerRadius = 16
        view.addSubview(fullscreenView)
        
        
        // We need to use this function because we dont use navbar.push to push this controller.
        // Also note that, if we add a child controller, we need to clean it afterward. (look at handleRemoveRedView func to see how to clean it)
        addChild(appFullscreenController)
        
        self.appFullscreenController = appFullscreenController
        
        self.collectionView.isUserInteractionEnabled = false
        
        guard let cell = collectionView.cellForItem(at: indexPath) else {return}
        
        // absolute coordinates of cell
        guard let startingFrame = cell.superview?.convert(cell.frame, to: nil) else {return}
        
        self.startingFrame = startingFrame
        
        
        // auto layout constraint animations --
        
        fullscreenView.translatesAutoresizingMaskIntoConstraints = false
        topConstraint = fullscreenView.topAnchor.constraint(equalTo: view.topAnchor, constant: startingFrame.origin.y)
        leadingConstraint = fullscreenView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: startingFrame.origin.x)
        widthConstraint = fullscreenView.widthAnchor.constraint(equalToConstant: startingFrame.width)
        heightConstraint = fullscreenView.heightAnchor.constraint(equalToConstant: startingFrame.height)
        
        
        [topConstraint, leadingConstraint, widthConstraint, heightConstraint].forEach({$0?.isActive = true})
        
        self.view.layoutIfNeeded()
        
        // -- end
        
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {

            self.topConstraint?.constant = 0
            self.leadingConstraint?.constant = 0
            self.widthConstraint?.constant = self.view.frame.width
            self.heightConstraint?.constant = self.view.frame.height
            
            self.view.layoutIfNeeded() // starts animation
            
            self.tabBarController?.tabBar.frame.origin.y = self.view.frame.size.height
            
            
            
            guard let cell = self.appFullscreenController.tableView.cellForRow(at: [0,0]) as? AppFullscreenHeaderCell else {return}
            
            cell.todayCell.topConstraint.constant = 48
            cell.layoutIfNeeded()
            
        }, completion: nil)

    }
    
    
    
    @objc func handleRemoveRedView() {
        
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
            
            self.appFullscreenController.tableView.scrollToRow(at: [0,0], at: .top, animated: true)
            
            guard let startingFrame = self.startingFrame else {return}
            
            self.topConstraint?.constant = startingFrame.origin.y
            self.leadingConstraint?.constant = startingFrame.origin.x
            self.widthConstraint?.constant = startingFrame.width
            self.heightConstraint?.constant = startingFrame.height
            self.view.layoutIfNeeded()
            
            if let tabBarFrame = self.tabBarController?.tabBar.frame {
                self.tabBarController?.tabBar.frame.origin.y = self.view.frame.size.height - tabBarFrame.height
            }
            
            
            guard let cell = self.appFullscreenController.tableView.cellForRow(at: [0,0]) as? AppFullscreenHeaderCell else {return}
            
            cell.todayCell.topConstraint.constant = 24
            cell.layoutIfNeeded()
            
            
            
        }, completion: { _ in
            self.appFullscreenController.view.removeFromSuperview()
            self.appFullscreenController.removeFromParent()
            self.collectionView.isUserInteractionEnabled = true
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: view.frame.width - 64, height: 450)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 32
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 32, left: 0, bottom: 32, right: 0)
    }
}
