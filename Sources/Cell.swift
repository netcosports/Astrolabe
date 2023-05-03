//
//  CollectionCellable.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 12/28/16.
//  Copyright © 2016 Netcosports. All rights reserved.
//

import UIKit
import RxSwift

public protocol Clickable {
  func click()
}

public protocol Identifyable {
  var id: String { get }
}


open class Cell<Container, CellView: ReusableView & Reusable>: DataHodler<CellView.Data>, Cellable
where CellView.Container == Container, CellView.Data: Identifyable {

  public typealias Data = CellView.Data

  let setup: SetupClosure<CellView>?

  public let type: CellType
  public var equals: EqualsClosure<Cellable>?
  public var click: ClickClosure? = nil
  public let page: Int = 0
  public var id: String = ""
  public var cellClass: CellView.Type { return CellView.self }
  open var identifier: String { return cellClass.identifier(for: data) }
  open var needsToRegister: Bool { return true }

  // MARK: - Init
  public init(
    data: Data,
    type: CellType = .cell,
    setup: SetupClosure<CellView>? = nil,
    equals: EqualsClosure<Cellable>? = nil
  ) {
    self.type = type
    self.setup = setup
    super.init(data: data)
    self.id = data.id
    if let exactEqual = equals {
      self.equals = exactEqual
    } else {
      self.equals = { [weak self] in
        guard let self = self, !$0.id.isEmpty && !self.id.isEmpty else {
          assertionFailure("id of a cell must not be empty string")
          return false
        }
        guard let anotherCell = $0 as? Self else {
          return false
        }
        return anotherCell.data == self.data
      }
    }
  }
  
  convenience public init(
    clickableData: Data,
    type: CellType = .cell,
    setup: SetupClosure<CellView>? = nil,
    equals: EqualsClosure<Cellable>? = nil
  ) where Data: Clickable {
    self.init(data: clickableData, type: type, setup: setup, equals: equals)
    self.click = clickableData.click
  }

  // MARK: - Lifecycle

  public func register<T: ContainerView>(in container: T) {
    guard needsToRegister else { return }

    container.register(type: type, cellClass: cellClass, identifier: identifier)
  }

  public func instance<T1: ContainerView, T2: ReusableView>(for container: T1, index: IndexPath) -> T2 {
    let cellView: CellView = container.instance(type: type, index: index, identifier: identifier)
    setup?(cellView)
    guard let result = cellView as? T2 else {
      fatalError("\(T2.self) is not registred")
    }
    return result
  }

  public func setup<T: ReusableView>(with cell: T) {
    guard let cellView = cell as? CellView else {
      fatalError("\(cell.self) trying to setup as \(cellClass)")
    }
    if cellView.data != data {
      cellView.data = data
      cellView.setup(with: data)
    }
    cellView.cellRequested()
  }

  public func size<T: ContainerView>(with container: T) -> CGSize {
    switch type {
    case .cell, .header, .footer:
      return cellClass.size(for: data, containerSize: container.size)
    case .custom:
      return CGSize.zero
    }
  }
}

open class ExpandableCell<Container, CellView: ReusableView & Reusable>: Cell<Container, CellView>,
  ExpandableCellable where CellView.Container == Container, CellView.Data: Identifyable {

  public var expandableCells: [Cellable]?

  public init(data: Data, expandableCells: [Cellable]?,
              setup: SetupClosure<CellView>? = nil, equals: EqualsClosure<Cellable>? = nil) {
    self.expandableCells = expandableCells
    super.init(data: data, type: .cell, setup: setup, equals: equals)
  }
}

public typealias CollectionExpandableCell<T:ReusableView & Reusable> = ExpandableCell<UICollectionView, T>
  where T.Container == UICollectionView, T.Data: Identifyable
public typealias TableExpandableCell<T:ReusableView & Reusable> = ExpandableCell<UITableView, T>
  where T.Container == UITableView, T.Data: Identifyable

public typealias CollectionCell<T:ReusableView & Reusable> = Cell<UICollectionView, T>
  where T.Container == UICollectionView, T.Data: Identifyable
public typealias TableCell<T:ReusableView & Reusable> = Cell<UITableView, T>
  where T.Container == UITableView, T.Data: Identifyable
