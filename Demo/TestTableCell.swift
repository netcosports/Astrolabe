//
//  TestTableCell.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/5/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe

class TestTableCell: TableViewCell {
  
  var data: Data?
  let label: UILabel = {
    let label = UILabel()
    label.textColor = .black
    label.font = .systemFont(ofSize: 18.0)
    label.textAlignment = .center
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

extension TestTableCell: Reusable {

  typealias Data = TestViewModel
  
  func setup(with data: TestViewModel) {
    label.text = data.title
    if selectedState {
      contentView.backgroundColor = .white
    } else {
      contentView.backgroundColor = data.color
    }
  }

  static func size(for data: TestViewModel, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: 64.0)
  }
}

class TestTableHeader: TableViewHeaderFooter {
  
  var data: Data?
  let label: UILabel = {
    let label = UILabel()
    label.textColor = .black
    label.font = .systemFont(ofSize: 18.0)
    label.textAlignment = .center
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

extension TestTableHeader: Reusable {
  typealias Data = TestViewModel

  func setup(with data: TestViewModel) {
    label.text = data.title
    contentView.backgroundColor = data.color
  }

  static func size(for data: TestViewModel, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: 64.0)
  }
}
