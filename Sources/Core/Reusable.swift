//
//  Reusable.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/4/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit

public enum SelectionManagement {
  case none
  case automatic
  case manual
}

public enum SelectionState {
  case single(id: String)
  case multiple(ids: [String])

  func isSelected(cellId: String) -> Bool {
    switch self {
    case let .single(id):
      return id == cellId
    case let .multiple(ids):
      return ids.contains(cellId)
    }
  }

  mutating func processSelection(for cellId: String) {
    switch self {
    case .single(_):
      self = .single(id: cellId)
    case var .multiple(ids):
      if let cellIndex = ids.index(of: cellId) {
        ids.remove(at: cellIndex)
      } else {
        ids.append(cellId)
      }

      self = .multiple(ids: ids)
    }
  }
}

public protocol ReusableSource {
  associatedtype Container: ContainerView

  var containerView: Container! { get set }
  var hostViewController: UIViewController? { get set }
  var sections: [Sectionable] { get set }
  var selectionState: SelectionState { get set }
  var selectionManagement: SelectionManagement { get set }

  func registerCellsForSections()
  var lastCellDisplayed: VoidClosure? { get set }
}

public protocol LoaderReusableSource: ReusableSource {
  var startProgress: ProgressClosure? { get set }
  var stopProgress: ProgressClosure? { get set }
  var updateEmptyView: EmptyViewClosure? { get set }
  var autoupdatePeriod: TimeInterval { get set }
  var loadingBehavior: LoadingBehavior { get set }

  func forceReloadData(keepCurrentDataBeforeUpdate: Bool)
  func pullToRefresh()
  func appear()
  func disappear()
  func reloadDataWithEmptyDataSet()
}

public protocol Reusable {
  associatedtype Data

  func setup(with data: Data)
  static func size(for data: Data, containerSize: CGSize) -> CGSize
  static func identifier(for data: Data) -> String
}

public extension Reusable where Data == Void {
  func setup(with data: Data) {}
}

public extension Reusable {
  static func identifier(for data: Data) -> String {
    return "\(self)"
  }
}

public protocol ReusableWrapper: class {
  var contentView: UIView? { get set }
  func setup<T: ReusableView>(with reusableView: T)
  init()
}

public protocol StyledData {
  associatedtype Style

  var style: Style { get }
}

public protocol StyledReusable: Reusable {
  associatedtype Data: StyledData

  var style: Data.Style? { get set }
}

public extension StyledReusable {
  static func identifier(for data: Data) -> String {
    return "\(self)_\(data.style)"
  }
}
