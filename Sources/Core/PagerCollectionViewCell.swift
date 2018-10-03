//
//  PagerCollectionViewCell.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 7/12/16.
//  Copyright © 2016 Netcosports. All rights reserved.
//

import UIKit

public struct PagerViewModel {
  public let viewController: UIViewController
  public let cellId: String

  public init(viewController: UIViewController, cellId: String) {
    self.viewController = viewController
    self.cellId = cellId
  }
}

public class PagerCollectionViewCell: CollectionViewCell, Reusable, PagerSourceCell {

  open var data: PagerViewModel?

  open func setup(with data: PagerViewModel) {
    self.data = data

    if data.viewController.view.superview != contentView {
      setupChildView(data)
      shouldCallWillAppear = false
    } else {
      shouldCallWillAppear = true
    }
  }

  private var shouldCallWillAppear = false

  public static func size(for data: PagerViewModel, containerSize: CGSize) -> CGSize {
    return containerSize
  }

  public static func identifier(for data: PagerViewModel) -> String {
    return data.cellId
  }

  private func setupChildView(_ data: PagerViewModel) {
    data.viewController.beginAppearanceTransition(true, animated: true)

    containerViewController?.addChild(data.viewController)
    contentView.addSubview(data.viewController.view)

    data.viewController.view.translatesAutoresizingMaskIntoConstraints = false
    contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[content]|", metrics: nil,
                                                              views: ["content": data.viewController.view]))
    contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[content]|", metrics: nil,
                                                              views: ["content": data.viewController.view]))
  }

  public func willAppear(isCancelled: Bool = false) {
    guard shouldCallWillAppear || isCancelled else { return }
    guard let data = data else { return }

    setupChildView(data)
  }

  public func didAppear() {
    data?.viewController.endAppearanceTransition()

    guard let containerViewController = containerViewController else { return }
    data?.viewController.didMove(toParent: containerViewController)
  }

  public func willDisappear() {
    guard let data = data else { return }
    data.viewController.beginAppearanceTransition(false, animated: true)
  }

  public func didDisappear() {
    guard let data = data else { return }

    data.viewController.willMove(toParent: nil)
    data.viewController.removeFromParent()
    data.viewController.view.removeFromSuperview()

    data.viewController.endAppearanceTransition()
  }

  override public var debugDescription: String {
    guard let data = data else { return super.debugDescription }
    return super.debugDescription + " " + data.cellId
  }

}
