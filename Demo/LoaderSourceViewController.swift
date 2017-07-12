//
//  LoaderSourceViewController.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/10/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import UIKit
import Astrolabe

class TableLoaderSourceViewController: BaseLoaderTableViewController<TableViewSource> {

  override func createSource() -> Source? {
    return TableViewSource(hostViewController: self)
  }

  override func sections(for page: Int) -> [Sectionable]? {
    let gen = TableGenerator<TestTableCell, TestTableHeader>()
    return [
      gen.headerSection(page: page, cells: page)
    ]
  }

}

class CollectionLoaderSourceViewController: BaseLoaderCollectionViewController<CollectionViewSource> {

  override func createSource() -> Source? {
    return CollectionViewSource(hostViewController: self, layout: collectionViewLayout())
  }

  override func sections(for page: Int) -> [Sectionable]? {
    let gen = CollectionGenerator<TestCollectionCell, TestCollectionCell>()
    return [
      gen.headerSection(page: page, cells: page)
    ]
  }
}
