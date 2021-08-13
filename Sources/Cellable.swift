//
//  Cellable.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/9/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit

import RxSwift

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

open class DataHodler<Data> {

  public var data: Data

  public init(data: Data) {
    self.data = data
  }
}

public protocol Cellable {
  func register<T: ContainerView>(in container: T)
  func instance<T1: ContainerView, T2: ReusableView>(for container: T1, index: IndexPath) -> T2
  func setup<T: ReusableView>(with cell: T)
  func size<T: ContainerView>(with container: T) -> CGSize

  var type: CellType { get }

  func handleClickEvent()
}
