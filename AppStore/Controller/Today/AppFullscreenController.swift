//
//  AppFullscreenController.swift
//  AppStore
//
//  Created by horkimlong on 29/4/21.
//

import UIKit

class AppFullscreenController: UITableViewController {
    
    var dismissHandler: (()->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.item == 0 {
            let cell = AppFullscreenHeaderCell()
            cell.closeButton.addTarget(self, action: #selector(handleDimiss), for: .touchUpOutside)
            return cell
        }
        
        let cell = AppFullscreenDescriptionCell()
        return cell
    }
    
    @objc fileprivate func handleDimiss(button: UIButton) {
        button.isHidden = true
        dismissHandler?()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 450
        }
        
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
}
