//
//  CollectionViewReusedPagerSource.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/9/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

open class CollectionViewReusedPagerSource: CollectionViewSource {

  public required init() {
    super.init()
  }

  public required init(with containerView: ContainerView) {
    super.init(with: containerView)
    internalInit()
  }

  public init(hostViewController: UIViewController? = nil,
              layout: UICollectionViewFlowLayout = CollectionViewPagerSource.defaultLayout) {
    super.init()
    self.hostViewController = hostViewController
    self.containerView.collectionViewLayout = layout
    internalInit()
  }

  fileprivate func internalInit() {
    containerView.isPagingEnabled = true
    containerView.bounces = false
    if #available(iOS 10.0, tvOS 10.0, *) {
      containerView.isPrefetchingEnabled = false
    }

    selectedItem.asObservable().skip(1).observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] index in
        guard let strongSelf = self else { return }

        let offset = CGPoint(x: CGFloat(index) * strongSelf.containerView.frame.width, y: 0)
        if offset == strongSelf.containerView.contentOffset { return }

        strongSelf.containerView.isUserInteractionEnabled = false
        strongSelf.containerView.setContentOffset(offset, animated: true)
      }).addDisposableTo(disposeBag)
  }

  let disposeBag = DisposeBag()
  fileprivate var selectedItem = BehaviorSubject<Int>(value: 0)

  public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    let page = Int(containerView.contentOffset.x / containerView.frame.width)
    selectedItem.onNext(page)
    containerView.isUserInteractionEnabled = true
  }

  public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    containerView.isUserInteractionEnabled = true
  }
}

extension Reactive where Base: CollectionViewReusedPagerSource {

  public var selectedItem: ControlProperty<Int> {
    return ControlProperty(values: base.selectedItem.asObservable(),
                           valueSink: base.selectedItem)
  }

}
