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

  override open var containerView: UICollectionView? {
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
        guard let `self` = self else { return }
        guard let containerView = self.containerView else { return }

        let offset = CGPoint(x: CGFloat(index) * containerView.frame.width, y: 0)
        if offset == containerView.contentOffset { return }

        containerView.setContentOffset(offset, animated: true)
        containerView.isUserInteractionEnabled = false
      }).disposed(by: disposeBag)

    if let collectionView = containerView as? CollectionView<CollectionViewPagerSource> {
      collectionView.sizeDidChange.skip(1).subscribe(onNext: { [weak self] _ in
        guard let `self` = self else { return }
        self.finishAppearanceTransitionIfNeeded()
      }).disposed(by: disposeBag)
    }
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

  typealias PagerCell = PagerSourceCell & UICollectionViewCell

  private weak var appearing: PagerCell?
  private weak var disappearing: PagerCell?

  open override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    beginAppearanceTransition()
  }

  open override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard let containerView = containerView else { return }
    guard let disappearing = disappearing else { return beginAppearanceTransition() }

    let visibleCells = containerView.visibleCells

    if visibleCells.count == 2 {
      if let appearing = appearing {
        let newCells = visibleCells.filter { $0 != disappearing && $0 != appearing }

        guard newCells.count == 1 else { return }

        if visibleCells.contains(appearing) {
          disappearing.didDisappear()
          appearing.willDisappear()

          self.disappearing = appearing
          self.appearing = newCells[0] as? PagerCell
          self.appearing?.willAppear(isCancelled: false)
        } else if visibleCells.contains(disappearing) {
          appearing.willDisappear()
          appearing.didDisappear()

          self.appearing = newCells[0] as? PagerCell
          self.appearing?.willAppear(isCancelled: false)
        } else {
          print("\(#file):\(#line) WAT")
        }
      } else {
        let newIndexPaths = visibleCells.filter { $0 != disappearing }

        guard newIndexPaths.count == 1 else { return assertionFailure() }
        appearing = newIndexPaths[0] as? PagerCell

        disappearing.willDisappear()
        appearing?.willAppear(isCancelled: false)
      }
    }
  }

  open override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    finishAppearanceTransition()
  }

  open override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    finishAppearanceTransition()
  }

  private func beginAppearanceTransition() {
    guard let containerView = containerView else { return }

    let visibleCells = containerView.visibleCells
    guard !visibleCells.isEmpty else { return }

    disappearing = visibleCells[0] as? PagerCell
  }

  private func finishAppearanceTransitionIfNeeded() {
    guard containerView != nil else { return }
    guard disappearing != nil || appearing != nil else { return }
    finishAppearanceTransition()
  }

  private func finishAppearanceTransition() {
    guard let containerView = containerView else { return }

    if let visible = containerView.visibleCells.min(by: {
      abs($0.frame.origin.x - containerView.contentOffset.x) < abs($1.frame.origin.x - containerView.contentOffset.x)
    }) {
      if visible == appearing {
        disappearing?.didDisappear()
        disappearing = nil

        appearing?.didAppear()
        appearing = nil
      } else if visible == disappearing {
        appearing?.willDisappear()
        appearing?.didDisappear()
        appearing = nil

        disappearing?.willAppear(isCancelled: true)
        disappearing?.didAppear()
        disappearing = nil
      } else {
        print("\(#file):\(#line) WAT")
      }
    } else {
      print("\(#file):\(#line) WAT")
    }

    let page = Int(containerView.contentOffset.x / containerView.frame.width)

    selectedItem.onNext(page)
    containerView.isUserInteractionEnabled = true
  }
}

extension Reactive where Base: CollectionViewPagerSource {

  public var selectedItem: ControlProperty<Int> {
    return ControlProperty(values: base.selectedItem.asObservable(),
                           valueSink: base.selectedItem)
  }
}
