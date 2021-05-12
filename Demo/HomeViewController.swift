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
  typealias Header = TableHeaderSection<TestTableHeader>

  // swiftlint:disable:next function_body_length
  override func allSections() -> [Sectionable]? {
    var tableCells: [Cellable] = [
      Item(data: TestViewModel("Source"), id: "Table Source") { [weak self] in
        self?.navigationController?.pushViewController(TableSourceViewController(), animated: true)
      }
    ]

#if !os(tvOS)
    tableCells.append(contentsOf: [
      Item(data: TestViewModel("Singe Selection Example"), id: "Singe Selection Example") { [weak self] in
        self?.navigationController?.pushViewController(SelectionTableViewController(with: .single, ids: []), animated: true)
      },
      Item(data: TestViewModel("Multiple Selection Example"), id: "Singe Selection Example") { [weak self] in
        self?.navigationController?.pushViewController(SelectionTableViewController(with: .multiple, ids: []), animated: true)
      }
    ])
#endif


    var collectionCells: [Cellable] = [
      Item(data: TestViewModel("Basic Collection Example"), id: "Basic Collection Source") { [weak self] in
        self?.navigationController?.pushViewController(BasicExampleCollectionViewController(), animated: true)
      }
    ]

#if !os(tvOS)
    collectionCells.append(contentsOf: [
      Item(data: TestViewModel("Singe Selection Collection Example"), id: "Singe Selection Collection Example") { [weak self] in
        self?.navigationController?.pushViewController(SelectionCollectionViewController(with: .single, ids: []), animated: true)
      },
      Item(data: TestViewModel("Multiple Selection Collection Example"), id: "Singe Selection Collection Example") { [weak self] in
        self?.navigationController?.pushViewController(SelectionCollectionViewController(with: .multiple, ids: []), animated: true)
      }
    ])
#endif

    collectionCells.append(contentsOf: [
      Item(data: TestViewModel("Source"), id: "Collection Source") { [weak self] in
        self?.navigationController?.pushViewController(CollectionSourceViewController(), animated: true)
      }
    ])

#if !os(tvOS)
    collectionCells.append(contentsOf: [
      Item(data: TestViewModel("Reuse Pager"), id: "Collection Reuse Pager") { [weak self] in
        self?.navigationController?.pushViewController(ReusePagerViewController(), animated: true)
      }
    ])
#endif

    return [
      Header(cells: tableCells, headerData: TestViewModel("Table View:"), page: 0) { [weak self] in
        self?.navigationController?.pushViewController(TableSourceViewController(), animated: true)
      },
      Header(cells: collectionCells, headerData: TestViewModel("Collection View:"))
    ]
  }
}
