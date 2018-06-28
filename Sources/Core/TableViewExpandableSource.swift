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
  public var expandableBehavior = ExpandableBehavior(collapseDisabled: false)
  public var expandedCells: Set<String> = []
  fileprivate var expandableSections: [Sectionable] = []
  override public var sections: [Sectionable] {

    set {
      let newSections = newValue
      for var section in newSections {
        let cells = adjust(cells: &section.cells)
        section.cells = cells
      }
      expandableSections = newSections
      registerCellsForSections()
    }

    get {
      return expandableSections
    }
  }

  open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    var section = sections[indexPath.section]
    var sectionCells = section.cells
    let cell = sectionCells[indexPath.item]

    guard var expandableCell = cell as? ExpandableCellable else {
      super.tableView(tableView, didSelectRowAt: indexPath)
      return
    }

    handle(expandableCell: &expandableCell,
           section: &section,
           sectionCells: &sectionCells,
           cell: cell,
           indexPath: indexPath)
  }

  override func setupCell(cellView: TableViewCell, cell: Cellable, indexPath: IndexPath) {
    super.setupCell(cellView: cellView, cell: cell, indexPath: indexPath)
    guard let expandableCell = cell as? ExpandableCellable else {
      return
    }
    cellView.expandedState = isExpanded(cell: expandableCell)
  }

  @discardableResult func reloadCell(section: Sectionable, sectionIndex: Int, cell: Cellable) -> IndexPath? {
    guard let itemIndex = section.cells.index(where: { $0.id == cell.id }) else {
      return nil
    }

    let indexPath = IndexPath(row: itemIndex, section: sectionIndex)

    if let cellView = containerView?.cellForRow(at: indexPath) as? TableViewCell {
      setupCell(cellView: cellView, cell: cell, indexPath: indexPath)
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
