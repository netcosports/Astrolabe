//
//  ReusedPagerCollectionViewCell.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/4/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit

public protocol ReusedPageData {
  associatedtype PageData: Equatable

  var data: PageData? { get set }
}

public final class ReusedPagerCollectionViewCell<Controller: UIViewController>: CollectionViewCell, Reusable, PagerSourceCell
where Controller: ReusedPageData {

  public typealias Data = Controller.PageData
  public var viewController = Controller()

  public func setup(with data: Data) {
    if viewController.data != data {
      viewController.data = data
    }

    if viewController.view.superview != contentView {
      setupChildView()
      shouldCallWillAppear = false
    } else {
      shouldCallWillAppear = true
    }
  }

  private var shouldCallWillAppear = false

  public static func size(for data: Data, containerSize: CGSize) -> CGSize {
    return containerSize
  }

  public static func identifier(for data: PagerViewModel) -> String {
    return data.cellId
  }

  private func setupChildView() {
    viewController.beginAppearanceTransition(true, animated: true)

    hostViewController?.addChild(viewController)
    contentView.addSubview(viewController.view)

    viewController.view.translatesAutoresizingMaskIntoConstraints = false
    contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[content]|", metrics: nil,
                                                              views: ["content": viewController.view]))
    contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[content]|", metrics: nil,
                                                              views: ["content": viewController.view]))
  }

  public func willAppear(isCancelled: Bool = false) {
    guard shouldCallWillAppear || isCancelled else { return }
    guard viewController.data != nil else { return }

    setupChildView()
  }

  public func didAppear() {
    viewController.endAppearanceTransition()

    guard let containerViewController = hostViewController else { return }
    viewController.didMove(toParent: containerViewController)
  }

  public func willDisappear() {
    guard viewController.data != nil else { return }
    viewController.beginAppearanceTransition(false, animated: true)
  }

  public func didDisappear() {
    guard viewController.data != nil else { return }

    viewController.willMove(toParent: nil)
    viewController.removeFromParent()
    viewController.view.removeFromSuperview()

    viewController.endAppearanceTransition()
  }
}
