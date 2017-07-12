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

  func setup(with data: TestViewModel) {
    label.text = data.title
    contentView.backgroundColor = data.color
  }

  static func size(for data: TestViewModel, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: 64.0)
  }
}

class TestTableStyledCell: StyledTableViewCell<Style> {

  let label: UILabel = {
    let label = UILabel()
    label.textColor = .black
    label.font = .systemFont(ofSize: 18.0)
    label.textAlignment = .center
    return label
  }()

  override func setup(with style: Style) {
    super.setup(with: style)

    switch style {
    case .red:
      contentView.backgroundColor = UIColor.red
    case .blue:
      contentView.backgroundColor = UIColor.blue
    case .green:
      contentView.backgroundColor = UIColor.green
    }

    contentView.addSubview(label)
    label.snp.remakeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
}

extension TestTableStyledCell: StyledReusable {
  typealias Data = TestStyledViewModel

  func setup(with data: Data) {
    label.text = data.title
  }

  static func size(for data: Data, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: 64.0)
  }
}
