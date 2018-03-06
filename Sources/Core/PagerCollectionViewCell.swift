//
//  PagerCollectionViewCell.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 7/12/16.
//  Copyright © 2016 Netcosports. All rights reserved.
//

import UIKit

struct PagerViewModel {
  let viewController: UIViewController
  let cellId: String
}

class PagerCollectionViewCell: CollectionViewCell, Reusable {

  open var data: PagerViewModel?

  func setup(with data: PagerViewModel) {
    self.data = data

    if data.viewController.view.superview != contentView {
      setupChildView(data)
      shouldCallWillAppear = false
    } else {
      shouldCallWillAppear = true
    }
  }

  private var shouldCallWillAppear = false

  static func size(for data: PagerViewModel, containerSize: CGSize) -> CGSize {
    return containerSize
  }

  static func identifier(for data: PagerViewModel) -> String {
    return data.cellId
  }

  private func setupChildView(_ data: PagerViewModel) {
    data.viewController.beginAppearanceTransition(true, animated: true)

    containerViewController?.addChildViewController(data.viewController)
    contentView.addSubview(data.viewController.view)

    data.viewController.view.translatesAutoresizingMaskIntoConstraints = false
    contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[content]|", metrics: nil,
                                                              views: ["content": data.viewController.view]))
    contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[content]|", metrics: nil,
                                                              views: ["content": data.viewController.view]))
  }

  func willAppear(isCancelled: Bool = false) {
    guard shouldCallWillAppear || isCancelled else { return }
    guard let data = data else { return }

    setupChildView(data)
  }

  func didAppear() {
    data?.viewController.endAppearanceTransition()

    guard let containerViewController = containerViewController else { return }
    data?.viewController.didMove(toParentViewController: containerViewController)
  }

  func willDisappear() {
    guard let data = data else { return }
    data.viewController.beginAppearanceTransition(false, animated: true)
  }

  func didDisappear() {
    guard let data = data else { return }

    data.viewController.willMove(toParentViewController: nil)
    data.viewController.removeFromParentViewController()
    data.viewController.view.removeFromSuperview()

    data.viewController.endAppearanceTransition()
  }

  override var debugDescription: String {
    guard let data = data else { return super.debugDescription }
    return super.debugDescription + " " + data.cellId
  }

}
