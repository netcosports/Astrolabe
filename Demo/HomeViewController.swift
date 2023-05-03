//
//  HomeViewController.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/3/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import SnapKit
import Astrolabe

class HomeViewController: BaseTableViewController<TableViewSource> {
  typealias Item = TableCell<TestTableCell>

  // swiftlint:disable:next function_body_length
  override func allSections() -> [Sectionable]? {
    var tableCells: [Cellable] = [
      Item(data: TestViewModel("Source"))
    ]

#if !os(tvOS)
    tableCells.append(contentsOf: [
      Item(data: TestViewModel("Singe Selection Example")),
      Item(data: TestViewModel("Multiple Selection Example"))
    ])
#endif


    var collectionCells: [Cellable] = [
      Item(data: TestViewModel("Basic Collection Example"))
    ]

#if !os(tvOS)
    collectionCells.append(contentsOf: [
      Item(data: TestViewModel("Singe Selection Collection Example")) ,
      Item(data: TestViewModel("Multiple Selection Collection Example"))
    ])
#endif

    collectionCells.append(contentsOf: [
      Item(data: TestViewModel("Source"))
    ])

#if !os(tvOS)
    collectionCells.append(contentsOf: [
      Item(data: TestViewModel("Reuse Pager"))
    ])
#endif

    return [
      Section(cells: tableCells, id: "Table View:"),
      Section(cells: collectionCells, id: "Collection View:")
    ]
  }
}
