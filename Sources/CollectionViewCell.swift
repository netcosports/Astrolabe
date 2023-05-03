//
//  CollectionViewCell.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 7/1/16.
//  Copyright © 2016 Netcosports. All rights reserved.
//

import RxSwift
import UIKit

open class RootCollectionCell: UICollectionViewCell {

  convenience init() {
    self.init(frame: CGRect.zero)
  }

  public required override init(frame: CGRect) {
    super.init(frame: frame)
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

open class CollectionViewCell: RootCollectionCell, ReusableView {
  open var cell: Cellable?
  open weak var hostContainerView: UICollectionView?
  open weak var hostViewController: UIViewController?
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
