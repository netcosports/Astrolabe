//
//  ReusableView.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/9/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

public enum TargetScrollPosition {
  case start
  case end
  case center
}

public protocol ReusableView: AnyObject {
  associatedtype Container: ContainerView

  func setup()

  var contentView: UIView { get }
  var cell: Cellable? { get set }

  var hostViewController: UIViewController? { get set }
  var hostContainerView: Container? { get set }
  var indexPath: IndexPath? { get set }

  var selectedState: Bool { get set }
  var expandedState: Bool { get set }

  func willDisplay()
  func endDisplay()
}

public protocol ContainerView: AnyObject {
  func register<T: ReusableView>(type: CellType, cellClass: T.Type, identifier: String)
  func instance<T: ReusableView>(type: CellType, index: IndexPath, identifier: String) -> T

  var size: CGSize { get }
  var visibleItems: [IndexPath]? { get }

  func reloadData()
  var backgroundView: UIView? { get set }

  func insert(at indexes: [IndexPath])
  func delete(at indexes: [IndexPath])
  func reload(at indexes: [IndexPath])
  func insertSectionables(at indexes: IndexSet)
  func deleteSectionables(at indexes: IndexSet)
  func reloadSectionables(at indexes: IndexSet)

  typealias CompletionClosure = (Bool) -> Void
  func batchUpdate(block: VoidClosure, completion: CompletionClosure?)
  
  func scroll(to index: IndexPath, at position: TargetScrollPosition, animated: Bool)
}

extension UICollectionView: ContainerView {
  public var size: CGSize {
    return frame.size
  }

  public var visibleItems: [IndexPath]? {
    return indexPathsForVisibleItems
  }

  public func register<T: ReusableView>(type: CellType, cellClass: T.Type, identifier: String) {
    switch type {
    case .cell:
      register(cellClass, forCellWithReuseIdentifier: identifier)
    case .header:
      register(cellClass, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
               withReuseIdentifier: identifier)
    case .footer:
      register(cellClass, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
               withReuseIdentifier: identifier)
    case .custom(let kind):
      register(cellClass, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
    }
  }

  public func instance<T: ReusableView>(type: CellType, index: IndexPath, identifier: String) -> T {
    switch type {
    case .cell:
      let instance = dequeueReusableCell(withReuseIdentifier: identifier, for: index as IndexPath)
      guard let cellView = instance as? T else {
        fatalError("\(T.self) is not registred")
      }
      return cellView

    case .header:
      let instance = dequeueReusableSupplementaryView(
        ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: identifier, for: index as IndexPath)
      guard let supplementaryView = instance as? T else {
        fatalError("\(T.self) is not registred")
      }
      return supplementaryView

    case .footer:
      let instance = dequeueReusableSupplementaryView(
        ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: identifier, for: index as IndexPath)
      guard let supplementaryView = instance as? T else {
        fatalError("\(T.self) is not registred")
      }
      return supplementaryView

    case .custom(let kind):
      let instance = dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier,
                                                      for: index as IndexPath)
      guard let supplementaryView = instance as? T else {
        fatalError("\(T.self) is not registred")
      }
      return supplementaryView
    }
  }

  public func insert(at indexes: [IndexPath]) {
    insertItems(at: indexes)
  }

  public func delete(at indexes: [IndexPath]) {
    deleteItems(at: indexes)
  }

  public func reload(at indexes: [IndexPath]) {
    reloadItems(at: indexes)
  }

  public func insertSectionables(at indexes: IndexSet) {
    insertSections(indexes)
  }

  public func deleteSectionables(at indexes: IndexSet) {
    deleteSections(indexes)
  }

  public func reloadSectionables(at indexes: IndexSet) {
    reloadSections(indexes)
  }

  public func batchUpdate(block: VoidClosure, completion: CompletionClosure?) {
    performBatchUpdates(block, completion: completion)
  }
  
  public func scroll(to index: IndexPath, at position: TargetScrollPosition, animated: Bool) {
    let vertical = ((collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection ?? .vertical) == .vertical
    switch position {
    case .center:
      scrollToItem(at: index, at: vertical ? .centeredVertically : .centeredHorizontally , animated: animated)
    case .start:
      scrollToItem(at: index, at: vertical ? .top : .left , animated: animated)
    case .end:
      scrollToItem(at: index, at: vertical ? .bottom : .right , animated: animated)
    }
  }
}

extension UITableView: ContainerView {
  public var size: CGSize {
    return frame.size
  }

  public var visibleItems: [IndexPath]? {
    return indexPathsForVisibleRows
  }

  public func register<T: ReusableView>(type: CellType, cellClass: T.Type, identifier: String) {
    switch type {
    case .cell:
      register(cellClass, forCellReuseIdentifier: identifier)
    case .header, .footer:
      register(cellClass, forHeaderFooterViewReuseIdentifier: identifier)
    case .custom:
      fatalError("Unsupported type for table view")
    }
  }

  public func instance<T: ReusableView>(type: CellType, index: IndexPath, identifier: String) -> T {
    switch type {
    case .cell:
      let instance = dequeueReusableCell(withIdentifier: identifier, for: index)
      guard let cellView = instance as? T else {
        fatalError("\(T.self) is not registred")
      }
      return cellView

    case .header, .footer:
      let instance = dequeueReusableHeaderFooterView(withIdentifier: identifier)
      guard let supplementaryView = instance as? T else {
        fatalError("\(T.self) is not registred")
      }
      return supplementaryView

    case .custom:
      fatalError("Unsupported type for table view")
    }
  }

  public func insert(at indexes: [IndexPath]) {
    insertRows(at: indexes, with: .top)
  }

  public func delete(at indexes: [IndexPath]) {
    deleteRows(at: indexes, with: .top)
  }

  public func reload(at indexes: [IndexPath]) {
    reloadRows(at: indexes, with: .automatic)
  }

  public func insertSectionables(at indexes: IndexSet) {
    insertSections(indexes, with: .top)
  }

  public func deleteSectionables(at indexes: IndexSet) {
    deleteSections(indexes, with: .top)
  }

  public func reloadSectionables(at indexes: IndexSet) {
    reloadSections(indexes, with: .automatic)
  }

  public func batchUpdate(block: VoidClosure, completion: CompletionClosure? = nil) {
    if #available(iOS 11.0, tvOS 11.0, *) {
      performBatchUpdates(block, completion: completion)
    } else {
      CATransaction.begin()
      CATransaction.setCompletionBlock {
        completion?(true)
      }

      beginUpdates()
      block()
      endUpdates()
      CATransaction.commit()
    }
  }
  
  public func scroll(to index: IndexPath, at position: TargetScrollPosition, animated: Bool) {
    switch position {
    case .center:
      scrollToRow(at: index, at: .middle, animated: animated)
    case .start:
      scrollToRow(at: index, at: .top, animated: animated)
    case .end:
      scrollToRow(at: index, at: .bottom, animated: animated)
    }
  }
}

extension ContainerView {

  public func apply(
    newContext: CollectionUpdateContext?,
    sectionsUpdater: VoidClosure?,
    completion: CompletionClosure? = nil
  ) {
      if let context = newContext {
        self.batchUpdate(block: {
          sectionsUpdater?()
          self.deleteSectionables(at: context.deletedSections)
          self.delete(at: context.deleted)
          self.reloadSectionables(at: context.updatedSections)
          self.reload(at: context.updated)
          self.insertSectionables(at: context.insertedSections)
          self.insert(at: context.inserted)
        }, completion: completion)
      } else {
        self.reloadData()
      }
    }
}

extension ReusableSource {

  public func appply(
    sections: [Sectionable],
    completion: ContainerView.CompletionClosure? = nil
  ) {
    let currectSections = self.sections
    do {
      let context = try DiffUtils.diffOrThrow(new: sections, old: currectSections)
      self.containerView?.apply(
        newContext: context,
        sectionsUpdater: { [weak self] in
          self?.sections = sections
        },
        completion: completion
      )
    } catch {
      self.sections = sections
      self.containerView?.reloadData()
    }
  }
}
