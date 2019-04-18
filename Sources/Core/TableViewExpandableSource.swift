//
//  TableViewExpandableSource.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/6/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import RxSwift

open class TableViewExpandableSource: TableViewSource, Expandable {

  let disposeBag = DisposeBag()
  public var expandableBehavior = ExpandableBehavior()
  public var expandedCells: Set<String> = []
  public var loadingExpandableCells: [String : CellObservable] = [:]
  public var loadedExpandableCells: [String : [Cellable]] = [:]
  public var expandableSections: [Sectionable] = []
  override public var sections: [Sectionable] {

    set {
      adjust(newSections: newValue, excludedCells: [])
      dataSource.sections = self.sections
    }

    get {
      return expandableSections
    }
  }

  override func setup(cellView: TableViewCell, with cell: Cellable) {
    super.setup(cellView: cellView, with: cell)
    guard let expandableCell = cell as? ExpandableCellable else { return }
    cellView.expandedState = isExpanded(cell: expandableCell)
  }

  override func click(cell: Cellable, indexPath: IndexPath) {
    super.click(cell: cell, indexPath: indexPath)
    var section = sections[indexPath.section]
    var sectionCells = section.cells
    let cell = sectionCells[indexPath.item]

    guard var expandableCell = cell as? ExpandableCellable else { return }

    handle(expandableCell: &expandableCell,
           section: &section,
           sectionCells: &sectionCells,
           cell: cell,
           indexPath: indexPath)
  }

  @discardableResult func reloadCell(section: Sectionable, sectionIndex: Int, cell: Cellable) -> IndexPath? {
    guard let itemIndex = section.cells.index(where: { $0.id == cell.id }) else {
      return nil
    }

    let indexPath = IndexPath(row: itemIndex, section: sectionIndex)

    if let cellView = containerView?.cellForRow(at: indexPath) as? TableViewCell {
      setup(cellView: cellView, with: cell)
      cell.setup(with: cellView)
    } else {
      UIView.performWithoutAnimation {
        self.containerView?.reloadRows(at: [indexPath], with: .automatic)
      }
    }
    return indexPath
  }

  func scroll(to indexPath: IndexPath) {
    containerView?.scrollToRow(at: indexPath, at: .middle, animated: true)
  }
}
