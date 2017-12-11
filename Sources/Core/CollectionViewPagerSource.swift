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
  func section(with cells: [Cellable]) -> Sectionable
}

public extension CollectionViewPager {

  func section(with cells: [Cellable]) -> Sectionable {
    return Section(cells: cells)
  }

}

open class CollectionViewPagerSource: CollectionViewSource {

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

        containerView.setContentOffset(offset, animated: true)
        containerView.isUserInteractionEnabled = false
      }).disposed(by: disposeBag)
  }

  typealias PageCell = CollectionCell<PagerCollectionViewCell>

  public weak var pager: CollectionViewPager?
  fileprivate var selectedItem = BehaviorSubject<Int>(value: 0)
  fileprivate let disposeBag = DisposeBag()

  public func reloadData() {
    guard let pager = pager else { return }

    let cells: [Cellable] = pager.pages.map {
      PageCell(data: PagerViewModel(viewController: $0.controller, cellId: $0.id))
    }
    sections = [pager.section(with: cells)]
    containerView?.reloadData()
  }

  open class var layout: UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    layout.sectionInset = UIEdgeInsets.zero
    layout.scrollDirection = .horizontal
    return layout
  }

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

extension Reactive where Base: CollectionViewPagerSource {

  public var selectedItem: ControlProperty<Int> {
    return ControlProperty(values: base.selectedItem.asObservable(),
                           valueSink: base.selectedItem)
  }
}
