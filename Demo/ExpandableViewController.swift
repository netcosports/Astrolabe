//
//  ExpandableTableViewController.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/6/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe
import RxSwift

class ExpandableTableViewController: BaseTableViewController<TableViewExpandableSource> {

  override func sections() -> [Sectionable]? {
    let gen = TableGenerator<TestTableCell, TestTableHeader>()
    let cells1: [Cellable] = [
      gen.expandable(page: 1, cells: 1),
      gen.expandable(page: 2, cells: 2),
      gen.expandable(page: 3, cells: 3),
      gen.expandable(page: 4, cells: 3),
      gen.expandable(page: 5, cells: 4),
      gen.expandable(page: 6, cells: 5),
      gen.expandable(page: 7, cells: 6),
      gen.expandable(page: 8, cells: 7)
    ]

    let cells2: [Cellable] = [
      loaderCell(),
      gen.expandable(page: 9, cells: 1),
      gen.expandable(page: 10, cells: 2),
      gen.expandable(page: 11, cells: 3),
      gen.expandable(page: 12, cells: 3),
      gen.expandable(page: 13, cells: 4),
      gen.expandable(page: 14, cells: 5),
      gen.expandable(page: 15, cells: 6),
      gen.expandable(page: 16, cells: 7)
    ]

    return [Section(cells: cells1), Section(cells: cells2)]
  }

  private func loaderCell() -> LoaderExpandableCellable {
    let loader = TableCell<TestTableCell>(data: TestViewModel("indicator"))
    let cell = LoaderExpandableCell<UITableView, TestTableCell>(data: TestViewModel("loader"), loader: {
      let gen = TableGenerator<TestTableCell, TestTableHeader>()
      return SectionObservable.just([Section(cells: gen.cellsViews(page: 99, cells: 10))])
        .delay(1.0, scheduler: MainScheduler.instance)
        .concat(SectionObservable.just([Section(cells: gen.cellsViews(page: 99, cells: 10))])
                  .delay(2.0, scheduler: MainScheduler.instance))
    }, loaderCell: loader)
    cell.id = "indicator"
    return cell
  }
}

class ExpandableCollectionViewController: BaseCollectionViewController<CollectionViewExpandableSource> {

  override func cells() -> [Cellable]? {
    let gen = CollectionGenerator<TestCollectionCell, TestCollectionCell>()
    return [
      loaderCell(),
      gen.expandable(page: 1, cells: 1),
      gen.expandable(page: 2, cells: 2),
      gen.expandable(page: 3, cells: 3),
      gen.expandable(page: 4, cells: 3),
      gen.expandable(page: 5, cells: 4),
      gen.expandable(page: 6, cells: 5),
      gen.expandable(page: 7, cells: 6),
      gen.expandable(page: 8, cells: 7)
    ]
  }

  private func loaderCell() -> LoaderExpandableCellable {
    let loader = CollectionCell<TestCollectionCell>(data: TestViewModel("indicator"))
    let cell = LoaderExpandableCell<UICollectionView, TestCollectionCell>(data: TestViewModel("loader"), loader: {
      let gen = CollectionGenerator<TestCollectionCell, TestCollectionCell>()
      return SectionObservable.just([Section(cells: gen.cellsViews(page: 99, cells: 10))])
        .delay(1.0, scheduler: MainScheduler.instance)
        .concat(SectionObservable.just([Section(cells: gen.cellsViews(page: 99, cells: 10))])
                  .delay(2.0, scheduler: MainScheduler.instance))
    }, loaderCell: loader)
    cell.id = "indicator"
    return cell
  }
}
