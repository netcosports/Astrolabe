//
//  TableView.swift
//  Pods
//
//  Created by Sergei Mikhan on 9/25/17.
//
//

import UIKit
import RxCocoa

open class CollectionView<T: ReusableSource>: UICollectionView, AccessorView where T.Container == UICollectionView {

  public typealias Source = T
  public let source = T()

  public required init() {
    super.init(frame: .zero, collectionViewLayout: CollectionViewSource.defaultLayout)
    source.containerView = self
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    source.containerView = self
  }

  private let _size = PublishRelay<CGSize>()
  private(set) lazy var sizeDidChange = ControlEvent<CGSize>(events: _size.distinctUntilChanged())

  open override func layoutSubviews() {
    super.layoutSubviews()

    _size.accept(frame.size)
  }

}
