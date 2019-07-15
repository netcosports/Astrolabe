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

public protocol DataSource: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

  associatedtype CellView: UICollectionViewCell
  init()

  var sections: [Sectionable] { get set }

  var lastCellDisplayed: VoidClosure? { get set }
  var lastCellСondition: LastCellConditionClosure? { get set }
  var setupCell: ((CellView, Cellable) -> ())? { get set }
  var cellSelected: ((Cellable, IndexPath) -> ())? { get set }
}

open class CollectionViewDataSource<CellView: UICollectionViewCell>: NSObject, DataSource, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout where CellView: ReusableView, CellView.Container == UICollectionView {

  required public override init() {}
  public var sections: [Sectionable] = []

  public var lastCellDisplayed: VoidClosure?
  public var lastCellСondition: LastCellConditionClosure?
  public var setupCell: ((CellView, Cellable) -> ())?
  public var cellSelected: ((Cellable, IndexPath) -> ())?

  internal func setupCell(cellView: CellView, collectionView: UICollectionView, cell: Cellable, indexPath: IndexPath) {
    cellView.containerView = collectionView
    cellView.indexPath = indexPath
    cellView.cell = cell

    setupCell?(cellView, cell)
  }

  internal func instance(cell: Cellable, collectionView: UICollectionView, indexPath: IndexPath) -> CellView {
    let cellView: CellView = cell.instance(for: collectionView, index: indexPath)
    setupCell(cellView: cellView, collectionView: collectionView, cell: cell, indexPath: indexPath)
    cell.setup(with: cellView)
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
    return instance(cell: cell, collectionView: collectionView, indexPath: indexPath)
  }

  open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                           at indexPath: IndexPath) -> UICollectionReusableView {
    let index: Int
    if indexPath.count == 1 {
      index = indexPath[0]
    } else {
      index = indexPath.section
    }
    let section = sections[index]
    var type = CellType.header
    switch kind {
    case UICollectionView.elementKindSectionHeader:
      type = .header
    case UICollectionView.elementKindSectionFooter:
      type = .footer
    default:
      type = .custom(kind: kind)
    }
    guard let supplementary = section.supplementary(for: type) else {
      fatalError("Section does not have supplementary view of kind \(kind)")
    }
    let supplementaryView = instance(cell: supplementary, collectionView: collectionView, indexPath: indexPath)
    if supplementary.click != nil {
      supplementaryView.gestureRecognizers?.forEach { supplementaryView.removeGestureRecognizer($0) }
      let recognizer = UITapGestureRecognizer(target: self, action: #selector(actionHeaderClick))
      supplementaryView.addGestureRecognizer(recognizer)
    }
    return supplementaryView
  }

  open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let section = sections[indexPath.section]
    let cell = section.cells[indexPath.item]
    cell.click?()
    cellSelected?(cell, indexPath)
  }

  open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                           sizeForItemAt indexPath: IndexPath) -> CGSize {
    let section = sections[indexPath.section]
    let cell = section.cells[indexPath.item]
    return cell.size(with: collectionView)
  }

  open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                           referenceSizeForHeaderInSection section: Int) -> CGSize {
    let section = sections[section]
    guard let header = section.supplementary(for: .header) else {
      return CGSize.zero
    }
    return header.size(with: collectionView)
  }

  open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                           referenceSizeForFooterInSection section: Int) -> CGSize {
    let section = sections[section]
    guard let header = section.supplementary(for: .footer) else {
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

  @objc fileprivate func actionHeaderClick(recognizer: UITapGestureRecognizer) {
    if let cellView = recognizer.view as? CellView {
      if let click = cellView.cell?.click {
        click()
      }
    }
  }
}

//open class GenericCollectionViewSource<CellView: UICollectionViewCell>: ReusableSource where CellView:
//ReusableView, CellView.Container == UICollectionView {
//
//}

open class GenericDataSourceCollectionViewSource<T: DataSource, CellView: UICollectionViewCell>: ReusableSource where CellView: ReusableView, CellView.Container == UICollectionView, CellView == T.CellView {

  public required init() {}

  public typealias Container = UICollectionView

  public let dataSource = T()

  open weak var containerView: Container? {
    didSet {
      internalInit()
    }
  }

  public weak var hostViewController: UIViewController?
  public var sections: [Sectionable] = [] {
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
  public var selectedCellIds: Set<String> = []
  public var selectionBehavior: SelectionBehavior = .single
  public var selectionManagement: SelectionManagement = .none
#if os(tvOS)
  public let focusedItem = BehaviorRelay<Int>(value: 0)
#endif

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
  }

  func setup(cellView: CellView, with cell: Cellable) {
    cellView.containerViewController = hostViewController
    cellView.selectedState = selectedCellIds.contains(cell.id)
  }

  func click(cell: Cellable, indexPath: IndexPath) {
    if selectionManagement == .automatic {
      processSelection(for: cell.id)
      containerView?.reloadData()
    }
  }

  public func registerCellsForSections() {
    guard let containerView = containerView else { return }
    sections.forEach { section in
      section.supplementaryTypes.forEach {
        if let supplementary = section.supplementary(for: $0) {
          supplementary.register(in: containerView)
        }
      }
      section.cells.forEach { cell in
        cell.register(in: containerView)
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
}

public typealias GenericCollectionViewSource<CellView: UICollectionViewCell & ReusableView> = GenericDataSourceCollectionViewSource<CollectionViewDataSource<CellView>, CellView> where CellView.Container == UICollectionView
public typealias CollectionViewSource = GenericCollectionViewSource<CollectionViewCell>
