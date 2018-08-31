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

public protocol PagerSourceCell: class {

  func willAppear(isCancelled: Bool)
  func didAppear()
  func willDisappear()
  func didDisappear()
}

open class CollectionViewReusedPagerSource: CollectionViewSource {

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

  override public class var defaultLayout: UICollectionViewFlowLayout {
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
  fileprivate let disposeBag = DisposeBag()
  fileprivate var selectedItem = BehaviorSubject<Int>(value: 0)

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

extension Reactive where Base: CollectionViewReusedPagerSource {

  public var selectedItem: ControlProperty<Int> {
    return ControlProperty(values: base.selectedItem.asObservable(),
                           valueSink: base.selectedItem)
  }
}
