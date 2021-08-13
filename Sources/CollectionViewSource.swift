//
//  CollectionViewSource.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 11/1/16.
//  Copyright © 2016 Netcosports. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

open class GenericCollectionViewSource<
  CellView: UICollectionViewCell,
  SectionState: Hashable,
  CellState: Hashable
>: ReusableSource where CellView: ReusableView, CellView.Container == UICollectionView {

  public required init() {}

  public typealias Container = UICollectionView

  let dataSource = CollectionViewDataSource<CellView, SectionState, CellState>()

  open weak var containerView: Container? {
    didSet {
      internalInit()
    }
  }

  public weak var hostViewController: UIViewController?
  public var sections: [Section<SectionState, CellState>] = [] {
    didSet {
      dataSource.sections = sections
      registerCellsForSections()
    }
  }
  public var lastCellDisplayed: VoidClosure? {
    didSet {
      dataSource.lastCellDisplayed = lastCellDisplayed
    }
  }
  public var lastCellСondition: LastCellConditionClosure? {
    didSet {
      dataSource.lastCellСondition = lastCellСondition
    }
  }
  public var selectedCellStates: Set<CellState> = []
  public var selectionBehavior: SelectionBehavior = .single
  public var selectionManagement: SelectionManagement = .none
  #if os(tvOS)
  public let focusedItem = BehaviorRelay<Int>(value: 0)
  private let disposeBag = DisposeBag()
  #endif

  // NOTE: property to pass current sections from the datasource
  // it could be different with the one in a sections because of reordering feature
  public var orderedSections: [Section<SectionState, CellState>] {
    return dataSource.sections
  }

  public var disabledForReorderCells: [CellState] = [] {
    didSet {
      dataSource.disabledForReorderCells = disabledForReorderCells
    }
  }

  fileprivate func internalInit() {
    dataSource.containerView = containerView
    containerView?.backgroundColor = .clear
    if #available(iOS 13.0, *) {
      containerView?.dataSource = dataSource.diffableDataSource
    } else {
      containerView?.dataSource = dataSource
    }
    containerView?.delegate = dataSource

    dataSource.cellSelected = { [weak self] cell, indexPath in
      self?.click(cell: cell, indexPath: indexPath)
    }

    dataSource.setupCell = { [weak self] cellView, cell in
      self?.setup(cellView: cellView, with: cell)
    }
    let recognizer = UITapGestureRecognizer(target: self, action: #selector(actionHeaderClick))
    recognizer.cancelsTouchesInView = false
    recognizer.delegate = dataSource
    containerView?.addGestureRecognizer(recognizer)

    #if os(tvOS)
    dataSource.focusedItem.bind(to: focusedItem).disposed(by: disposeBag)
    #endif
  }

  func setup(cellView: CellView, with cell: Cell<CellState>) {
    cellView.hostViewController = hostViewController
    cellView.selectedState = selectedCellStates.contains(cell.state)
  }

  func click(cell: Cell<CellState>, indexPath: IndexPath) {
    if selectionManagement == .automatic {
      processSelection(for: cell.state)
      containerView?.reloadData()
    }
  }

  public func registerCellsForSections() {
    guard let containerView = containerView else { return }
    sections.forEach { section in
      section.supplementaryTypes.forEach { type in
        let supplementaries = section.supplementaries(for: type)
        supplementaries.forEach {
          $0.register(in: containerView)
        }
      }
      section.cells.forEach { cell in
        cell.cell.register(in: containerView)
      }
    }
  }

  class var defaultLayout: UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    layout.sectionInset = UIEdgeInsets.zero
    layout.scrollDirection = .vertical
    return layout
  }

  @objc fileprivate func actionHeaderClick(recognizer: UITapGestureRecognizer) {
    var view: UIScrollView? = containerView

    while view != nil {
      if let cell = supplementary(in: view, at: recognizer.location(in: view)) {
        cell.handleClickEvent()
      }
      view = parentScrollView(of: view?.superview)
    }
  }

  private func supplementary(in scrollView: UIScrollView?, at point: CGPoint) -> Cellable? {
    guard let scrollView = scrollView else { return nil }
    return scrollView.subviews
      .filter({ $0.frame.contains(point) })
      .filter( { $0.alpha > 0.0 && !$0.isHidden })
      .compactMap({ ($0 as? CellView)?.cell }).first(where: {
        switch $0.type {
        case .custom, .footer, .header:
          return true
        default:
          return false
        }
      })
  }

  private func parentScrollView(of scrollView: UIView?) -> UIScrollView? {
    var view = scrollView
    while view != nil {
      if let scrollView = view as? UIScrollView {
        return scrollView
      }
      view = view?.superview
    }
    return nil
  }

  public func apply(
    sections: [Section<SectionState, CellState>],
    completion: ContainerView.CompletionClosure? = nil
  ) {
    if #available(iOS 13.0, *) {
      self.sections = sections
      var newSnapshot = NSDiffableDataSourceSnapshot<SectionState, CellState>()
      newSnapshot.appendSections(sections.map { $0.state })
      sections.forEach { section in
        newSnapshot.appendItems(section.cells.map { $0.state }, toSection: section.state)
      }
      self.dataSource.diffableDataSource.apply(newSnapshot)
    } else {
      let currectSections = self.sections
      let context = DiffUtils<SectionState, CellState>.diff(new: sections, old: currectSections)
      self.containerView?.apply(
        newContext: context,
        sectionsUpdater: { [weak self] in
          self?.sections = sections
        },
        completion: completion
      )
    }
  }
}

public typealias CollectionViewSource<
  SectionState: Hashable,
  CellState: Hashable
> = GenericCollectionViewSource<CollectionViewCell, SectionState, CellState>
