//
//  Reusable.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/4/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import RxSwift

public enum SelectionManagement {
  case none
  case automatic
  case manual
}

public enum SelectionBehavior {
  case single, multiple
}

public struct ExpandableBehavior {
  public var collapseDisabled: Bool
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

  public var cellsCount: Int {
    return sections.reduce(0, { $0 + $1.cells.count })
  }

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
    return String(reflecting: self)
  }
}
