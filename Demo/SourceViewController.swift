//
//  TableSourceViewController.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/10/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import UIKit
import Astrolabe

class TableSourceViewController: BaseTableViewController<TableViewSource> {

  override func sections() -> [Sectionable]? {
    let gen = TableGenerator<TestTableCell, TestTableHeader>()
    let wrappergen = TableGenerator<TestTableCell, TestTableHeader>()
    return [
      wrappergen.headerSection(page: 0, cells: 5),
      gen.section(page: 1, cells: 3),
      gen.footerSection(page: 2, cells: 4),
      gen.headerSection(page: 3, cells: 5),
      gen.headerFooterSection(page: 4, cells: 6)
    ]
  }

}

class CollectionSourceViewController: BaseCollectionViewController<CollectionViewSource> {

  override func sections() -> [Sectionable]? {
    let gen = CollectionGenerator<TestCollectionCell, TestCollectionCell>()
    let wrappergen = CollectionGenerator<TestCollectionCell, TestCollectionCell>()
    return [
      wrappergen.headerSection(page: 0, cells: 5),
      gen.section(page: 1, cells: 3),
      gen.footerSection(page: 2, cells: 4),
      gen.headerSection(page: 3, cells: 5),
      gen.headerFooterSection(page: 4, cells: 6)
    ]
  }
}
