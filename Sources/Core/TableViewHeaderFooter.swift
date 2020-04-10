//
//  TableViewHeaderFooter.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/9/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit

open class RootTableHeaderFooter: UITableViewHeaderFooterView {

  public convenience init() {
    self.init(frame: CGRect.zero)
  }

  public required override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    internalSetup()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    internalSetup()
  }

  open override func awakeFromNib() {
    super.awakeFromNib()
    internalSetup()
  }

  open override class var requiresConstraintBasedLayout: Bool {
    return true
  }

  func internalSetup() {
    fatalError("should not be instantiated directly")
  }
}

open class TableViewHeaderFooter: RootTableHeaderFooter, ReusableView {
  open var cell: Cellable?
  open weak var hostViewController: UIViewController?
  open weak var hostContainerView: UITableView?
  open var indexPath: IndexPath?
  open var selectedState = false
  open var expandedState = false

  override func internalSetup() {
    setup()
  }

  open func setup() {

  }

  open func willDisplay() {

  }

  open func endDisplay() {

  }
}
