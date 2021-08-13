//
//  Section.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/9/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

public struct Section<
  SectionState: Hashable,
  CellState: Hashable
> {

  public var cells: [Cell<CellState>]
  public let supplementaries: [Cellable]

  public let state: SectionState

  public let inset: UIEdgeInsets?
  public let minimumLineSpacing: CGFloat?
  public let minimumInteritemSpacing: CGFloat?

  public init(
    cells: [Cell<CellState>],
    state: SectionState,
    supplementaries: [Cellable],
    inset: UIEdgeInsets? = nil,
    minimumLineSpacing: CGFloat? = nil,
    minimumInteritemSpacing: CGFloat? = nil
  ) {
    self.cells = cells
    self.state = state
    self.supplementaries = supplementaries
    self.inset = inset
    self.minimumLineSpacing = minimumLineSpacing
    self.minimumInteritemSpacing = minimumInteritemSpacing
  }

  public var supplementaryTypes: [CellType] {
    return supplementaries.map { $0.type }
  }

  public func supplementaries(for type: CellType) -> [Cellable] {
    return supplementaries.filter { $0.type == type }
  }
}

