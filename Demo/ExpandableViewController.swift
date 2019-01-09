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

class ExpandableTableViewController: BaseLoaderTableViewController<LoaderDecoratorSource<TableViewExpandableSource>> {

  override func viewDidLoad() {
    super.viewDidLoad()
    source.loader = LoaderMediator(loader: self)
    source.loadingBehavior = [.appearance, .autoupdate]
  }

  override func sections(for page: Int) -> [Sectionable]? {
    let gen = TableGenerator<TestTableCell, TestTableHeader>()
    let cells1: [Cellable] = [
      loaderCell(for: 1),
      loaderCell(for: 2),
      loaderCell(for: 3),
      loaderCell(for: 4),
      gen.expandable(page: 10 * page + 1, cells: 1),
      gen.expandable(page: 10 * page + 2, cells: 2),
      gen.expandable(page: 10 * page + 3, cells: 3),
      gen.expandable(page: 10 * page + 4, cells: 3),
      gen.expandable(page: 10 * page + 5, cells: 4),
      gen.expandable(page: 10 * page + 6, cells: 5),
      gen.expandable(page: 10 * page + 7, cells: 6),
      gen.expandable(page: 10 * page + 8, cells: 7)
    ]

    return [Section(cells: cells1, page: page)]
  }

  private func loaderCell(for page: Int) -> LoaderExpandableCellable {
    let loader = TableCell<TestTableCell>(data: TestViewModel("indicator \(page)"), id: "indicator \(page)")
    return LoaderExpandableCell<UITableView, TestTableCell>(data: TestViewModel("loader \(page)"), id: "Loader \(page)", loader: {
      let gen = TableGenerator<TestTableCell, TestTableHeader>()
      return CellObservable.just(gen.cellsViews(page: 1000 * page + 99, cells: 10))
        .delay(1.0, scheduler: MainScheduler.instance)
    }, loaderCell: loader)
  }
}

class ExpandableCollectionViewController: BaseLoaderCollectionViewController<LoaderDecoratorSource<CollectionViewExpandableSource>> {

  override func viewDidLoad() {
    super.viewDidLoad()
    source.loader = LoaderMediator(loader: self)
    source.loadingBehavior = [.appearance, .autoupdate, .paging]
  }

  override func sections(for page: Int) -> [Sectionable]? {
    let gen = CollectionGenerator<TestCollectionCell, TestCollectionCell>()
    let cells1: [Cellable] = [
      gen.expandable(page: 10 * page + 1, cells: 1),
      gen.expandable(page: 10 * page + 2, cells: 2),
      gen.expandable(page: 10 * page + 3, cells: 3),
      gen.expandable(page: 10 * page + 4, cells: 3),
      gen.expandable(page: 10 * page + 5, cells: 4),
      gen.expandable(page: 10 * page + 6, cells: 5),
      gen.expandable(page: 10 * page + 7, cells: 6),
      gen.expandable(page: 10 * page + 8, cells: 7)
    ]

    return [Section(cells: cells1, page: page)]
  }

  private func loaderCell() -> LoaderExpandableCellable {
    let loader = CollectionCell<TestCollectionCell>(data: TestViewModel("indicator"))
    return LoaderExpandableCell<UICollectionView, TestCollectionCell>(data: TestViewModel("loader"), id: "indicator", loader: {
      let gen = CollectionGenerator<TestCollectionCell, TestCollectionCell>()
      return CellObservable.just(gen.cellsViews(page: 99, cells: 10))
        .delay(1.0, scheduler: MainScheduler.instance)
    }, loaderCell: loader)
  }
}
