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

open class Section: Sectionable {
  public var cells: [Cellable]
  public var id: String = ""

  public var equals: EqualsClosure<Sectionable>?

  public var inset: UIEdgeInsets?
  public var minimumLineSpacing: CGFloat?
  public var minimumInteritemSpacing: CGFloat?

  public init(
    cells: [Cellable],
    id: String = "",
    inset: UIEdgeInsets? = nil,
    minimumLineSpacing: CGFloat? = nil,
    minimumInteritemSpacing: CGFloat? = nil
  ) {
    self.cells = cells
    self.id = id
    self.inset = inset
    self.minimumLineSpacing = minimumLineSpacing
    self.minimumInteritemSpacing = minimumInteritemSpacing

    self.equals = { [weak self] in
      guard let self = self, !$0.id.isEmpty && !self.id.isEmpty else {
        assertionFailure("id of a section must not be empty string")
        return false
      }
      return self.id == $0.id
    }
  }

  public var supplementaryTypes: [CellType] { return [] }

  public func supplementaries(for type: CellType) -> [Cellable] {
    return []
  }
}

open class MultipleSupplementariesSection: Section {

  let supplementaries: [Cellable]
  
  public init(
    supplementaries: [Cellable],
    cells: [Cellable],
    inset: UIEdgeInsets? = nil,
    minimumLineSpacing: CGFloat? = nil,
    minimumInteritemSpacing: CGFloat? = nil
  ) {
    self.supplementaries = supplementaries
    super.init(
      cells: cells,
      inset: inset,
      minimumLineSpacing: minimumLineSpacing,
      minimumInteritemSpacing: minimumInteritemSpacing
    )
  }

  public override var supplementaryTypes: [CellType] {
    return supplementaries.map { $0.type }
  }

  public override func supplementaries(for type: CellType) -> [Cellable] {
    return supplementaries.filter { $0.type == type }
  }
}
