//
//  CollectionCellable.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 12/28/16.
//  Copyright © 2016 Netcosports. All rights reserved.
//

import UIKit
import RxSwift

open class Cell<Container, CellView: ReusableView & Reusable>: Cellable
where CellView.Container == Container {
  public typealias Data = CellView.Data

  let data: Data
  let setup: SetupClosure<CellView>?
  let type: CellType

  public let click: ClickClosure?
  public let page: Int = 0
  public var id: String = ""

  public convenience init(data: Data, click: ClickClosure? = nil) {
    self.init(data: data, click: click, type: .cell, setup: nil)
  }

  public convenience init(data: Data, id: String, click: ClickClosure? = nil) {
    self.init(data: data, click: click, type: .cell, setup: nil)
    self.id = id
  }

  public init(data: Data, click: ClickClosure? = nil, type: CellType = .cell, setup: SetupClosure<CellView>? = nil) {
    self.data = data
    self.type = type
    self.setup = setup
    self.click = click
  }

  public func register<T: ContainerView>(in container: T) {
    let cellClass = CellView.self
    let identifier = cellClass.identifier(for: data)
    container.register(type: type, cellClass: cellClass, identifier: identifier)
  }

  public func instance<T1: ContainerView, T2: ReusableView>(for container: T1, index: IndexPath) -> T2 {
    let cellClass = CellView.self
    let identifier = cellClass.identifier(for: data)
    var cellView: CellView = container.instance(type: type, index: index, identifier: identifier)
    presetupCellView(with: &cellView)
    setup?(cellView)
    guard let result = cellView as? T2 else {
      fatalError("\(T2.self) is not registred")
    }
    return result
  }

  public func setup<T: ReusableView>(with cell: T) {
    guard let cellView = cell as? CellView else {
      fatalError("\(cell.self) trying to setup as \(CellView.self)")
    }
    cellView.setup(with: data)
  }

  public func size<T: ContainerView>(with container: T) -> CGSize {
    let cellClass = CellView.self

    switch type {
    case .cell, .header, .footer:
      return cellClass.size(for: data, containerSize: container.size)
    case .custom:
      return CGSize.zero
    }
  }

  internal func presetupCellView(with cellView: inout CellView) {
  }
}

open class ExpandableCell<Container, CellView: ReusableView & Reusable>: Cell<Container, CellView>,
  ExpandableCellable where CellView.Container == Container {

  public var expandableCells: [Cellable]?
  public var expanded: Bool = false

  public init(data: Data, expandableCells: [Cellable]?, click: ClickClosure? = nil,
              setup: SetupClosure<CellView>? = nil) {
    self.expandableCells = expandableCells
    super.init(data: data, click: click, type: .cell, setup: setup)
  }
}

public typealias CollectionExpandableCell<T:ReusableView & Reusable> = ExpandableCell<UICollectionView, T>
  where T.Container == UICollectionView
public typealias TableExpandableCell<T:ReusableView & Reusable> = ExpandableCell<UITableView, T>
  where T.Container == UITableView

open class LoaderExpandableCell<Container, CellView: ReusableView & Reusable>:
  ExpandableCell<Container, CellView>, LoaderExpandableCellable where CellView.Container == Container {

  public init(data: Data,
              loader: ObservableClosure? = nil,
              loaderCell: Cellable,
              click: ClickClosure? = nil,
              setup: SetupClosure<CellView>? = nil) {
    self.loader = loader
    self.loaderCell = loaderCell
    super.init(data: data, expandableCells: nil, click: click, setup: setup)
    self.expandableCells = [loaderCell]
  }

  public func performLoading() -> SectionObservable? {
    guard let sectionObservable = loader?() else {
      return .just(nil)
    }
    state = .loading(intent: .initial)
    return sectionObservable.do(onNext: { [weak self] sections in
      guard let strongSelf = self, let sections = sections else { return }
      strongSelf.loadedCells = sections.flatMap { $0.cells }
      if strongSelf.loadedCells?.count == 0 {
        strongSelf.state = .empty
      } else {
        strongSelf.state = .hasData
      }
    }, onError: { [weak self] error in
      guard let strongSelf = self else { return }
      strongSelf.state = .error
    })
  }

  public var state: LoaderState = .notInitiated
  public var loadedCells: [Cellable]?
  public var loaderCell: Cellable
  public var loader: ObservableClosure?
}

public typealias CollectionCell<T:ReusableView & Reusable> = Cell<UICollectionView, T>
  where T.Container == UICollectionView
public typealias TableCell<T:ReusableView & Reusable> = Cell<UITableView, T>
  where T.Container == UITableView

open class StyledCell<Container, CellView: ReusableView & StyledReusable>: Cell<Container, CellView>
  where CellView.Container == Container {

  public typealias Style = CellView.Data.Style

  let style: Style

  public convenience init(data: Data, click: ClickClosure? = nil) {
    self.init(style: data.style, data: data, click: click, type: .cell, setup: nil)
  }

  public init(style: Style, data: Data, click: ClickClosure? = nil, type: CellType = .cell,
              setup: SetupClosure<CellView>? = nil) {
    self.style = style
    super.init(data: data, click: click, type: type, setup: setup)
  }

  override internal func presetupCellView(with cellView: inout CellView) {
    if cellView.style == nil {
      cellView.style = style
    }
  }
}

public typealias StyledCollectionCell<T:ReusableView & StyledReusable> = StyledCell<UICollectionView, T>
  where T.Container == UICollectionView
public typealias StyledTableCell<T:ReusableView & StyledReusable> = StyledCell<UITableView, T>
  where T.Container == UITableView
