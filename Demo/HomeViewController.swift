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

  override func createSource() -> Source? {
    return TableViewSource(hostViewController: self)
  }

  // swiftlint:disable:next function_body_length
  override func sections() -> [Sectionable]? {
    let tableCells: [Cellable] = [
      Item(data: TestViewModel("Source"), id: "Table Source") { [weak self] in
        self?.navigationController?.pushViewController(TableSourceViewController(), animated: true)
      },
      Item(data: TestViewModel("Styled Source"), id: "Table Styled Source") { [weak self] in
        self?.navigationController?.pushViewController(TableStyledSourceViewController(), animated: true)
      },
      Item(data: TestViewModel("Loader Source infinite pageing"),
           id: "Table Loader Source infinite paging") { [weak self] in
        self?.navigationController?.pushViewController(TableLoaderSourceViewController(type: .infinitePaging),
                                                       animated: true)
      },
      Item(data: TestViewModel("Loader Source Empty"), id: "Table Loader Source empty") { [weak self] in
        self?.navigationController?.pushViewController(TableLoaderSourceViewController(type: .emptyPage1),
                                                       animated: true)
      },
      Item(data: TestViewModel("Loader Source Error"), id: "Table Loader Source Error") { [weak self] in
        self?.navigationController?.pushViewController(TableLoaderSourceViewController(type: .errorPage1),
                                                       animated: true)
      },
      Item(data: TestViewModel("Loader Source page 4 empty"), id: "Table Loader Source page 4 empty") { [weak self] in
        self?.navigationController?.pushViewController(TableLoaderSourceViewController(type: .emptyPage4),
                                                       animated: true)
      },
      Item(data: TestViewModel("Loader Source page 4 error"), id: "Table Loader Source page 4 error") { [weak self] in
        self?.navigationController?.pushViewController(TableLoaderSourceViewController(type: .errorPage4),
                                                       animated: true)
      },
      Item(data: TestViewModel("Expandable Source"), id: "Table Expandable Source") { [weak self] in
        self?.navigationController?.pushViewController(ExpandableTableViewController(), animated: true)
      }
    ]

    var collectionCells: [Cellable] = [
      Item(data: TestViewModel("Basic Collection Example"), id: "Basic Collection Source") { [weak self] in
        self?.navigationController?.pushViewController(BasicExampleCollectionViewController(), animated: true)
      },
      Item(data: TestViewModel("Basic Data Collection Example"), id: "Basic Data Collection Source") { [weak self] in
        self?.navigationController?.pushViewController(BasicDataExampleCollectionViewController(), animated: true)
      },
      Item(data: TestViewModel("Basic Timeline Collection Example"), id: "Basic Timeline Collection Source") { [weak self] in
        self?.navigationController?.pushViewController(BasicTimelineExampleCollectionViewController(), animated: true)
      },
      Item(data: TestViewModel("Source"), id: "Collection Source") { [weak self] in
        self?.navigationController?.pushViewController(CollectionSourceViewController(), animated: true)
      },
      Item(data: TestViewModel("Styled Source"), id: "Collection Source") { [weak self] in
        self?.navigationController?.pushViewController(CollectionStyledSourceViewController(), animated: true)
      },
      Item(data: TestViewModel("Loader Source infinite pageing"),
           id: "Collection Loader Source infinite paging") { [weak self] in
        self?.navigationController?.pushViewController(CollectionLoaderSourceViewController(type: .infinitePaging),
                                                       animated: true)
      },
      Item(data: TestViewModel("Loader Source Empty"), id: "Collection Loader Source empty") { [weak self] in
        self?.navigationController?.pushViewController(CollectionLoaderSourceViewController(type: .emptyPage1),
                                                       animated: true)
      },
      Item(data: TestViewModel("Loader Source Error"), id: "Collection Loader Source Error") { [weak self] in
        self?.navigationController?.pushViewController(CollectionLoaderSourceViewController(type: .errorPage1),
                                                       animated: true)
      },
      Item(data: TestViewModel("Loader Source page 4 empty"),
           id: "Collection Loader Source page 4 empty") { [weak self] in
        self?.navigationController?.pushViewController(CollectionLoaderSourceViewController(type: .emptyPage4),
                                                       animated: true)
      },
      Item(data: TestViewModel("Loader Source page 4 error"),
           id: "Collection Loader Source page 4 error") { [weak self] in
        self?.navigationController?.pushViewController(CollectionLoaderSourceViewController(type: .errorPage4),
                                                       animated: true)
      },
      Item(data: TestViewModel("Loader Source Expandable"), id: "Collection Loader Source Expandable") { [weak self] in
        self?.navigationController?.pushViewController(ExpandableCollectionViewController(), animated: true)
      }
    ]
#if !os(tvOS)
    let pagerCells: [Cellable] = [
      Item(data: TestViewModel("Pager"), id: "Collection Pager") { [weak self] in
        self?.navigationController?.pushViewController(PagerViewController(), animated: true)
      },
      Item(data: TestViewModel("Reuse Pager"), id: "Collection Reuse Pager") { [weak self] in
        self?.navigationController?.pushViewController(ReusePagerViewController(), animated: true)
      }
    ]
    collectionCells.append(contentsOf: pagerCells)
#endif

    return [
      Header(cells: tableCells, headerData: TestViewModel("Table View:"), page: 0) { [weak self] in
        self?.navigationController?.pushViewController(TableSourceViewController(), animated: true)
      },
      Header(cells: collectionCells, headerData: TestViewModel("Collection View:"))
    ]
  }
}
