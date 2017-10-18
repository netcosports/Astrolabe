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

public enum SelectionBehavior {
  case single, multiple
}

public protocol ReusableSource: class {

  init()
	
  associatedtype Container: ContainerView

  var containerView: Container? { get set }
  var hostViewController: UIViewController? { get set }
  var sections: [Sectionable] { get set }
  var selectedCellIds: Set<String> { get set }
  var selectionBehavior: SelectionBehavior { get set }
  var selectionManagement: SelectionManagement { get set }

  func registerCellsForSections()
  var lastCellDisplayed: VoidClosure? { get set }
}

extension ReusableSource {

  func processSelection(for cellId: String) {
    switch selectionBehavior {
    case .single:
      selectedCellIds = [cellId]
    case .multiple:
      if selectedCellIds.contains(cellId) {
        selectedCellIds.remove(cellId)
      } else {
        selectedCellIds.insert(cellId)
      }
    }
  }

}

public protocol LoaderReusableSource: ReusableSource {

  weak var loader: Loader? { get set }

  var startProgress: ProgressClosure? { get set }
  var stopProgress: ProgressClosure? { get set }
  var updateEmptyView: EmptyViewClosure? { get set }
  var autoupdatePeriod: TimeInterval { get set }
  var loadingBehavior: LoadingBehavior { get set }

  func forceReloadData(keepCurrentDataBeforeUpdate: Bool)
  func forceLoadNextPage()
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

public protocol StyledReusable: Reusable where Data: StyledData {
  var style: Data.Style? { get set }
}

public extension StyledReusable {
  static func identifier(for data: Data) -> String {
    return "\(self)_\(data.style)"
  }
}
