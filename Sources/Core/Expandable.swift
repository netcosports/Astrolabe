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
  var loadingExpandableCells: [String: CellObservable] { get set }
  var loadedExpandableCells: [String: [Cellable]] { get set }
  var expandableSections: [Sectionable] { get set } 

  func isExpanded(cell: ExpandableCellable) -> Bool
  func adjust(newSections: [Sectionable], excludedCells: [String])
  func scroll(to indexPath: IndexPath)
  @discardableResult func reloadCell(section: Sectionable, sectionIndex: Int, cell: Cellable) -> IndexPath?
}

extension Expandable where Self: ReusableSource {

  func updateLoaderCell(loaderExpandableCell: LoaderExpandableCellable,
                        cells: [Cellable],
                        indexPath: IndexPath) {
    let section = sections[indexPath.section]
    let sectionCells = section.cells
    let loaderCell = loaderExpandableCell.loaderCell

    loadedExpandableCells[loaderExpandableCell.id] = cells
    guard isExpanded(cell: loaderExpandableCell) else {
      return
    }

    if  sectionCells.contains(where: { $0.id == loaderExpandableCell.id }) {
      if let loaderIndex = sectionCells.index(where: { $0.id == loaderCell.id }) {
        self.adjust(newSections: self.sections, excludedCells: [loaderCell.id])
        containerView?.batchUpdate(block: {
          self.containerView?.delete(at: [IndexPath(row: loaderIndex, section: indexPath.section)])
          if cells.count > 0 {
            let indexPaths = (0 ..< cells.count).map {
              IndexPath(row: loaderIndex + $0, section: indexPath.section)
            }
            self.containerView?.insert(at: indexPaths)
          }
        }, completion: nil)
      } else if expandableCells(for: loaderExpandableCell) != nil {
        self.adjust(newSections: sections, excludedCells: [loaderCell.id])
        containerView?.reloadData()
      }
    }
  }

  func handleLoaderCell(expandableCell: ExpandableCellable, indexPath: IndexPath) {
    guard let loaderExpandableCellable = expandableCell as? LoaderExpandableCellable else {
      return
    }

    guard !loadingExpandableCells.keys.contains(expandableCell.id) else { return }
    let observable = loaderExpandableCellable.load()
    loadingExpandableCells[expandableCell.id] = observable
    observable.observeOn(MainScheduler.instance).subscribe(
      onNext: { [weak self] cells in
        guard let cells = cells else { return }
        self?.updateLoaderCell(loaderExpandableCell: loaderExpandableCellable, cells: cells, indexPath: indexPath)
      },
      onError: { [weak self] error in
        self?.updateLoaderCell(loaderExpandableCell: loaderExpandableCellable, cells: [], indexPath: indexPath)
        self?.loadingExpandableCells.removeValue(forKey: loaderExpandableCellable.id)
      },
      onCompleted: { [weak self] in
        self?.loadingExpandableCells.removeValue(forKey: loaderExpandableCellable.id)
      }
    ).disposed(by: disposeBag)
  }

  func adjust(cells: inout [Cellable], excludedCells: [String]) -> [Cellable] {
    for (index, cell) in cells.enumerated() {
      guard let expandableCell = cell as? ExpandableCellable, isExpanded(cell: expandableCell) else { continue }

      if var expandableCells = expandableCells(for: expandableCell) {
        let adjustedCells = adjust(cells: &expandableCells, excludedCells: excludedCells)
        let adjustedCellsIds = adjustedCells.map { $0.id }
        cells = cells.filter { !adjustedCellsIds.contains($0.id) }
        cells.insert(contentsOf: adjustedCells, at: index + 1)
      }
    }
    return cells.filter { cell in !excludedCells.contains(where: { $0 == cell.id }) }
  }

  func adjust(newSections: [Sectionable], excludedCells: [String]) {
    for var section in newSections {
      let cells = adjust(cells: &section.cells, excludedCells: excludedCells)
      section.cells = cells
    }
    expandableSections = newSections
    registerCellsForSections()
  }

  func isExpanded(cell: ExpandableCellable) -> Bool {
    return expandedCells.contains(cell.id)
  }

  func allIds(in cell: inout ExpandableCellable) -> [String] {
    guard let subcells = expandableCells(for: cell) else { return [] }

    var ids: [String] = []
    ids.reserveCapacity(subcells.count)

    subcells.forEach { subcell in
      ids.append(subcell.id)
      guard var expandableCell = subcell as? ExpandableCellable else { return }

      if isExpanded(cell: expandableCell) {
        let subids = allIds(in: &expandableCell)
        ids.append(contentsOf: subids)
      }

      expandedCells.remove(expandableCell.id)
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

    let indexPaths = (0 ..< expandableCells.count).map { indexToShow in
      IndexPath(row: indexToExpand + indexToShow, section: sectionIndex)
    }
    sectionCells.insert(contentsOf: expandableCells, at: indexToExpand)
    section.cells = sectionCells
    return indexPaths
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
      .filter { isExpanded(cell: $0) }

    for expandedCell in allExpandedCells {
      guard expandableCells(for: expandedCell)?.filter({ $0.id == expandableCell.id }).first != nil else { continue }

      let parentsCells = expandableCells(for: expandedCell)?.compactMap { $0 as? ExpandableCellable }
      if let anotherExpandedCell = parentsCells?.filter({ self.isExpanded(cell: $0) }).first {
        return anotherExpandedCell
      } else {
        return nil
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

    if let indexPath = reloadCell(section: section, sectionIndex: sectionIndex, cell: expandableCell),
      !expandableBehavior.autoScrollToItemDisabled {
      scroll(to: indexPath)
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
                                      collapsibleCell: inout ExpandableCellable,
                                      expandableCells: [Cellable],
                                      sectionCells: inout [Cellable],
                                      sectionIndex: Int) {

    let collapseIndexes = collapseItems(section: &section,
                                        expandableCell: &collapsibleCell,
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

    if isExpanded(cell: collapsibleCell) {
      expandedCells.remove(collapsibleCell.id)
    } else {
      expandedCells.insert(collapsibleCell.id)
    }

    let letSection = section
    let letExpandableCell = expandableCell

    containerView?.batchUpdate(block: {
      self.containerView?.delete(at: collapseIndexes)
      self.containerView?.insert(at: expandIndexes)
    }, completion: { _ in
      if !self.expandableBehavior.autoScrollToItemDisabled,
        let itemIndex = letSection.cells.index(where: { $0.id == letExpandableCell.id }) {
        self.scroll(to: IndexPath(row: itemIndex, section: sectionIndex))
      }
    })
    reloadCell(section: section, sectionIndex: sectionIndex, cell: expandableCell)
    reloadCell(section: section, sectionIndex: sectionIndex, cell: collapsibleCell)
  }

  func handle(expandableCell: inout ExpandableCellable,
              section: inout Sectionable,
              sectionCells: inout [Cellable],
              cell: Cellable,
              indexPath: IndexPath) {
    guard let expandableCells = expandableCells(for: expandableCell) else {
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
      if expandableBehavior.collapseOtherOnExpand, var collapsibleCell = expandedItemInSection(section: section, expandableCell: expandableCell) {
        collapseAndExpandItemInSection(section: &section,
                                       expandableCell: &expandableCell,
                                       collapsibleCell: &collapsibleCell,
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

  func expandableCells(for cell: ExpandableCellable) -> [Cellable]? {
    if let expandableCells = loadedExpandableCells[cell.id] {
      return expandableCells
    }
    return cell.expandableCells
  }
}
