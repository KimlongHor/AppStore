//
//  ReviewRowCell.swift
//  AppStore
//
//  Created by horkimlong on 23/4/21.
//

import UIKit

class ReviewRowCell: UICollectionViewCell {
    
    let reviewsAndRatings = UILabel(text: "Reviews & Ratings", font: .boldSystemFont(ofSize: 24))
    
    let reviewsController = ReviewsController()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        addSubview(reviewsAndRatings)
        addSubview(reviewsController.view)
        
        reviewsAndRatings.anchor(top: topAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 16, left: 16, bottom: 16, right: 16))
        
        reviewsController.view.anchor(top: reviewsAndRatings.bottomAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(top: 16, left: 0, bottom: 16, right: 0))
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
