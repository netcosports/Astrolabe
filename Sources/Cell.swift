//
//  CollectionCellable.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 12/28/16.
//  Copyright © 2016 Netcosports. All rights reserved.
//

import UIKit
import RxSwift

public struct Cell<State: Hashable> {
  public let state: State
  let cell: Cellable

  public init<Cell: ReusableView & Reusable & Eventable>(
    cell: Cell.Type,
    state: Cell.Data,
    eventsEmmiter: AnyObserver<Cell.Event>? = nil,
    clickEvent: Cell.Event? = nil,
    type: CellType = .cell,
    setup: SetupClosure<Cell>? = nil
  ) where Cell.Data == State {
    self.state = state
    self.cell = CellContainer<Cell>(
      data: state,
      eventsEmmiter: eventsEmmiter,
      clickEvent: clickEvent,
      type: type,
      setup: setup
    )
  }
}

public struct CellContainer<CellView: ReusableView & Reusable & Eventable>: Cellable {

  public typealias Data = CellView.Data
  public typealias Event = CellView.Event

  public let type: CellType

  private let setup: SetupClosure<CellView>?

  private let data: Data
  private var cellClass: CellView.Type { return CellView.self }

  private let eventsEmmiter: AnyObserver<Event>?
  private let clickEvent: Event?

  private var identifier: String { return cellClass.identifier(for: data) }
  private var needsToRegister: Bool { return true }

  // MARK: - Init
  public init(
    data: Data,
    eventsEmmiter: AnyObserver<Event>? = nil,
    clickEvent: Event? = nil,
    type: CellType = .cell,
    setup: SetupClosure<CellView>? = nil
  ) {
    self.data = data
    self.type = type
    self.eventsEmmiter = eventsEmmiter
    self.clickEvent = clickEvent
    self.setup = setup
  }

  public func handleClickEvent() {
    guard let clickEvent = clickEvent else { return }
    eventsEmmiter?.onNext(clickEvent)
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
// FiXME: move to view before setup
//    eventBinderDisposeBag = DisposeBag()
//    if let eventsEmmiter = eventsEmmiter {
//      cellView.eventSubject.bind(to: eventsEmmiter).disposed(by: eventBinderDisposeBag)
//    }
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


