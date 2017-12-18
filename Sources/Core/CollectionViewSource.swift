//
//  CollectionViewSource.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 11/1/16.
//  Copyright © 2016 Netcosports. All rights reserved.
//

import UIKit
import RxSwift

open class GenericCollectionViewSource<CellView: UICollectionViewCell>: NSObject, ReusableSource,
UICollectionViewDataSource, UICollectionViewDelegateFlowLayout where CellView: ReusableView, CellView.Container == UICollectionView {

  public typealias Container = UICollectionView

  public required override init() {
    super.init()
  }

  open weak var containerView: Container? {
    didSet {
      internalInit()
    }
  }

  public weak var hostViewController: UIViewController?
  public var sections: [Sectionable] = [] {
    didSet {
      registerCellsForSections()
    }
  }
  public var lastCellDisplayed: VoidClosure?
  public var selectedCellIds: Set<String> = []
  public var selectionBehavior: SelectionBehavior = .single
  public var selectionManagement: SelectionManagement = .none
#if os(tvOS)
  public let focusedItem = Variable<Int>(0)
#endif

  fileprivate func internalInit() {
    containerView?.backgroundColor = .clear
    containerView?.dataSource = self
    containerView?.delegate = self
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

  internal func setupCell(cellView: CellView, cell: Cellable, indexPath: IndexPath) {
    cellView.containerViewController = hostViewController
    cellView.containerView = containerView
    cellView.indexPath = indexPath
    cellView.selectedState = selectedCellIds.contains(cell.id)
    cellView.cell = cell
  }

  internal func instance(cell: Cellable, collectionView: UICollectionView, indexPath: IndexPath) -> CellView {
    let cellView: CellView = cell.instance(for: collectionView, index: indexPath)
    setupCell(cellView: cellView, cell: cell, indexPath: indexPath)
    cell.setup(with: cellView)
    return cellView
  }

  public func numberOfSections(in collectionView: UICollectionView) -> Int {
    return sections.count
  }

  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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
    case UICollectionElementKindSectionHeader:
      type = .header
    case UICollectionElementKindSectionFooter:
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
    if selectionManagement == .automatic {
      processSelection(for: cell.id)
      containerView?.reloadData()
    }
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

  public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
                           forItemAt indexPath: IndexPath) {
    if indexPath.section == collectionView.numberOfSections - 1
         && indexPath.item == collectionView.numberOfItems(inSection: indexPath.section) - 1 {
      lastCellDisplayed?()
    }

    (cell as? CellView)?.willDisplay()
  }

  public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell,
                           forItemAt indexPath: IndexPath) {
    (cell as? CellView)?.endDisplay()
  }

  public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
    (view as? CellView)?.willDisplay()
  }

  public func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
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

  public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    let section = sections[section]
    if let minimumLineSpacing = section.minimumLineSpacing {
      return minimumLineSpacing
    } else if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
      return layout.minimumLineSpacing
    } else {
      return 0.0
    }
  }

  public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    let section = sections[section]
    if let minimumInteritemSpacing = section.minimumInteritemSpacing {
      return minimumInteritemSpacing
    } else if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
      return layout.minimumInteritemSpacing
    } else {
      return 0.0
    }
  }

  open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
  }

  open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
  }

#if os(tvOS)

  open func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
    return true
  }

  open func collectionView(_ collectionView: UICollectionView,
                           didUpdateFocusIn context: UICollectionViewFocusUpdateContext,
                           with coordinator: UIFocusAnimationCoordinator) {
    if let focusedIndex = context.nextFocusedIndexPath?.item {
      focusedItem.value = focusedIndex
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

  class var defaultLayout: UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    layout.sectionInset = UIEdgeInsets.zero
    layout.scrollDirection = .vertical
    return layout
  }
}

public typealias CollectionViewSource = GenericCollectionViewSource<CollectionViewCell>
