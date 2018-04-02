//
//  TableViewExpandableSource.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/6/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import RxSwift

// swiftlint:disable:next type_body_length
open class TableViewExpandableSource: TableViewSource {

  let disposeBag = DisposeBag()
  public var expandableBehavior = ExpandableBehavior(collapseDisabled: false)

  open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    var section = sections[indexPath.section]
    var sectionCells = section.cells
    let cell = sectionCells[indexPath.item]

    guard var expandableCell = cell as? ExpandableCellable else {
      super.tableView(tableView, didSelectRowAt: indexPath)
      return
    }

    guard let expandableCells = expandableCell.expandableCells else {
      expandableCell.expanded = !expandableCell.expanded
      tableView.reloadData()
      return
    }

    if expandableCell.expanded {
      if expandableBehavior.collapseDisabled { return }
      collapseItemInSection(section: &section,
                            expandableCell: &expandableCell,
                            sectionCells: &sectionCells,
                            sectionIndex: indexPath.section)
    } else {
      if var collapseableCell = expandedItemInSection(section: section, expandableCell: expandableCell) {
        collapseAndExpandItemInSection(section: &section,
                                       expandableCell: &expandableCell,
                                       collapseableCell: &collapseableCell,
                                       expandableCells: expandableCells,
                                       sectionCells: &sectionCells,
                                       sectionIndex: indexPath.section)
      } else {
        expandItemInSection(section: &section,
                            expandableCell: &expandableCell,
                            expandableCells: expandableCells,
                            sectionCells: &sectionCells,
                            sectionIndex: indexPath.section)
      }
    }

    handleLoaderCell(expandableCell: expandableCell, indexPath: indexPath)
  }

  override func setupCell(cellView: TableViewCell, cell: Cellable, indexPath: IndexPath) {
    super.setupCell(cellView: cellView, cell: cell, indexPath: indexPath)
    guard let expandableCell = cell as? ExpandableCellable else {
      return
    }
    cellView.expandedState = expandableCell.expanded
  }

  private func expandedItemInSection(section: Sectionable, expandableCell: ExpandableCellable) -> ExpandableCellable? {
    let allExpandedCells = section.cells.flatMap { $0 as? ExpandableCellable }.filter { $0.expanded }

    for expandedCell in allExpandedCells {
      if expandedCell.expandableCells?.filter({$0.id == expandableCell.id }).first != nil {
        let parentsCells = expandedCell.expandableCells?.flatMap { $0 as? ExpandableCellable }
        if let anotherExpandedCell = parentsCells?.filter({ $0.expanded }).first {
          return anotherExpandedCell
        } else {
          return nil
        }
      }
    }

    return allExpandedCells.first
  }

  private func expandItemInSection(section: inout Sectionable,
                                   expandableCell: inout ExpandableCellable,
                                   expandableCells: [Cellable],
                                   sectionCells: inout [Cellable],
                                   sectionIndex: Int) {
    let indexes = expandItems(section: &section,
                              expandableCell: expandableCell,
                              expandableCells: expandableCells,
                              sectionCells: &sectionCells,
                              sectionIndex: sectionIndex)
    registerCellsForSections()
    containerView?.insertRows(at: indexes, with: .automatic)

    expandableCell.expanded = !expandableCell.expanded
    if let indexPath = reloadCell(section: section, sectionIndex: sectionIndex, cell: expandableCell) {
      containerView?.scrollToRow(at: indexPath, at: .middle, animated: true)
    }
  }

  private func expandItems(section: inout Sectionable,
                           expandableCell: ExpandableCellable,
                           expandableCells: [Cellable],
                           sectionCells: inout [Cellable],
                           sectionIndex: Int) -> [IndexPath] {
    guard var indexToExpand = section.cells.index(where: { $0.id == expandableCell.id }) else {
      return []
    }
    indexToExpand += 1

    var indexes: [IndexPath] = []
    for indexToShow in 0..<expandableCells.count {
      let index = IndexPath(row: indexToExpand + indexToShow, section: sectionIndex)
      indexes.append(index)
    }
    sectionCells.insert(contentsOf: expandableCells, at: indexToExpand)
    section.cells = sectionCells
    return indexes
  }

  func collapseExpandableCell(section: inout Sectionable,
                              expandableCell: inout ExpandableCellable,
                              sectionIndex: Int) {
    var sectionCells = section.cells
    collapseItemInSection(section: &section,
                          expandableCell: &expandableCell,
                          sectionCells: &sectionCells,
                          sectionIndex: sectionIndex)
  }

  private func collapseItemInSection(section: inout Sectionable,
                                     expandableCell: inout ExpandableCellable,
                                     sectionCells: inout [Cellable],
                                     sectionIndex: Int) {
    let indexes = collapseItems(section: &section,
                                expandableCell: &expandableCell,
                                sectionCells: &sectionCells,
                                sectionIndex: sectionIndex)
    registerCellsForSections()
    containerView?.deleteRows(at: indexes, with: .automatic)

    expandableCell.expanded = !expandableCell.expanded
    _ = reloadCell(section: section, sectionIndex: sectionIndex, cell: expandableCell)
  }

  private func collapseItems(section: inout Sectionable,
                             expandableCell: inout ExpandableCellable,
                             sectionCells: inout [Cellable],
                             sectionIndex: Int) -> [IndexPath] {
    var indexes: [IndexPath] = []
    let ids = TableViewExpandableSource.cellAllData(cell: &expandableCell)
    for id in ids {
      guard let index = sectionCells.index(where: { $0.id == id }) else {
        continue
      }
      indexes.append(IndexPath(row: index, section: sectionIndex))
    }

    sectionCells = sectionCells.filter { cellable -> Bool in
      !ids.contains { id -> Bool in
        return cellable.id == id
      }
    }
    section.cells = sectionCells
    return indexes
  }

  // swiftlint:disable:next function_parameter_count
  private func collapseAndExpandItemInSection(section: inout Sectionable,
                                              expandableCell: inout ExpandableCellable,
                                              collapseableCell: inout ExpandableCellable,
                                              expandableCells: [Cellable],
                                              sectionCells: inout [Cellable],
                                              sectionIndex: Int) {

    let collapseIndexes = collapseItems(section: &section,
                                        expandableCell: &collapseableCell,
                                        sectionCells: &sectionCells,
                                        sectionIndex: sectionIndex)

    let expandIndexes = expandItems(section: &section,
                                    expandableCell: expandableCell,
                                    expandableCells: expandableCells,
                                    sectionCells: &sectionCells,
                                    sectionIndex: sectionIndex)

    registerCellsForSections()

    CATransaction.begin()

    expandableCell.expanded = !expandableCell.expanded
    collapseableCell.expanded = !collapseableCell.expanded

    let letSection = section
    let letExpandableCell = expandableCell
    CATransaction.setCompletionBlock {
      if let itemIndex = letSection.cells.index(where: { $0.id == letExpandableCell.id }) {
        let indexPath = IndexPath(row: itemIndex, section: sectionIndex)
        self.containerView?.scrollToRow(at: indexPath, at: .middle, animated: true)
      }
    }

    containerView?.beginUpdates()

    containerView?.deleteRows(at: collapseIndexes, with: .automatic)
    containerView?.insertRows(at: expandIndexes, with: .automatic)

    containerView?.endUpdates()

    CATransaction.commit()

    _ = reloadCell(section: section, sectionIndex: sectionIndex, cell: expandableCell)
    _ = reloadCell(section: section, sectionIndex: sectionIndex, cell: collapseableCell)
  }

  private func reloadCell(section: Sectionable, sectionIndex: Int, cell: Cellable) -> IndexPath? {
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

  static func cellAllData(cell: inout ExpandableCellable) -> [String] {
    var datas: [String] = []
    guard let subcells = cell.expandableCells else {
      return datas
    }

    subcells.forEach { subcell in
      guard var expandableCell = subcell as? ExpandableCellable else {
        datas.append(subcell.id)
        return
      }

      datas.append(expandableCell.id)
      if expandableCell.expanded {
        let ids = cellAllData(cell: &expandableCell)
        datas.append(contentsOf: ids)
      }

      expandableCell.expanded = false
    }

    return datas
  }

  private func handleLoaderCell(expandableCell: ExpandableCellable, indexPath: IndexPath) {
    guard var loaderExpandableCellable = expandableCell as? LoaderExpandableCellable else {
      return
    }

    switch loaderExpandableCellable.state {
    case .notInitiated:
      loaderExpandableCellable.performLoading()?.observeOn(MainScheduler.instance).subscribe(
        onNext: { [weak self] _ in
          self?.updateLoaderCell(loaderExpandableCell: &loaderExpandableCellable, indexPath: indexPath)
        },

        onError: { [weak self] _ in
          self?.updateLoaderCell(loaderExpandableCell: &loaderExpandableCellable, indexPath: indexPath)
        }
      ).disposed(by: disposeBag)
    default: break
    }
  }

  private func updateLoaderCell(loaderExpandableCell: inout LoaderExpandableCellable, indexPath: IndexPath) {
    if !loaderExpandableCell.expanded {
      loaderExpandableCell.expandableCells = loaderExpandableCell.loadedCells
      return
    }

    var section = sections[indexPath.section]
    var sectionCells = section.cells
    let loaderCell = loaderExpandableCell.loaderCell

    if let expandableCellIndex = sectionCells.index(where: { $0.id == loaderExpandableCell.id }) {
      var targetIndex = expandableCellIndex

      if let loaderIndex = sectionCells.index(where: { $0.id == loaderCell.id }) {
        containerView?.beginUpdates()
        targetIndex = loaderIndex
        sectionCells.remove(at: loaderIndex)
        containerView?.deleteRows(at: [IndexPath(row: loaderIndex, section: indexPath.section)], with: .automatic)
        if let loadedCells = loaderExpandableCell.loadedCells {
          var indexes: [IndexPath] = []
          (0..<loadedCells.count).forEach {
            indexes.append(IndexPath(row: targetIndex + $0, section: indexPath.section))
          }
          sectionCells.insert(contentsOf: loadedCells, at: targetIndex)
          section.cells = sectionCells
          registerCellsForSections()
          containerView?.insertRows(at: indexes, with: .automatic)
          loaderExpandableCell.expandableCells = loaderExpandableCell.loadedCells
        }
        containerView?.endUpdates()
      } else {
        if loaderExpandableCell.expandableCells != nil {
          loaderExpandableCell.expandableCells = loaderExpandableCell.loadedCells
          var expandableCell: ExpandableCellable = loaderExpandableCell
          TableViewExpandableSource.cellAllData(cell: &expandableCell).forEach { id in
            guard let index = sectionCells.index(where: { $0.id == id }) else { return }
            sectionCells.remove(at: index)
          }
          if let loadedCells = loaderExpandableCell.loadedCells {
            sectionCells.insert(contentsOf: loadedCells, at: expandableCellIndex + 1)
          }
          section.cells = sectionCells
          containerView?.reloadData()
        }
      }
    }
  }
}
