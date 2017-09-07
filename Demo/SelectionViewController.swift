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

  let selectionState: SelectionState

  init(with selectionState: SelectionState) {
    self.selectionState = selectionState
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) { fatalError() }

  override func viewDidLoad() {
    super.viewDidLoad()
    guard let source = source else {
      return
    }
    source.selectionState = selectionState
    source.selectionManagement = .automatic
  }

}

class SelectionTableViewController: TableSourceViewController {

  let selectionState: SelectionState

  init(with selectionState: SelectionState) {
    self.selectionState = selectionState
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) { fatalError() }

  override func viewDidLoad() {
    super.viewDidLoad()
    source.selectionState = selectionState
    source.selectionManagement = .automatic
  }
  
}
