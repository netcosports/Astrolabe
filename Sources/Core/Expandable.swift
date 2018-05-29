//
//  Expandable.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 5/29/18.
//  Copyright © 2018 Netcosports. All rights reserved.
//

import UIKit
import RxSwift

protocol Expandable: class {
  associatedtype Container: ContainerView

  var disposeBag: DisposeBag { get }
  var expandableBehavior: ExpandableBehavior { get set }
  var expandedCells: Set<String> { get set }

  func isExpanded(cell: ExpandableCellable) -> Bool
  func adjust(cells: inout [Cellable]) -> [Cellable]
  func scroll(to indexPath: IndexPath)
  @discardableResult func reloadCell(section: Sectionable, sectionIndex: Int, cell: Cellable) -> IndexPath?
}

extension Expandable where Self: ReusableSource {

  func adjust(cells: inout [Cellable]) -> [Cellable] {
    cells.enumerated().forEach { index, cell in
      if let expandableCell = cell as? ExpandableCellable {
        if self.isExpanded(cell: expandableCell) {
          if var expandableCells = expandableCell.expandableCells {
            let adjustedCells = adjust(cells: &expandableCells)
            let adjustedCellsIds = adjustedCells.map { $0.id }
            cells = cells.filter { !adjustedCellsIds.contains($0.id) }
            cells.insert(contentsOf: adjustedCells, at: index + 1)
          }
        }
      }
    }
    return cells
  }

  func isExpanded(cell: ExpandableCellable) -> Bool {
    return expandedCells.contains(cell.id)
  }

  func allIds(in cell: inout ExpandableCellable) -> [String] {
    var ids: [String] = []
    guard let subcells = cell.expandableCells else {
      return ids
    }
    subcells.forEach { subcell in
      guard var expandableCell = subcell as? ExpandableCellable else {
        ids.append(subcell.id)
        return
      }
      ids.append(expandableCell.id)
      if isExpanded(cell: expandableCell) {
        let subids = allIds(in: &expandableCell)
        ids.append(contentsOf: subids)
      }
      self.expandedCells.remove(expandableCell.id)
    }
    return ids
  }

  func expandItems(section: inout Sectionable,
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

  func collapseItems(section: inout Sectionable,
                     expandableCell: inout ExpandableCellable,
                     sectionCells: inout [Cellable],
                     sectionIndex: Int) -> [IndexPath] {
    var indexes: [IndexPath] = []
    let ids = allIds(in: &expandableCell)
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

  func expandedItemInSection(section: Sectionable,
                             expandableCell: ExpandableCellable) -> ExpandableCellable? {
    let allExpandedCells = section.cells
      .compactMap { $0 as? ExpandableCellable }
      .filter { self.isExpanded(cell: $0) }

    for expandedCell in allExpandedCells {
      if expandedCell.expandableCells?.filter({$0.id == expandableCell.id }).first != nil {
        let parentsCells = expandedCell.expandableCells?.compactMap { $0 as? ExpandableCellable }
        if let anotherExpandedCell = parentsCells?.filter({ self.isExpanded(cell: $0) }).first {
          return anotherExpandedCell
        } else {
          return nil
        }
      }
    }

    return allExpandedCells.first
  }

  func expandItemInSection(section: inout Sectionable,
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
    containerView?.insert(at: indexes)

    if isExpanded(cell: expandableCell) {
      expandedCells.remove(expandableCell.id)
    } else {
      expandedCells.insert(expandableCell.id)
    }

    if let indexPath = reloadCell(section: section, sectionIndex: sectionIndex, cell: expandableCell) {
      self.scroll(to: indexPath)
    }
  }

  func collapseItemInSection(section: inout Sectionable,
                             expandableCell: inout ExpandableCellable,
                             sectionCells: inout [Cellable],
                             sectionIndex: Int) {
    let indexes = collapseItems(section: &section,
                                expandableCell: &expandableCell,
                                sectionCells: &sectionCells,
                                sectionIndex: sectionIndex)
    registerCellsForSections()
    containerView?.delete(at: indexes)

    if isExpanded(cell: expandableCell) {
      expandedCells.remove(expandableCell.id)
    } else {
      expandedCells.insert(expandableCell.id)
    }

    reloadCell(section: section, sectionIndex: sectionIndex, cell: expandableCell)
  }

  // swiftlint:disable:next function_parameter_count
  func collapseAndExpandItemInSection(section: inout Sectionable,
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
    if isExpanded(cell: expandableCell) {
      expandedCells.remove(expandableCell.id)
    } else {
      expandedCells.insert(expandableCell.id)
    }

    if isExpanded(cell: collapseableCell) {
      expandedCells.remove(collapseableCell.id)
    } else {
      expandedCells.insert(collapseableCell.id)
    }

    let letSection = section
    let letExpandableCell = expandableCell

    containerView?.batchUpdate(block: {
      self.containerView?.delete(at: collapseIndexes)
      self.containerView?.insert(at: expandIndexes)
    }, completion: { _ in
      if let itemIndex = letSection.cells.index(where: { $0.id == letExpandableCell.id }) {
        self.scroll(to: IndexPath(row: itemIndex, section: sectionIndex))
      }
    })
    reloadCell(section: section, sectionIndex: sectionIndex, cell: expandableCell)
    reloadCell(section: section, sectionIndex: sectionIndex, cell: collapseableCell)
  }

  func handleLoaderCell(expandableCell: ExpandableCellable,
                        indexPath: IndexPath) {
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

  func updateLoaderCell(loaderExpandableCell: inout LoaderExpandableCellable,
                        indexPath: IndexPath) {
    if isExpanded(cell: loaderExpandableCell) {
      let cells = loaderExpandableCell.loadedCells
      loaderExpandableCell.expandableCells = cells
      return
    }

    var section = sections[indexPath.section]
    var sectionCells = section.cells
    let loaderCell = loaderExpandableCell.loaderCell

    if let expandableCellIndex = sectionCells.index(where: { $0.id == loaderExpandableCell.id }) {
      var targetIndex = expandableCellIndex

      if let loaderIndex = sectionCells.index(where: { $0.id == loaderCell.id }) {
        containerView?.batchUpdate(block: {
          targetIndex = loaderIndex
          sectionCells.remove(at: loaderIndex)
          self.containerView?.delete(at: [IndexPath(row: loaderIndex, section: indexPath.section)])
          if let loadedCells = loaderExpandableCell.loadedCells {
            var indexes: [IndexPath] = []
            (0..<loadedCells.count).forEach {
              indexes.append(IndexPath(row: targetIndex + $0, section: indexPath.section))
            }
            sectionCells.insert(contentsOf: loadedCells, at: targetIndex)
            section.cells = sectionCells
            registerCellsForSections()
            containerView?.insert(at: indexes)
            let cells = loaderExpandableCell.loadedCells
            loaderExpandableCell.expandableCells = cells
          }
        }, completion: nil)
      } else {
        if loaderExpandableCell.expandableCells != nil {
          let cells = loaderExpandableCell.loadedCells
          loaderExpandableCell.expandableCells = cells
          var expandableCell: ExpandableCellable = loaderExpandableCell
          allIds(in: &expandableCell).forEach { id in
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

  func handle(expandableCell: inout ExpandableCellable,
              section: inout Sectionable,
              sectionCells: inout [Cellable],
              cell: Cellable,
              indexPath: IndexPath) {
    guard let expandableCells = expandableCell.expandableCells else {
      if isExpanded(cell: expandableCell) {
        expandedCells.remove(expandableCell.id)
      } else {
        expandedCells.insert(expandableCell.id)
      }
      containerView?.reloadData()
      return
    }

    if isExpanded(cell: expandableCell) {
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
}
