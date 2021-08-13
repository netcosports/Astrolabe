//
//  TableView.swift
//  Pods
//
//  Created by Sergei Mikhan on 9/25/17.
//
//

import UIKit
import RxCocoa

open class CollectionView<T: ReusableSource>: UICollectionView where T.Container == UICollectionView {

  public typealias Source = T
  public let source = T()

  public required init() {
    super.init(frame: .zero, collectionViewLayout: CollectionViewSource<T.SectionState, T.CellState>.defaultLayout)
    internalInit()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    internalInit()
  }

  private let _size = PublishRelay<CGSize>()
  private(set) lazy var sizeDidChange = ControlEvent<CGSize>(events: _size.distinctUntilChanged())

  open override func layoutSubviews() {
    super.layoutSubviews()

    _size.accept(frame.size)
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
