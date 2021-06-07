//
//  Section.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/9/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

open class Section: Sectionable {

  public var cells: [Cellable]
  public let page: Int
  public var id: String = ""

  public var equals: EqualsClosure<Sectionable>?

  public var inset: UIEdgeInsets?
  public var minimumLineSpacing: CGFloat?
  public var minimumInteritemSpacing: CGFloat?

  public init(cells: [Cellable], id: String = "", page: Int = 0, inset: UIEdgeInsets? = nil, minimumLineSpacing: CGFloat? = nil, minimumInteritemSpacing: CGFloat? = nil) {
    self.cells = cells
        self.id = id
    self.page = page
    self.inset = inset
    self.minimumLineSpacing = minimumLineSpacing
    self.minimumInteritemSpacing = minimumInteritemSpacing

    self.equals = {
      guard !$0.id.isEmpty && !self.id.isEmpty else {
        assertionFailure("id of a section must not be empty string")
        return false
      }
      return self.id == $0.id
    }
  }

  public var supplementaryTypes: [CellType] { return [] }

  public func supplementaries(for type: CellType) -> [Cellable] {
    return []
  }
}

open class MultipleSupplementariesSection: Section {

  let supplementaries: [Cellable]

  public init(supplementaries: [Cellable],
              cells: [Cellable],
              page: Int = 0,
              inset: UIEdgeInsets? = nil,
              minimumLineSpacing: CGFloat? = nil,
              minimumInteritemSpacing: CGFloat? = nil) {
    self.supplementaries = supplementaries
    super.init(cells: cells, page: page, inset: inset, minimumLineSpacing: minimumLineSpacing, minimumInteritemSpacing: minimumInteritemSpacing)
  }

  public override var supplementaryTypes: [CellType] {
    return supplementaries.map { $0.type }
  }

  public override func supplementaries(for type: CellType) -> [Cellable] {
    return supplementaries.filter { $0.type == type }
  }
}

open class HeaderSection<Container, CellView: ReusableView & Reusable & Eventable>: Section
  where CellView.Container == Container {

  public typealias HeaderCell = Cell<Container, CellView>
  public typealias HeaderData = HeaderCell.Data

  var headerCell: HeaderCell?

  public init(cells: [Cellable], headerData: HeaderData, inset: UIEdgeInsets? = nil, id: String? = nil,
              minimumLineSpacing: CGFloat? = nil, minimumInteritemSpacing: CGFloat? = nil, eventsEmmiter: AnyObserver<CellView.Event>? = nil, clickEvent: CellView.Event?) {
    super.init(cells: cells, page: 0, inset: inset, minimumLineSpacing: minimumLineSpacing,
               minimumInteritemSpacing: minimumInteritemSpacing)
    headerCell = HeaderCell(data: headerData, eventsEmmiter: eventsEmmiter, clickEvent: clickEvent, type: .header)
    if let id = id {
      headerCell?.id = id
    }
  }

  public init(cells: [Cellable], headerData: HeaderData, page: Int, id: String? = nil, inset: UIEdgeInsets? = nil,
              minimumLineSpacing: CGFloat? = nil, minimumInteritemSpacing: CGFloat? = nil,
              eventsEmmiter: AnyObserver<CellView.Event>? = nil, clickEvent: CellView.Event?) {
    super.init(cells: cells, page: page, inset: inset, minimumLineSpacing: minimumLineSpacing,
               minimumInteritemSpacing: minimumInteritemSpacing)
    headerCell = HeaderCell(data: headerData, eventsEmmiter: eventsEmmiter, clickEvent: clickEvent, type: .header)
    if let id = id {
      headerCell?.id = id
    }
  }

  public override var supplementaryTypes: [CellType] { return [.header] }

  public override func supplementaries(for type: CellType) -> [Cellable] {
    switch type {
      case .header, .custom:
      return [headerCell].compactMap { $0 }
    default:
      return []
    }
  }
}

open class CustomHeaderSection<CellView: ReusableView & Reusable & Eventable>: Section
  where CellView.Container == UICollectionView {

  public typealias HeaderCell = CollectionCell<CellView>
  public typealias HeaderData = HeaderCell.Data

  private let kind: String
  var headerCell: HeaderCell?

  public init(cells: [Cellable], headerData: HeaderData, page: Int = 0, kind: String, inset: UIEdgeInsets? = nil,
              minimumLineSpacing: CGFloat? = nil, minimumInteritemSpacing: CGFloat? = nil,
              eventsEmmiter: AnyObserver<CellView.Event>? = nil, clickEvent: CellView.Event?) {
    self.kind = kind
    super.init(cells: cells, page: page, inset: inset,
               minimumLineSpacing: minimumLineSpacing, minimumInteritemSpacing: minimumInteritemSpacing)
    headerCell = HeaderCell(data: headerData, eventsEmmiter: eventsEmmiter, clickEvent: clickEvent, type: .custom(kind: kind))
  }

  public override var supplementaryTypes: [CellType] { return [.custom(kind: kind)] }

  public override func supplementaries(for type: CellType) -> [Cellable] {
    switch type {
      case .header, .custom:
      return [headerCell].compactMap { $0 }
    default:
      return []
    }
  }
}

public typealias CollectionHeaderSection<T: Reusable & ReusableView & Eventable> = HeaderSection<UICollectionView, T>
  where T.Container == UICollectionView

open class TableHeaderSection<T: UITableViewHeaderFooterView>: HeaderSection<UITableView, T>
  where T.Container == UITableView, T: ReusableView & Reusable & Eventable {

  public override init(cells: [Cellable], headerData: HeaderData, page: Int = 0, id: String? = nil,
                       inset: UIEdgeInsets? = nil, minimumLineSpacing: CGFloat? = nil,
                       minimumInteritemSpacing: CGFloat? = nil,
                       eventsEmmiter: AnyObserver<T.Event>? = nil, clickEvent: T.Event?) {
    super.init(cells: cells, headerData: headerData, page: page, id: id, eventsEmmiter: eventsEmmiter, clickEvent: clickEvent)
  }
}

open class FooterSection<Container, CellView: ReusableView & Reusable & Eventable>: Section
  where CellView.Container == Container {

  public typealias FooterCell = Cell<Container, CellView>
  public typealias FooterData = FooterCell.Data

  var footerCell: FooterCell?

  public init(cells: [Cellable], footerData: FooterData, page: Int = 0, inset: UIEdgeInsets? = nil,
              minimumLineSpacing: CGFloat? = nil, minimumInteritemSpacing: CGFloat? = nil,
              eventsEmmiter: AnyObserver<CellView.Event>? = nil, clickEvent: CellView.Event?) {
    super.init(cells: cells, page: page, inset: inset,
               minimumLineSpacing: minimumLineSpacing, minimumInteritemSpacing: minimumInteritemSpacing)
    footerCell = FooterCell(data: footerData, eventsEmmiter: eventsEmmiter, clickEvent: clickEvent, type: .footer)
  }

  public override var supplementaryTypes: [CellType] { return [.footer] }

  public override func supplementaries(for type: CellType) -> [Cellable] {
    switch type {
      case .footer:
      return [footerCell].compactMap { $0 }
    default:
      return []
    }
  }
}

public typealias CollectionFooterSection<T:ReusableView & Reusable & Eventable> = FooterSection<UICollectionView, T>
  where T.Container == UICollectionView

open class TableFooterSection<T: UITableViewHeaderFooterView>: FooterSection<UITableView, T>
  where T.Container == UITableView, T: ReusableView & Reusable & Eventable {

  public override init(cells: [Cellable], footerData: FooterData, page: Int = 0, inset: UIEdgeInsets? = nil,
                       minimumLineSpacing: CGFloat? = nil, minimumInteritemSpacing: CGFloat? = nil,
                       eventsEmmiter: AnyObserver<T.Event>? = nil, clickEvent: T.Event?) {
    super.init(cells: cells, footerData: footerData, page: page, eventsEmmiter: eventsEmmiter, clickEvent: clickEvent)
  }
}

open class HeaderFooterSection<Container,
                               HeaderView: ReusableView & Reusable & Eventable,
                               FooterView: ReusableView & Reusable & Eventable>: Section
  where HeaderView.Container == Container, FooterView.Container == Container {

  public typealias HeaderCell = Cell<Container, HeaderView>
  public typealias HeaderData = HeaderCell.Data

  public typealias FooterCell = Cell<Container, FooterView>
  public typealias FooterData = FooterCell.Data

  var headerCell: HeaderCell?
  var footerCell: FooterCell?

  public init(cells: [Cellable], headerData: HeaderData, footerData: FooterData, page: Int = 0, id: String? = nil,
              inset: UIEdgeInsets? = nil, minimumLineSpacing: CGFloat? = nil, minimumInteritemSpacing: CGFloat? = nil,
              headerEventsEmmiter: AnyObserver<HeaderView.Event>? = nil, headerClickEvent: HeaderView.Event?,
              footerEventsEmmiter: AnyObserver<FooterView.Event>? = nil, footerClickEvent: FooterView.Event?) {
    super.init(cells: cells, id: id ?? "", page: page, inset: inset,
               minimumLineSpacing: minimumLineSpacing, minimumInteritemSpacing: minimumInteritemSpacing)

    headerCell = HeaderCell(data: headerData, eventsEmmiter: headerEventsEmmiter, clickEvent: headerClickEvent, type: .header)
    if let id = id {
      headerCell?.id = id
    }
    footerCell = FooterCell(data: footerData, eventsEmmiter: footerEventsEmmiter, clickEvent: footerClickEvent, type: .footer)
  }

  public override var supplementaryTypes: [CellType] { return [.header, .footer] }

  public override func supplementaries(for type: CellType) -> [Cellable] {
    switch type {
    case .header:
      return [headerCell].compactMap { $0 }
    case .footer:
      return [footerCell].compactMap { $0 }
    default:
      return []
    }
  }
}

public typealias CollectionHeaderFooterSection<Header:ReusableView & Reusable & Eventable, Footer:ReusableView & Reusable & Eventable>
  = HeaderFooterSection<UICollectionView, Header, Footer>
  where Header.Container == UICollectionView, Footer.Container == UICollectionView

open class TableHeaderFooterSection<Header: UITableViewHeaderFooterView, Footer: UITableViewHeaderFooterView>:
  HeaderFooterSection<UITableView, Header, Footer> where Header.Container == UITableView,
  Footer.Container == UITableView, Header: ReusableView & Reusable & Eventable, Footer: ReusableView & Reusable & Eventable {

  public override init(cells: [Cellable], headerData: HeaderData, footerData: FooterData, page: Int = 0,
                       id: String? = nil, inset: UIEdgeInsets? = nil, minimumLineSpacing: CGFloat? = nil,
                       minimumInteritemSpacing: CGFloat? = nil,
                       headerEventsEmmiter: AnyObserver<Header.Event>? = nil, headerClickEvent: Header.Event? = nil,
                       footerEventsEmmiter: AnyObserver<Footer.Event>? = nil, footerClickEvent: Footer.Event? = nil) {
    super.init(cells: cells, headerData: headerData, footerData: footerData, page: page, id: id,
               headerEventsEmmiter: headerEventsEmmiter, headerClickEvent: headerClickEvent,
               footerEventsEmmiter: footerEventsEmmiter, footerClickEvent: footerClickEvent)
  }
}
