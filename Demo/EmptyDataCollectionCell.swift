//
//  EmptyDataCollectionCell.swift
//  Demo
//
//  Created by Eugen Filipkov on 3/4/19.
//  Copyright © 2019 NetcoSports. All rights reserved.
//

import UIKit
import Astrolabe

class EmptyDataCollectionCell: CollectionViewCell {
  let label: UILabel = {
    let label = UILabel()
    label.textColor = .black
    label.font = .systemFont(ofSize: 14.0)
    label.textAlignment = .center
    label.numberOfLines = 2
    return label
  }()
  
  override func setup() {
    super.setup()
    
    contentView.addSubview(label)
    label.snp.remakeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
}

extension EmptyDataCollectionCell: Reusable {
  func setup(with data: LoaderState) {
    switch data {
    case .empty:
      label.text = "NO DATA"
    case .error(_):
      label.text = "ERROR"
    default: break
    }    
  }
  
  class func size(for data: LoaderState, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: 320.0)
  }
}
