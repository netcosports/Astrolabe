//
//  SelectionViewController.swift
//  Demo
//
//  Created by Sergey Dikovitsky on 9/7/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import UIKit
import Astrolabe
import SnapKit

class SelectionCollectionViewController: BasicExampleCollectionViewController {

  let selectionBehavior: SelectionBehavior
  let initialSelectedIds: Set<String>

  init(with selectionBehavior: SelectionBehavior, ids initialSelectedIds: Set<String>) {
    self.selectionBehavior = selectionBehavior
    self.initialSelectedIds = initialSelectedIds
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) { fatalError() }

  override func viewDidLoad() {
    super.viewDidLoad()
    guard let source = source else {
      return
    }
    source.selectionBehavior = selectionBehavior
    source.selectedCellIds = initialSelectedIds
    source.selectionManagement = .automatic
  }

}

class SelectionTableViewController: TableSourceViewController {

  let selectionBehavior: SelectionBehavior
  let initialSelectedIds: Set<String>

  init(with selectionBehavior: SelectionBehavior, ids initialSelectedIds: Set<String>) {
    self.selectionBehavior = selectionBehavior
    self.initialSelectedIds = initialSelectedIds
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) { fatalError() }

  override func viewDidLoad() {
    super.viewDidLoad()
    source.selectionBehavior = selectionBehavior
    source.selectedCellIds = initialSelectedIds
    source.selectionManagement = .automatic
  }
  
}
