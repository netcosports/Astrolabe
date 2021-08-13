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

class CollectionViewDataSource<
  CellView: UICollectionViewCell,
  SectionState: Hashable,
  CellState: Hashable
>: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate where CellView: ReusableView, CellView.Container == UICollectionView {

  var sections: [Section<SectionState, CellState>] = []

  var lastCellDisplayed: VoidClosure?
  var lastCellСondition: LastCellConditionClosure?

  var setupCell: ((CellView, Cell<CellState>) -> ())?
  var setupSupplementary: ((CellView, Cellable) -> ())?

  var cellSelected: ((Cell<CellState>, IndexPath) -> ())?
  var supplementarySelected: ((Cell<SectionState>, IndexPath) -> ())?

  var disabledForReorderCells: [CellState] = []

  #if os(tvOS)
  public let focusedItem = BehaviorRelay<Int>(value: 0)
  #endif

  internal func setupCellable(
    cellView: CellView,
    collectionView: UICollectionView,
    cell: Cellable,
    indexPath: IndexPath
  ) {
    cellView.hostContainerView = collectionView
    cellView.indexPath = indexPath
    cellView.cell = cell
  }

  internal func instanceCellable<State: Hashable>(
    cell: Cell<State>,
    collectionView: UICollectionView,
    indexPath: IndexPath
  ) -> CellView {
    let cellView: CellView = cell.cell.instance(for: collectionView, index: indexPath)
    setupCellable(cellView: cellView, collectionView: collectionView, cell: cell.cell, indexPath: indexPath)
    // FIXME: bind actions inside
    cell.cell.setup(with: cellView)
    return cellView
  }

  internal func instanceCell(
    cell: Cell<CellState>,
    collectionView: UICollectionView,
    indexPath: IndexPath
  ) -> CellView {
    let cellView = instanceCellable(
      cell: cell,
      collectionView: collectionView,
      indexPath: indexPath
    )
    setupCell?(cellView, cell)
    return cellView
  }

  internal func instanceSupplementary(
    cell: Cellable,
    collectionView: UICollectionView,
    indexPath: IndexPath
  ) -> CellView {
    let cellView: CellView = cell.instance(for: collectionView, index: indexPath)
    setupCellable(cellView: cellView, collectionView: collectionView, cell: cell, indexPath: indexPath)
    // FIXME: bind actions inside
    cell.setup(with: cellView)
    setupSupplementary?(cellView, cell)
    return cellView
  }

  open func numberOfSections(in collectionView: UICollectionView) -> Int {
    return sections.count
  }

  open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let section = sections[section]
    return section.cells.count
  }

  open func collectionView(_ collectionView: UICollectionView,
                           cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let section = sections[indexPath.section]
    let cell = section.cells[indexPath.item]
    return instanceCell(
      cell: cell,
      collectionView: collectionView,
      indexPath: indexPath
    )
  }

  open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                           at indexPath: IndexPath) -> UICollectionReusableView {
    let sectionIndex: Int
    if indexPath.count == 1 {
      sectionIndex = indexPath[0]
    } else {
      sectionIndex = indexPath.section
    }
    let section = sections[sectionIndex]
    var type = CellType.header
    switch kind {
    case UICollectionView.elementKindSectionHeader:
      type = .header
    case UICollectionView.elementKindSectionFooter:
      type = .footer
    default:
      type = .custom(kind: kind)
    }
    var targetSupplementary: Cellable?
    let supplementaries = section.supplementaries(for: type)
    if indexPath.count == 1 {
      targetSupplementary = supplementaries.first
    } else if indexPath.item < supplementaries.count {
      targetSupplementary = supplementaries[indexPath.item]
    }
    guard let supplementary = targetSupplementary else {
      fatalError("Section does not have supplementary view of kind \(kind)")
    }
    return instanceSupplementary(
      cell: supplementary,
      collectionView: collectionView,
      indexPath: indexPath
    )
  }

  open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let section = sections[indexPath.section]
    let cell = section.cells[indexPath.item]
    cell.cell.handleClickEvent()
    cellSelected?(cell, indexPath)
  }

  open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                           sizeForItemAt indexPath: IndexPath) -> CGSize {
    let section = sections[indexPath.section]
    let cell = section.cells[indexPath.item]
    return cell.cell.size(with: collectionView)
  }

  open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                           referenceSizeForHeaderInSection section: Int) -> CGSize {
    let section = sections[section]
    guard let header = section.supplementaries(for: .header).first else {
      return CGSize.zero
    }
    return header.size(with: collectionView)
  }

  open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                           referenceSizeForFooterInSection section: Int) -> CGSize {
    let section = sections[section]
    guard let header = section.supplementaries(for: .footer).first else {
      return CGSize.zero
    }
    return header.size(with: collectionView)
  }

  open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
                           forItemAt indexPath: IndexPath) {
    if lastCellСondition?(indexPath,
                           collectionView.numberOfSections - 1,
                           collectionView.numberOfItems(inSection: indexPath.section) - 1) ?? false {
      lastCellDisplayed?()
    }

    (cell as? CellView)?.willDisplay()
  }

  open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell,
                           forItemAt indexPath: IndexPath) {
    (cell as? CellView)?.endDisplay()
  }

  open func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
    (view as? CellView)?.willDisplay()
  }

  open func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
    (view as? CellView)?.endDisplay()
  }

  open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                           insetForSectionAt section: Int) -> UIEdgeInsets {
    let section = sections[section]
    if let inset = section.inset {
      return inset
    } else if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
      return layout.sectionInset
    } else {
      return .zero
    }
  }

  open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    let section = sections[section]
    if let minimumLineSpacing = section.minimumLineSpacing {
      return minimumLineSpacing
    } else if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
      return layout.minimumLineSpacing
    } else {
      return 0.0
    }
  }

  open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    let section = sections[section]
    if let minimumInteritemSpacing = section.minimumInteritemSpacing {
      return minimumInteritemSpacing
    } else if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
      return layout.minimumInteritemSpacing
    } else {
      return 0.0
    }
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    guard let subviews = gestureRecognizer.view?.subviews else { return true }
    if let scrollView = subviews.compactMap({ self.scrollView(in: $0) }).first {
      gestureRecognizer.require(toFail: scrollView.panGestureRecognizer)
    }
    return true
  }

  private func scrollView(in view: UIView) -> UIScrollView? {
    if let scrollView = view as? UIScrollView {
      return scrollView
    }
    if let scrollView = view.subviews.compactMap({ self.scrollView(in: $0) }).first {
      return scrollView
    }
    return nil
  }

  open func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
    let section = sections[indexPath.section]
    let cell = section.cells[indexPath.item]
    return !disabledForReorderCells.contains(cell.state)
  }

  open func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    guard var section = sections.first else {
      return
    }
    var cells = section.cells
    let cell = cells.remove(at: sourceIndexPath.item)
    cells.insert(cell, at: destinationIndexPath.item)
    section.cells = cells
    self.sections = [section]
  }

  #if os(tvOS)

  open func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
    return true
  }

  open func collectionView(_ collectionView: UICollectionView,
                           didUpdateFocusIn context: UICollectionViewFocusUpdateContext,
                           with coordinator: UIFocusAnimationCoordinator) {
    if let focusedIndex = context.nextFocusedIndexPath?.item {
      focusedItem.accept(focusedIndex)
    }
  }
  #endif
}

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
    containerView?.backgroundColor = .clear
    containerView?.dataSource = dataSource
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
}

public typealias CollectionViewSource<
  SectionState: Hashable,
  CellState: Hashable
> = GenericCollectionViewSource<CollectionViewCell, SectionState, CellState>
