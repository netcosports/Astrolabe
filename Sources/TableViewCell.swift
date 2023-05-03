//
//  TableViewCell.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/4/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import RxSwift
import UIKit

open class RootTableCell: UITableViewCell {

  public convenience init() {
    self.init(frame: CGRect.zero)
  }

  public required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    internalSetup()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    selectionStyle = .none
    internalSetup()
  }

  open override func awakeFromNib() {
    super.awakeFromNib()
    selectionStyle = .none
    internalSetup()
  }

  open override class var requiresConstraintBasedLayout: Bool {
    return true
  }

  func internalSetup() {
    fatalError("should not be instantiated directly")
  }
}

open class TableViewCell: RootTableCell, ReusableView {
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
