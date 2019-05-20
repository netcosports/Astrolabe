//
//  Cellable.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/9/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit

public typealias VoidClosure = () -> Void
public typealias ClickClosure = VoidClosure
public typealias SetupClosure<T> = (T) -> Void
public typealias LastCellConditionClosure = (_ path: IndexPath, _ sectionsCounts: Int, _ itemsInSectionCount: Int) -> Bool

public enum CellType: Hashable {
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

  var type: CellType { get }
  var click: ClickClosure? { get }
  var page: Int { get }

  // FIXME: need to clarify this
  var id: String { get }
}

public protocol ExpandableCellable: Cellable {
  var expandableCells: [Cellable]? { get set }
}

public protocol LoaderExpandableCellable: ExpandableCellable {
  func load() -> CellObservable
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
