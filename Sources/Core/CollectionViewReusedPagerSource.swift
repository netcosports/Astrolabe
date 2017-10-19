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

  override public var containerView: UICollectionView? {
    didSet {
      internalInit()
    }
  }

  fileprivate func internalInit() {
    containerView?.isPagingEnabled = true
    containerView?.bounces = false
    if #available(iOS 10.0, tvOS 10.0, *) {
      containerView?.isPrefetchingEnabled = false
    }

    selectedItem.asObservable().skip(1).observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] index in
        guard let strongSelf = self else { return }
        guard let containerView = strongSelf.containerView else { return }

        let offset = CGPoint(x: CGFloat(index) * containerView.frame.width, y: 0)
        if offset == containerView.contentOffset { return }

        containerView.isUserInteractionEnabled = false
        containerView.setContentOffset(offset, animated: true)
      }).disposed(by: disposeBag)
  }

  override public class var defaultLayout: UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    layout.sectionInset = UIEdgeInsets.zero
    layout.scrollDirection = .horizontal
    return layout
  }

  let disposeBag = DisposeBag()
  fileprivate var selectedItem = BehaviorSubject<Int>(value: 0)

  public override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    guard let containerView = containerView else { return }

    let page = Int(containerView.contentOffset.x / containerView.frame.width)
    selectedItem.onNext(page)
    containerView.isUserInteractionEnabled = true
  }

  public override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    guard let containerView = containerView else { return }
    containerView.isUserInteractionEnabled = true
  }
}

extension Reactive where Base: CollectionViewReusedPagerSource {

  public var selectedItem: ControlProperty<Int> {
    return ControlProperty(values: base.selectedItem.asObservable(),
                           valueSink: base.selectedItem)
  }

}
