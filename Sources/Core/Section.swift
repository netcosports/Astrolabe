//
//  Section.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/9/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit

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
      if $0.id.isEmpty || self.id.isEmpty {
        return false
      } else {
        return self.id == $0.id
      }
    }
  }

  public var supplementaryTypes: [CellType] { return [] }

  public func supplementary(for type: CellType) -> Cellable? {
    return nil
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

  public override func supplementary(for type: CellType) -> Cellable? {
    return supplementaries.first(where: { $0.type == type })
  }
}

open class HeaderSection<Container, CellView: ReusableView & Reusable>: Section
  where CellView.Container == Container {

  public typealias HeaderCell = Cell<Container, CellView>
  public typealias HeaderData = HeaderCell.Data

  var headerCell: HeaderCell?

  public init(cells: [Cellable], headerData: HeaderData, inset: UIEdgeInsets? = nil, id: String? = nil,
              minimumLineSpacing: CGFloat? = nil, minimumInteritemSpacing: CGFloat? = nil, click: ClickClosure? = nil) {
    super.init(cells: cells, page: 0, inset: inset, minimumLineSpacing: minimumLineSpacing,
               minimumInteritemSpacing: minimumInteritemSpacing)
    headerCell = HeaderCell(data: headerData, click: click, type: .header)
    if let id = id {
      headerCell?.id = id
    }
  }

  public init(cells: [Cellable], headerData: HeaderData, page: Int, id: String? = nil, inset: UIEdgeInsets? = nil,
              minimumLineSpacing: CGFloat? = nil, minimumInteritemSpacing: CGFloat? = nil, click: ClickClosure? = nil) {
    super.init(cells: cells, page: page, inset: inset, minimumLineSpacing: minimumLineSpacing,
               minimumInteritemSpacing: minimumInteritemSpacing)
    headerCell = HeaderCell(data: headerData, click: click, type: .header)
    if let id = id {
      headerCell?.id = id
    }
  }

  public override var supplementaryTypes: [CellType] { return [.header] }

  public override func supplementary(for type: CellType) -> Cellable? {
    switch type {
    case .header, .custom:
      return headerCell
    default:
      return nil
    }
  }
}

open class CustomHeaderSection<CellView: ReusableView & Reusable>: Section
  where CellView.Container == UICollectionView {

  public typealias HeaderCell = CollectionCell<CellView>
  public typealias HeaderData = HeaderCell.Data

  private let kind: String
  var headerCell: HeaderCell?

  public init(cells: [Cellable], headerData: HeaderData, page: Int = 0, kind: String, inset: UIEdgeInsets? = nil,
              minimumLineSpacing: CGFloat? = nil, minimumInteritemSpacing: CGFloat? = nil,
              click: ClickClosure? = nil) {
    self.kind = kind
    super.init(cells: cells, page: page, inset: inset,
               minimumLineSpacing: minimumLineSpacing, minimumInteritemSpacing: minimumInteritemSpacing)
    headerCell = HeaderCell(data: headerData, click: click, type: .custom(kind: kind))
  }

  public override var supplementaryTypes: [CellType] { return [.custom(kind: kind)] }

  public override func supplementary(for type: CellType) -> Cellable? {
    switch type {
    case .header, .custom:
      return headerCell
    default:
      return nil
    }
  }
}

public typealias CollectionHeaderSection<T:Reusable & ReusableView> = HeaderSection<UICollectionView, T>
  where T.Container == UICollectionView

open class TableHeaderSection<T: UITableViewHeaderFooterView>: HeaderSection<UITableView, T>
  where T.Container == UITableView, T: ReusableView & Reusable {

  public override init(cells: [Cellable], headerData: HeaderData, page: Int = 0, id: String? = nil,
                       inset: UIEdgeInsets? = nil, minimumLineSpacing: CGFloat? = nil,
                       minimumInteritemSpacing: CGFloat? = nil, click: ClickClosure? = nil) {
    super.init(cells: cells, headerData: headerData, page: page, id: id, click: click)
  }
}

open class FooterSection<Container, CellView: ReusableView & Reusable>: Section
  where CellView.Container == Container {

  public typealias FooterCell = Cell<Container, CellView>
  public typealias FooterData = FooterCell.Data

  var footerCell: FooterCell?

  public init(cells: [Cellable], footerData: FooterData, page: Int = 0, inset: UIEdgeInsets? = nil,
              minimumLineSpacing: CGFloat? = nil, minimumInteritemSpacing: CGFloat? = nil, click: ClickClosure? = nil) {
    super.init(cells: cells, page: page, inset: inset,
               minimumLineSpacing: minimumLineSpacing, minimumInteritemSpacing: minimumInteritemSpacing)
    footerCell = FooterCell(data: footerData, click: click, type: .footer)
  }

  public override var supplementaryTypes: [CellType] { return [.footer] }

  public override func supplementary(for type: CellType) -> Cellable? {
    switch type {
    case .footer:
      return footerCell
    default:
      return nil
    }
  }
}

public typealias CollectionFooterSection<T:ReusableView & Reusable> = FooterSection<UICollectionView, T>
  where T.Container == UICollectionView

open class TableFooterSection<T: UITableViewHeaderFooterView>: FooterSection<UITableView, T>
  where T.Container == UITableView, T: ReusableView & Reusable {

  public override init(cells: [Cellable], footerData: FooterData, page: Int = 0, inset: UIEdgeInsets? = nil,
                       minimumLineSpacing: CGFloat? = nil, minimumInteritemSpacing: CGFloat? = nil,
                       click: ClickClosure? = nil) {
    super.init(cells: cells, footerData: footerData, page: page, click: click)
  }
}

open class HeaderFooterSection<Container, HeaderView: ReusableView & Reusable,
                               FooterView: ReusableView & Reusable>: Section
  where HeaderView.Container == Container, FooterView.Container == Container {

  public typealias HeaderCell = Cell<Container, HeaderView>
  public typealias HeaderData = HeaderCell.Data

  public typealias FooterCell = Cell<Container, FooterView>
  public typealias FooterData = FooterCell.Data

  var headerCell: HeaderCell?
  var footerCell: FooterCell?

  public init(cells: [Cellable], headerData: HeaderData, footerData: FooterData, page: Int = 0, id: String? = nil,
              inset: UIEdgeInsets? = nil, minimumLineSpacing: CGFloat? = nil, minimumInteritemSpacing: CGFloat? = nil,
              headerClick: ClickClosure? = nil, footerClick: ClickClosure? = nil) {
    super.init(cells: cells, page: page, inset: inset,
               minimumLineSpacing: minimumLineSpacing, minimumInteritemSpacing: minimumInteritemSpacing)

    headerCell = HeaderCell(data: headerData, click: headerClick, type: .header)
    if let id = id {
      headerCell?.id = id
    }
    footerCell = FooterCell(data: footerData, click: footerClick, type: .footer)
  }

  public override var supplementaryTypes: [CellType] { return [.header, .footer] }

  public override func supplementary(for type: CellType) -> Cellable? {
    switch type {
    case .header:
      return headerCell
    case .footer:
      return footerCell

    default:
      return nil
    }
  }
}

public typealias CollectionHeaderFooterSection<Header:ReusableView & Reusable, Footer:ReusableView & Reusable>
  = HeaderFooterSection<UICollectionView, Header, Footer>
  where Header.Container == UICollectionView, Footer.Container == UICollectionView

open class TableHeaderFooterSection<Header: UITableViewHeaderFooterView, Footer: UITableViewHeaderFooterView>:
  HeaderFooterSection<UITableView, Header, Footer> where Header.Container == UITableView,
  Footer.Container == UITableView, Header: ReusableView & Reusable, Footer: ReusableView & Reusable {

  public override init(cells: [Cellable], headerData: HeaderData, footerData: FooterData, page: Int = 0,
                       id: String? = nil, inset: UIEdgeInsets? = nil, minimumLineSpacing: CGFloat? = nil,
                       minimumInteritemSpacing: CGFloat? = nil, headerClick: ClickClosure? = nil,
                       footerClick: ClickClosure? = nil) {
    super.init(cells: cells, headerData: headerData, footerData: footerData, page: page, id: id,
               headerClick: headerClick, footerClick: footerClick)
  }
}
