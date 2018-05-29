//
//  ReusableView.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/9/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit

public protocol ReusableView: class {
  associatedtype Container: ContainerView

  func setup()

  var contentView: UIView { get }
  var cell: Cellable? { get set }

  var containerViewController: UIViewController? { get set }
  var containerView: Container? { get set }
  var indexPath: IndexPath? { get set }

  var selectedState: Bool { get set }
  var expandedState: Bool { get set }

  func willDisplay()
  func endDisplay()
}

public protocol ContainerView: class {
  func register<T: ReusableView>(type: CellType, cellClass: T.Type, identifier: String)
  func instance<T: ReusableView>(type: CellType, index: IndexPath, identifier: String) -> T

  var size: CGSize { get }
  var visibleItems: [IndexPath]? { get }

  func reloadData()
  var backgroundView: UIView? { get set }

  func insert(at indexes: [IndexPath])
  func delete(at indexes: [IndexPath])
  func reload(at indexes: [IndexPath])

  typealias CompletionClosure = (Bool) -> Void
  func batchUpdate(block: VoidClosure, completion: CompletionClosure?)
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
      register(cellClass, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
               withReuseIdentifier: identifier)
    case .footer:
      register(cellClass, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter,
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
        ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: identifier, for: index as IndexPath)
      guard let supplementaryView = instance as? T else {
        fatalError("\(T.self) is not registred")
      }
      return supplementaryView

    case .footer:
      let instance = dequeueReusableSupplementaryView(
        ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: identifier, for: index as IndexPath)
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

  public func batchUpdate(block: VoidClosure, completion: CompletionClosure?) {
    performBatchUpdates(block, completion: completion)
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
    insertRows(at: indexes, with: .automatic)
  }

  public func delete(at indexes: [IndexPath]) {
    deleteRows(at: indexes, with: .automatic)
  }

  public func reload(at indexes: [IndexPath]) {
    reloadRows(at: indexes, with: .automatic)
  }

  public func batchUpdate(block: VoidClosure, completion: CompletionClosure? = nil) {
    if #available(iOS 11.0, *) {
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
}
