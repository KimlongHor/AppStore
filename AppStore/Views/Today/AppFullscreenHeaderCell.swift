//
//  AppFullscreenHeaderCell.swift
//  AppStore
//
//  Created by horkimlong on 30/4/21.
//

import UIKit

class AppFullscreenHeaderCell: UITableViewCell {
    
    let todayCell = TodayCell()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(todayCell)
        todayCell.fillSuperview()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
