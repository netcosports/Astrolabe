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
}
