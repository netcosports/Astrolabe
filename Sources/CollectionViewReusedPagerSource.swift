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

public protocol PagerSourceCell: AnyObject {

  func willAppear(isCancelled: Bool)
  func didAppear()
  func willDisappear()
  func didDisappear()
}

open class CollectionViewReusedPagerSource<
  SectionState: Hashable,
  CellState: Hashable
>: CollectionViewSource<SectionState, CellState> {

  override open var containerView: UICollectionView? {
    didSet {
      internalInit()
    }
  }

  fileprivate func internalInit() {
    guard let containerView = containerView else { return }
    containerView.isPagingEnabled = true
    containerView.bounces = false
    if #available(iOS 10.0, tvOS 10.0, *) {
      containerView.isPrefetchingEnabled = false
    }

    selectedItem.asObservable().skip(1).observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] index in
        guard let `self` = self else { return }
        guard let containerView = self.containerView else { return }

        let offset: CGPoint
        if UIView.userInterfaceLayoutDirection(for: containerView.semanticContentAttribute) == .rightToLeft {
          offset = CGPoint(x: containerView.contentSize.width - CGFloat(index + 1) * containerView.frame.width, y: 0)
        } else {
          offset = CGPoint(x: CGFloat(index) * containerView.frame.width, y: 0)
        }
        if offset == containerView.contentOffset { return }

        containerView.setContentOffset(offset, animated: true)
        containerView.isUserInteractionEnabled = false
      }).disposed(by: disposeBag)

    containerView.rx.willBeginDragging.subscribe(onNext: { [weak self] in
      self?.beginAppearanceTransition()
    }).disposed(by: disposeBag)

    containerView.rx.didEndDecelerating.subscribe(onNext: { [weak self] in
      self?.finishAppearanceTransition()
    }).disposed(by: disposeBag)

    containerView.rx.didEndScrollingAnimation.subscribe(onNext: { [weak self] in
      self?.finishAppearanceTransition()
    }).disposed(by: disposeBag)

    containerView.rx.didScroll.subscribe(onNext: { [weak self] in
      guard let self = self else { return }
      guard let containerView = self.containerView else { return }
      guard let disappearing = self.disappearing else { return self.beginAppearanceTransition() }

      let visibleCells = containerView.visibleCells

      if visibleCells.count == 2 {
        if let appearing = self.appearing {
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
          self.appearing = newIndexPaths[0] as? PagerCell

          disappearing.willDisappear()
          self.appearing?.willAppear(isCancelled: false)
        }
      }
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

  typealias PagerCell = PagerSourceCell & UICollectionViewCell

  private weak var appearing: PagerCell?
  private weak var disappearing: PagerCell?
  fileprivate let disposeBag = DisposeBag()

  fileprivate let selectedItem = BehaviorSubject<Int>(value: 0)

  private func beginAppearanceTransition() {
    guard let containerView = containerView else { return }

    let visibleCells = containerView.visibleCells
    guard !visibleCells.isEmpty else { return }

    if let appearing = appearing {
      disappearing = visibleCells.first { $0 != appearing } as? PagerCell
    } else {
      disappearing = visibleCells[0] as? PagerCell
    }
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

    let page: Int
    if UIView.userInterfaceLayoutDirection(for: containerView.semanticContentAttribute) == .rightToLeft {
      page = Int((containerView.contentSize.width - containerView.contentOffset.x -  containerView.frame.width) / containerView.frame.width)
    } else {
      page = Int(containerView.contentOffset.x / containerView.frame.width)
    }

    selectedItem.onNext(page)
    containerView.isUserInteractionEnabled = true
  }

  struct Reactive<SectionState: Hashable, CellState: Hashable> {
    let base: CollectionViewReusedPagerSource<SectionState, CellState>

    fileprivate init(_ base: CollectionViewReusedPagerSource<SectionState, CellState>) {
      self.base = base
    }
  }

  var reactive: Reactive<SectionState, CellState> {
    return Reactive(self)
  }
}

extension CollectionViewReusedPagerSource: ReactiveCompatible {}
extension CollectionViewReusedPagerSource.Reactive {

  public var selectedItem: ControlProperty<Int> {
    return ControlProperty(
      values: base.selectedItem.asObservable(),
      valueSink: base.selectedItem
    )
  }
}
