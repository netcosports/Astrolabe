//
//  PagerCollectionViewCell.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 7/12/16.
//  Copyright © 2016 Netcosports. All rights reserved.
//

import UIKit
import SnapKit

struct PagerViewModel {
  let viewController: UIViewController
  let cellId: String
}

class PagerCollectionViewCell: CollectionViewCell, Reusable {

  open var data: PagerViewModel?

  func setup(with data: PagerViewModel) {
    self.data = data
    containerViewController?.addChildViewController(data.viewController)
    contentView.addSubview(data.viewController.view)
    data.viewController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
  }

  static func size(for data: PagerViewModel, containerSize: CGSize) -> CGSize {
    return containerSize
  }

  static func identifier(for data: PagerViewModel) -> String {
    return data.cellId
  }

  open override func willDisplay() {
    super.willDisplay()
    if let data = data {
      guard let containerViewController = containerViewController else { return }
      data.viewController.didMove(toParentViewController: containerViewController)
    }
  }

  open override func endDisplay() {
    super.endDisplay()
    if let data = data {
      data.viewController.willMove(toParentViewController: nil)
      data.viewController.view.removeFromSuperview()
      data.viewController.removeFromParentViewController()
    }
  }
}
