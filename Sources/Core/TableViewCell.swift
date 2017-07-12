//
//  TableViewCell.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/4/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit

open class RootTableCell: UITableViewCell {

  public convenience init() {
    self.init(frame: CGRect.zero)
  }

  public required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
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
  open weak var containerViewController: UIViewController?
  open weak var containerView: UITableView?
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

open class StyledTableViewCell<Style>: TableViewCell {
  // NOTE: the idea currently is to initialize style only once
  // this will be managed outside of cell implementation
  open var style: Style? {
    didSet {
      if let style = style {
        setup(with: style)
      }
    }
  }

  open override func setup() {
    fatalError("Use setup method with style param")
  }

  override func internalSetup() {

  }

  open func setup(with style: Style) {

  }
}

open class ReusableWrapperTableViewCell<T: ReusableWrapper & Reusable>: TableViewCell, Reusable {
  public typealias View = T
  public typealias Data = T.Data

  var wrappedView: View?

  open override func setup() {
    if wrappedView == nil {
      wrappedView = View()
      wrappedView?.contentView = contentView
      wrappedView?.setup(with: self)
    }
  }

  public func setup(with data: Data) {
    wrappedView?.setup(with: data)
  }

  public static func size(for data: Data, containerSize: CGSize) -> CGSize {
    return View.size(for: data, containerSize: containerSize)
  }

  public static func identifier(for data: Data) -> String {
    return View.identifier(for: data)
  }
}
