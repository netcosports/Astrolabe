//
//  TestWrapperCell.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/10/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import UIKit
import Astrolabe

class TestWrapperCell: ReusableWrapper, Reusable {
  var contentView: UIView?

  let label: UILabel = {
    let label = UILabel()
    label.textColor = .black
    label.font = .systemFont(ofSize: 18.0)
    label.textAlignment = .center
    return label
  }()

  required init() { }

  func setup<T: ReusableView>(with reusableView: T) {
    reusableView.contentView.addSubview(label)
    label.snp.remakeConstraints { make in
      make.edges.equalToSuperview()
    }
  }

  func setup(with data: TestViewModel) {
    label.text = data.title
    contentView?.backgroundColor = data.color
  }

  static func size(for data: TestViewModel, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: 64.0)
  }
}
