//
//  EmptyDataTableCell.swift
//  Demo
//
//  Created by Eugen Filipkov on 3/5/19.
//  Copyright © 2019 NetcoSports. All rights reserved.
//

import UIKit
import Astrolabe

class EmptyDataTableCell: TableViewCell {
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

extension EmptyDataTableCell: Reusable {  
  func setup(with data: LoaderState) {
    switch data {
    case .empty:
      label.text = "NO DATA"
    case .error(_):
      label.text = "ERROR"
    default: break
    }
  }
  
  static func size(for data: LoaderState, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: 320.0)
  }
}
