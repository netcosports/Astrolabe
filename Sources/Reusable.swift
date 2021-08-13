//
//  Reusable.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/4/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

public enum SelectionManagement {
  case none
  case automatic
  case manual
}

public enum SelectionBehavior {
  case single, singleUnselectable, multiple
}

public struct ExpandableBehavior {
  public var collapseDisabled = false
  public var collapseOtherOnExpand = true
  // Disabled or enabled scroll to cell after collapse/expand animation
  public var autoScrollToItemDisabled = false

  public init(collapseDisabled: Bool = false,
              collapseOtherOnExpand: Bool = true,
              autoScrollToItemDisabled: Bool = false) {
    self.collapseDisabled = collapseDisabled
    self.collapseOtherOnExpand = collapseOtherOnExpand
    self.autoScrollToItemDisabled = autoScrollToItemDisabled
  }
}

public protocol ReusableSource: AnyObject {

  init()

  associatedtype Container: UIScrollView & ContainerView
  associatedtype SectionState: Hashable
  associatedtype CellState: Hashable

  var containerView: Container? { get set }
  var hostViewController: UIViewController? { get set }
  var sections: [Section<SectionState, CellState>] { get set }
  var selectedCellStates: Set<CellState> { get set }
  var selectionBehavior: SelectionBehavior { get set }
  var selectionManagement: SelectionManagement { get set }

  func registerCellsForSections()
  var lastCellDisplayed: VoidClosure? { get set }
  var lastCellСondition: LastCellConditionClosure? { get set }
}

extension ReusableSource {

  public var cellsCount: Int {
    return sections.reduce(0, { $0 + $1.cells.count })
  }

  func processSelection(for state: CellState) {
    switch selectionBehavior {
    case .single:
      if selectedCellStates.contains(state) {
        selectedCellStates.remove(state)
      } else {
        selectedCellStates = [state]
      }
    case .multiple:
      if selectedCellStates.contains(state) {
        selectedCellStates.remove(state)
      } else {
        selectedCellStates.insert(state)
      }
    case .singleUnselectable:
      if !selectedCellStates.contains(state) {
        selectedCellStates = [state]
      }
    }
  }
}

public protocol ReusedData: AnyObject {
  associatedtype Data: Hashable
  var data: Data? { get set }
}

public protocol Eventable: AnyObject {
  associatedtype Event: Hashable
  var eventSubject: PublishSubject<Event> { get }
}

public protocol Reusable: ReusedData {
  func setup(with data: Data)

  func cellRequested()

  static func size(for data: Data, containerSize: CGSize) -> CGSize
  static func identifier(for data: Data) -> String
}

public extension Reusable {

  func cellRequested() { }
}

public extension Reusable where Data == Never {
  func setup(with data: Data) {}
}

public extension Reusable {
  static func identifier(for data: Data) -> String {
    return String(reflecting: self)
  }
}

public extension Reusable where Self: UIView {

  static func size(for data: Data, containerSize: CGSize) -> CGSize {
    return containerSize
  }
}

public extension Reactive where Base: UIView & Reusable {
  var viewModel: Binder<Base.Data> {
    .init(base) { (base, data) in
      base.setup(with: data)
    }
  }
}
