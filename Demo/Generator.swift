//
//  Generator.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/6/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe

class Generator<Container,
               CellView: ReusableView & Reusable,
               HeaderView: ReusableView & Reusable>
  where CellView.Container == Container, CellView.Data == TestViewModel,
  HeaderView.Container == Container, HeaderView.Data == TestViewModel {

  func cellsViews(page: Int, cells: Int) -> [Cell<Container, CellView>] {
    let indexes = [Int](1 ... cells)
    let cells: [Cell<Container, CellView>] = indexes.map {
      let cell = Cell<Container, CellView>(data: TestViewModel("\(page) Cell \($0)"))
      cell.id = "\(page) Cell \($0)"
      return cell
    }
    return cells
  }

  func expandable(page: Int, cells: Int) -> ExpandableCell<Container, CellView> {
    let cells: [Cell<Container, CellView>] = cellsViews(page: page, cells: cells)
    let expandable = ExpandableCell<Container, CellView>(data: TestViewModel("root \(page)"),
                                                         expandableCells: cells as [Cellable])
    expandable.id = "root \(page)"
    return expandable
  }

  func section(page: Int, cells: Int) -> Section {
    let cells: [Cell<Container, CellView>] = cellsViews(page: page, cells: cells)
    return Section(cells: cells as [Cellable], page: page)
  }

  func headerSection(page: Int, cells: Int) -> HeaderSection<Container, HeaderView> {
    let sectionTitle = "Section \(page)"
    let cells: [Cell<Container, CellView>] = cellsViews(page: page, cells: cells)
    return HeaderSection<Container, HeaderView>(cells: cells, headerData: TestViewModel("header only \(sectionTitle)"),
                                                page: page)
  }

  func footerSection(page: Int, cells: Int) -> FooterSection<Container, HeaderView> {
    let sectionTitle = "Section \(page)"
    let cells: [Cell<Container, CellView>] = cellsViews(page: page, cells: cells)
    return FooterSection<Container, HeaderView>(cells: cells, footerData: TestViewModel("footer only \(sectionTitle)"),
                                                page: page, click: nil)
  }

  func headerFooterSection(page: Int, cells: Int) -> HeaderFooterSection<Container, HeaderView, HeaderView> {
    let sectionTitle = "Section \(page)"
    let header = TestViewModel("header of \(sectionTitle)")
    let footer = TestViewModel("footer of \(sectionTitle)")
    let cells: [Cell<Container, CellView>] = cellsViews(page: page, cells: cells)
    return HeaderFooterSection<Container, HeaderView, HeaderView>(cells: cells, headerData: header, footerData: footer,
                                                                  page: page, headerClick: nil, footerClick: nil)
  }
}

typealias CollectionGenerator<T1:ReusableView & Reusable, T2:ReusableView & Reusable>
  = Generator<UICollectionView, T1, T2>
where T1.Container == UICollectionView, T1.Data == TestViewModel,
T2.Container == UICollectionView, T2.Data == TestViewModel

typealias TableGenerator<T1:ReusableView & Reusable, T2:ReusableView & Reusable>
  = Generator<UITableView, T1, T2>
where T1.Container == UITableView, T1.Data == TestViewModel,
T2.Container == UITableView, T2.Data == TestViewModel

