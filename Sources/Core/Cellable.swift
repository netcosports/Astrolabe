//
//  Cellable.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/9/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit

public typealias VoidClosure = (Void) -> Void
public typealias ClickClosure = VoidClosure
public typealias SetupClosure<T> = (T) -> Void

public enum CellType {
  case cell
  case header
  case footer
  case custom(kind: String)
}

public protocol Cellable {
  func register<T: ContainerView>(in container: T)
  func instance<T1: ContainerView, T2: ReusableView>(for container: T1, index: IndexPath) -> T2
  func setup<T: ReusableView>(with cell: T)
  func size<T: ContainerView>(with container: T) -> CGSize

  var click: ClickClosure? { get }
  var page: Int { get }

  // FIXME: need to clarify this
  var id: String { get }
}

public protocol ExpandableCellable: Cellable {
  var expandableCells: [Cellable]? { get set }
  var expanded: Bool { get set }
}

public protocol LoaderExpandableCellable: ExpandableCellable {
  func performLoading() -> SectionObservable?

  var state: LoaderState { get }
  var loadedCells: [Cellable]? { get }
  var loaderCell: Cellable { get }
}

public protocol Sectionable {
  var supplementaryTypes: [CellType] { get }
  func supplementary(for type: CellType) -> Cellable?
  var cells: [Cellable] { get set }
  var page: Int { get }
  var inset: UIEdgeInsets? { get set }
  var minimumLineSpacing: CGFloat? { get set }
  var minimumInteritemSpacing: CGFloat? { get set }
}
