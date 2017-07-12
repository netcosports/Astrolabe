//
//  StyledSourceViewController.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/10/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import UIKit
import Astrolabe

class TableStyledSourceViewController: BaseTableViewController<TableViewSource> {

  override func createSource() -> Source? {
    return TableViewSource(hostViewController: self)
  }

  override func sections() -> [Sectionable]? {
    let gen = TableStyledGenerator<TestTableStyledCell, TestTableHeader>()
    return [
      gen.section(page: 0, cells: 3),
      gen.footerSection(page: 1, cells: 4),
      gen.headerSection(page: 2, cells: 5),
      gen.headerFooterSection(page: 3, cells: 6)
    ]
  }

}

class CollectionStyledSourceViewController: BaseCollectionViewController<CollectionViewSource> {

  override func createSource() -> Source? {
    return CollectionViewSource(hostViewController: self, layout: collectionViewLayout())
  }

  override func sections() -> [Sectionable]? {
    let gen = CollectionStyledGenerator<TestStyledCollectionCell, TestCollectionCell>()
    return [
      gen.section(page: 0, cells: 3),
      gen.footerSection(page: 1, cells: 4),
      gen.headerSection(page: 2, cells: 5),
      gen.headerFooterSection(page: 3, cells: 6)
    ]
  }
}
