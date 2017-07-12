//
//  CollectionViewPagerSource.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 11/8/16.
//  Copyright © 2016 Netcosports. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

public struct Page {
  public let controller: UIViewController
  public let id: String

  public init(controller: UIViewController, id: String) {
    self.controller = controller
    self.id = id
  }
}

public protocol CollectionViewPager: class {
  var pages: [Page] { get }
}

open class CollectionViewPagerSource: CollectionViewSource {

  typealias PageCell = CollectionCell<PagerCollectionViewCell>
  fileprivate weak var pager: CollectionViewPager?
  fileprivate var selectedItem = BehaviorSubject<Int>(value: 0)
  let disposeBag = DisposeBag()

  public init(hostViewController: UIViewController? = nil,
              layout: UICollectionViewFlowLayout = CollectionViewPagerSource.defaultLayout(),
              pager: CollectionViewPager) {
    self.pager = pager
    super.init(hostViewController: hostViewController, layout: layout)

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

        strongSelf.containerView.setContentOffset(offset, animated: true)
        strongSelf.containerView.isUserInteractionEnabled = false
      }).addDisposableTo(disposeBag)
  }

  public func reloadData() {
    guard let pager = pager else { return }

    let cells: [Cellable] = pager.pages.map {
      PageCell(data: PagerViewModel(viewController: $0.controller, cellId: $0.id))
    }
    sections = [Section(cells: cells)]
    containerView.reloadData()
  }

  static func defaultLayout() -> UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    layout.sectionInset = UIEdgeInsets.zero
    layout.scrollDirection = .horizontal
    return layout
  }

  public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    let page = Int(containerView.contentOffset.x / containerView.frame.width)
    selectedItem.onNext(page)
    containerView.isUserInteractionEnabled = true
  }

  public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    containerView.isUserInteractionEnabled = true
  }
}

extension Reactive where Base: CollectionViewPagerSource {

  public var selectedItem: ControlProperty<Int> {
    return ControlProperty(values: base.selectedItem.asObservable(),
                           valueSink: base.selectedItem)
  }
}
