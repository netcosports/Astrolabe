//
//  LoaderSourceViewController.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/10/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import UIKit
import Astrolabe

class TableLoaderSourceViewController: BaseLoaderTableViewController<LoaderDecoratorSource<TableViewSource>> {

  override func loadView() {
    super.loadView()
    source.loader = self
  }

  override func sections(for page: Int) -> [Sectionable]? {
    let gen = TableGenerator<TestTableCell, TestTableHeader>()
    return [
      gen.headerSection(page: page, cells: page)
    ]
  }

}

class CollectionLoaderSourceViewController: BaseLoaderCollectionViewController<LoaderDecoratorSource<CollectionViewSource>> {

  override func loadView() {
    super.loadView()
    source.loader = self
  }

  override func sections(for page: Int) -> [Sectionable]? {
    let gen = CollectionGenerator<TestCollectionCell, TestCollectionCell>()
    return [
      gen.headerSection(page: page, cells: page)
    ]
  }
}
