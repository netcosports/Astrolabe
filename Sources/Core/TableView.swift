//
//  TableView.swift
//  Pods
//
//  Created by Sergei Mikhan on 9/25/17.
//
//

import UIKit

open class TableView<T: ReusableSource>: UITableView, AccessorView where T.Container == UITableView {

  public typealias Source = T
  public let source = T()

  public required init() {
    super.init(frame: .zero, style: .plain)
    internalInit()
  }

  public required init?(coder aDecoder: NSCoder) {
//    fatalError("init(coder:) has not been implemented")
    super.init(coder: aDecoder)
    internalInit()
  }
  
  private func internalInit() {
    source.containerView = self
    source.lastCellСondition = {
      if $0.section == $1
        && $0.item == $2 {
        return true
      }
      return false
    }
  }
}
