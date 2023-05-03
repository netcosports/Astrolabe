//
//  SelectionViewController.swift
//  Demo
//
//  Created by Sergey Dikovitsky on 9/7/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import UIKit
import Astrolabe

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

    containerView.source.selectionBehavior = selectionBehavior
    containerView.source.selectedCellIds = initialSelectedIds
    containerView.source.selectionManagement = .automatic
  }

}
