//
//  CollectionCellable.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 12/28/16.
//  Copyright © 2016 Netcosports. All rights reserved.
//

import UIKit
import RxSwift

open class Cell<Container, CellView: ReusableView & Reusable & Eventable>: DataHodler<CellView.Data>, Cellable
where CellView.Container == Container {

  public typealias Data = CellView.Data
  public typealias Event = CellView.Event

  let setup: SetupClosure<CellView>?

  public let type: CellType
  public var equals: EqualsClosure<Cellable>?
  public var click: ClickClosure? = nil
  public let page: Int = 0
  public var id: String = ""
  public var cellClass: CellView.Type { return CellView.self }

  let eventsEmmiter: AnyObserver<Event>?
  let clickEvent: Event?
  var eventBinderDisposeBag = DisposeBag()

  open var identifier: String { return cellClass.identifier(for: data) }
  open var needsToRegister: Bool { return true }

  // MARK: - Init

  public init(
    data: Data,
    id: String,
    eventsEmmiter: AnyObserver<Event>? = nil,
    clickEvent: Event? = nil,
    type: CellType = .cell,
    setup: SetupClosure<CellView>? = nil,
    equals: EqualsClosure<Cellable>? = nil
  ) {
    self.type = type
    self.eventsEmmiter = eventsEmmiter
    self.clickEvent = clickEvent
    self.setup = setup
    super.init(data: data)
    self.click = { [weak self] in
      guard let event = self?.clickEvent else { return }
      self?.eventsEmmiter?.onNext(event)
    }
    self.id = id
    if let exactEqual = equals {
      self.equals = exactEqual
    } else {
      self.equals = {
        guard !$0.id.isEmpty && !self.id.isEmpty else {
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
    eventBinderDisposeBag = DisposeBag()
    if let eventsEmmiter = eventsEmmiter {
      cellView.eventSubject.bind(to: eventsEmmiter).disposed(by: eventBinderDisposeBag)
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

open class ExpandableCell<Container, CellView: ReusableView & Reusable & Eventable>: Cell<Container, CellView>,
  ExpandableCellable where CellView.Container == Container {

  public var expandableCells: [Cellable]?

  public init(data: Data, id: String, expandableCells: [Cellable]?, eventsEmmiter: AnyObserver<Event>? = nil, clickEvent: Event? = nil,
              setup: SetupClosure<CellView>? = nil, equals: EqualsClosure<Cellable>? = nil) {
    self.expandableCells = expandableCells
    super.init(data: data, id: id, eventsEmmiter: eventsEmmiter, clickEvent: clickEvent, type: .cell, setup: setup, equals: equals)
  }
}

public typealias CollectionExpandableCell<T:ReusableView & Reusable & Eventable> = ExpandableCell<UICollectionView, T>
  where T.Container == UICollectionView
public typealias TableExpandableCell<T:ReusableView & Reusable & Eventable> = ExpandableCell<UITableView, T>
  where T.Container == UITableView

public typealias CollectionCell<T:ReusableView & Reusable & Eventable> = Cell<UICollectionView, T>
  where T.Container == UICollectionView
public typealias TableCell<T:ReusableView & Reusable & Eventable> = Cell<UITableView, T>
  where T.Container == UITableView
