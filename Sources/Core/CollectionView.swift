//
//  TableView.swift
//  Pods
//
//  Created by Sergei Mikhan on 9/25/17.
//
//

import UIKit

open class CollectionView<T: ReusableSource>: UICollectionView, AccessorView where T.Container == UICollectionView {

  public typealias Source = T
  open let source = T()

  public required init() {
    super.init(frame: .zero, collectionViewLayout: CollectionViewSource.defaultLayout)
    source.containerView = self
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
