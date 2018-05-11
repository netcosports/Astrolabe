//
//  TestCell.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 12/28/16.
//  Copyright © 2016 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe

struct TestViewModel {
  let title: String
  let color: UIColor

  init(_ title: String) {
    self.title = title
    self.color = TestViewModel.generateRandomColor()
  }

  private static func generateRandomColor() -> UIColor {
    let hue: CGFloat = CGFloat(arc4random() % 256) / 256
    let saturation: CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5
    let brightness: CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5
    return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
  }
}

class TestCollectionCell: CollectionViewCell {

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

extension TestCollectionCell: Reusable {

  func setup(with data: TestViewModel) {
    label.text = data.title
    if selectedState {
      contentView.backgroundColor = .white
    } else {
      contentView.backgroundColor = data.color
    }
  }

  static func size(for data: TestViewModel, containerSize: CGSize) -> CGSize {
    return CGSize(width: 64.0, height: 64.0)
  }
}
