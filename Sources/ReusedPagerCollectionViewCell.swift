//
//  ReusedPagerCollectionViewCell.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/4/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

public final class ReusedPagerCollectionViewCell<Controller: UIViewController>:
  CollectionViewCell, Reusable, Eventable,
  PagerSourceCell where Controller: ReusedData & Eventable {

  public let eventSubject = PublishSubject<Event>()
  public var data: Controller.Data?

  public typealias Event = Controller.Event
  public typealias Data = Controller.Data

  public var viewController = Controller()
  public let disposeBag = DisposeBag()

  public override func setup() {
    super.setup()
    eventSubject
      .bind(to: viewController.eventSubject)
      .disposed(by: disposeBag)
  }

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

  private func setupChildView() {
    viewController.beginAppearanceTransition(true, animated: true)

    hostViewController?.addChild(viewController)
    contentView.addSubview(viewController.view)

    viewController.view.translatesAutoresizingMaskIntoConstraints = false
    contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[content]|", metrics: nil,
                                                              views: ["content": viewController.view as Any]))
    contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[content]|", metrics: nil,
                                                              views: ["content": viewController.view as Any]))
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
