//
//  DiffUtils.swift
//  Astrolabe-iOS
//
//  Created by Alexander Zhigulich on 4/23/19.
//

import Foundation

/** The result of the difference */
public struct CollectionUpdateContext {

  /** Inserted cells index paths */
  public let inserted: [IndexPath]

  /** Deleted cells index paths */
  public let deleted: [IndexPath]

  /** Updated cell index paths */
  public let updated: [IndexPath]

  /** Inserted section indecies */
  public let insertedSections: IndexSet

  /** Deleted section indecies */
  public let deletedSections: IndexSet

  /** Updated section indecies */
  public let updatedSections: IndexSet

  public init(
    inserted: [IndexPath] = [],
    deleted: [IndexPath] = [],
    updated: [IndexPath] = [],
    insertedSections: IndexSet = IndexSet(),
    deletedSections: IndexSet = IndexSet(),
    updatedSections: IndexSet = IndexSet()
  ) {
    self.inserted = inserted
    self.deleted = deleted
    self.updated = updated
    self.insertedSections = insertedSections
    self.deletedSections = deletedSections
    self.updatedSections = updatedSections
  }
}

/** Error to throw */
public enum DiffError: Error {
  case error(String)
}

/** Utility class to manage differences between new and old sources */
open class DiffUtils<
  SectionState: Hashable,
  CellState: Hashable
> {

  // MARK: - Open API

  /**
   Calculate difference safely.
   If no difference found nil returned.
   If data inconsistent no error thrown but nil returned and assertion fired into DEBUG

   - parameter newSections: new sections source
   - parameter oldSections: old sections source
   - returns: CollectionUpdateContext instance or nil
   */
  open class func diff(
    new newSections: [Section<SectionState, CellState>],
    old oldSections: [Section<SectionState, CellState>]
    ) -> CollectionUpdateContext? {
    do {
      return try diffOrThrow(new: newSections, old: oldSections)
    } catch DiffError.error(let message) {
      assertionFailure(message)
      return nil
    } catch let error {
      assertionFailure(error.localizedDescription)
      return nil
    }
  }

  /**
   Calculate difference.
   If no difference found nil returned.

   - parameter newSections: new sections source
   - parameter oldSections: old sections source
   - returns: CollectionUpdateContext instance or nil
   - throws: DiffError if data inconsistent
   */
  open class func diffOrThrow(
    new newSections: [Section<SectionState, CellState>],
    old oldSections: [Section<SectionState, CellState>]
    ) throws -> CollectionUpdateContext? {

//    /*
//     Check validity of sections.
//     - id
//     - equals closure
//     */
//    let allSections = newSections + oldSections
//    if let section = allSections.first(where: { $0.id.isEmpty || $0.equals == nil }) {
//      throw DiffError.error("Check section id, equals closure: \(section)")
//    }
    if Set(newSections.map({ $0.state })).count != newSections.count {
      throw DiffError.error("Check new section ids: collision detected")
    }
    if Set(oldSections.map({ $0.state })).count != oldSections.count {
      throw DiffError.error("Check old section ids: collision detected")
    }

    /*
     Check validity of section suppelementary cells.
     - id
     - equals closure
     - data equals closure
     */
//    let allSupplyCellsOnly = allSections.compactMap({ $0.supplyCellsOnly() }).reduce([], +)
//    if let cell = allSupplyCellsOnly.first(where: { $0.id.isEmpty || $0.equals == nil }) {
//      throw DiffError.error("Check supplementary cell id, equals closure, data equals closure: \(cell)")
//    }
//    try newSections.forEach { section in
//      let supplyCellsOnly = section.supplyCellsOnly()
//      if Set(supplyCellsOnly.map({ $0.sta })).count != supplyCellsOnly.count {
//        throw DiffError.error("Check supplementary cell ids: collision detected for new section \(section)")
//      }
//    }
//    try oldSections.forEach { section in
//      let supplyCellsOnly = section.supplyCellsOnly()
//      if Set(supplyCellsOnly.map({ $0.id })).count != supplyCellsOnly.count {
//        throw DiffError.error("Check supplementary cell ids: collision detected for old section \(section)")
//      }
//    }

    /*
     Check validity of cells
     - id
     - equals closure
     - data equals closure
     */
//    let allCellsOnly = allSections.compactMap({ $0.cellsOnly() }).reduce([], +)
//    if let cell = allCellsOnly.first(where: { $0.id.isEmpty || $0.equals == nil }) {
//      throw DiffError.error("Check cell id, equals closure, data equals closure: \(cell)")
//    }
    try newSections.forEach { section in
      let cellsOnly = section.cellsOnly()
      if Set(cellsOnly.map({ $0.state })).count != cellsOnly.count {
        throw DiffError.error("Check cell ids: collision detected for new section \(section)")
      }
    }
    try oldSections.forEach { section in
      let cellsOnly = section.cellsOnly()
      if Set(cellsOnly.map({ $0.state })).count != cellsOnly.count {
        throw DiffError.error("Check cell ids: collision detected for old section \(section)")
      }
    }

    /*
     Detect inserted sections
     */
    var insertedSections = newSections.filter { !containsSection(in: oldSections, $0) }
    var insertedSectionsIndecies = insertedSections.compactMap { firstIndexOfSection(in: newSections, $0) }

    /*
     Detect deleted sections
     */
    var deletedSections = oldSections.filter { !containsSection(in: newSections, $0) }
    var deletedSectionsIndecies = deletedSections.compactMap { firstIndexOfSection(in: oldSections, $0) }

    /*
     Detect updated sections.
     By checking index changes.
     By bypassing it's supplementary items and checking it's equals and dataEquals closures.
     */
    var updatedSections = [Section<SectionState, CellState>]()
    var updatedSectionsIndecies = [Int]()
    for (oldSectionIndex, oldSectionToDiscover) in oldSections.enumerated() {

      /* Skip already deleted sections */
      if containsSection(in: deletedSections, oldSectionToDiscover) {
        continue
      }

      guard let newSectionToDiscover = newSections.first(where: { oldSectionToDiscover.state == $0.state }) else {
        assertionFailure("should not happen")
        continue
      }

      /*
       Check if section moved
       Then don't move but delete/insert intead (safest way for sections)
       */
      if let sameNewSectionIndex = firstIndexOfSection(in: newSections, newSectionToDiscover),
        oldSectionIndex != sameNewSectionIndex {

        deletedSections.append(oldSectionToDiscover)
        deletedSectionsIndecies.append(oldSectionIndex)

        insertedSections.append(newSectionToDiscover)
        insertedSectionsIndecies.append(sameNewSectionIndex)

        continue
      }

      /*
       If at least one supplementary item has been changed, mark all section as reloaded
       Note: all cells in this section will also be re-requested from appropriate delegate
       */
      var updated = false
      let newSupplyCells = newSectionToDiscover.supplyCellsOnly()
      let oldSupplyCells = oldSectionToDiscover.supplyCellsOnly()

      // NOTE: we only handle case when count of supplimentories updated
      if newSupplyCells.map({ $0.type }) != oldSupplyCells.map({ $0.type }) {
        updated = true
      }

      if updated {
        updatedSections.append(oldSectionToDiscover)
        updatedSectionsIndecies.append(oldSectionIndex)
      }
    }

    /*
     Detect deleted and updated cells only in sections
     that are not inserted, deleted or updated which were detected from the above.
     */
    var deletedIndecies = [IndexPath]()
    var updatedIndecies = [IndexPath]()
    for (oldSectionIndex, oldSectionToDiscover) in oldSections.enumerated() {

      /* Skip already inserted, deleted and updated sections */
      if containsSection(in: insertedSections, oldSectionToDiscover) ||
         containsSection(in: deletedSections, oldSectionToDiscover) ||
         containsSection(in: updatedSections, oldSectionToDiscover) {
        continue
      }

      guard let newSectionIndex = firstIndexOfSection(in: newSections, oldSectionToDiscover) else {
        assertionFailure("should not happen")
        continue
      }

      let newSectionToDiscover = newSections[newSectionIndex]

      /*
       Detect deleted and updated cells in current section normally.
       When detecting updated cells we compare it's index and datas
       using dedicated dataEquals closure assuming closure is provided
       (if not assertion will be fired or error thrown from verification section in the beginning)
       */

      var deletedIndeciesForSection = [IndexPath]()
      var updatedIndeciesForSection = [IndexPath]()

      let oldSectionCellsOnly = oldSectionToDiscover.cellsOnly()
      for (oldCellIndex, oldCell) in oldSectionCellsOnly.enumerated() {

        if let sameNewCell = newSectionToDiscover.firstCellLike(oldCell) {
          /* Check if cell moved otherwise compare datas */
          if let sameNewCellIndex = newSectionToDiscover.firstIndexOfCell(oldCell),
            oldCellIndex != sameNewCellIndex ||
              !areCellableDatasEqual(cell1: sameNewCell, cell2: oldCell) {
            updatedIndeciesForSection.append(IndexPath(row: oldCellIndex, section: oldSectionIndex))
          }
        }
      }

      for (oldCellIndex, oldCell) in oldSectionToDiscover.cellsOnly().enumerated() {
        if !newSectionToDiscover.containsCell(oldCell) {
          deletedIndeciesForSection.append(IndexPath(row: oldCellIndex, section: oldSectionIndex))
        }
      }

      deletedIndecies.append(contentsOf: deletedIndeciesForSection)
      updatedIndecies.append(contentsOf: updatedIndeciesForSection)
    }

    /*
     Detect inserted cells
     */
    var insertedIndecies = [IndexPath]()
    for (newSectionIndex, newSectionToDiscover) in newSections.enumerated() {

      /* Skip already inserted, deleted and updated sections */
      if containsSection(in: insertedSections, newSectionToDiscover) ||
         containsSection(in: deletedSections, newSectionToDiscover) ||
         containsSection(in: updatedSections, newSectionToDiscover) {
        continue
      }

      guard let oldSectionIndex = firstIndexOfSection(in: oldSections, newSectionToDiscover) else {
        assertionFailure("should not happen")
        continue
      }

      let oldSectionToDiscover = oldSections[oldSectionIndex]

      /*
       Detect inserted cells in current section normally.
       When detecting updated cells we compare it's index and datas
       using dedicated dataEquals closure assuming closure is provided
       (if not assertion will be fired or error thrown from verification section in the beginning)
       */

      var insertedIndeciesForSection = [IndexPath]()

      let newSectionCellsOnly = newSectionToDiscover.cellsOnly()
      for (newCellIndex, newCell) in newSectionCellsOnly.enumerated() {

        if oldSectionToDiscover.firstCellLike(newCell) == nil {
          insertedIndeciesForSection.append(IndexPath(row: newCellIndex, section: newSectionIndex))
        }
      }

      insertedIndecies.append(contentsOf: insertedIndeciesForSection)
    }

    print("--- is: \(insertedSectionsIndecies), ds: \(deletedSectionsIndecies) us: \(updatedSectionsIndecies), i: \(insertedIndecies), d: \(deletedIndecies), u: \(updatedIndecies)")

    /* No changes, return nil */
    guard insertedSectionsIndecies.count > 0 ||
      deletedSectionsIndecies.count > 0 ||
      updatedSectionsIndecies.count > 0 ||
      insertedIndecies.count > 0 ||
      deletedIndecies.count > 0 ||
      updatedIndecies.count > 0 else {
        return nil
    }

    return CollectionUpdateContext(
      inserted: insertedIndecies,
      deleted: deletedIndecies,
      updated: updatedIndecies,
      insertedSections: IndexSet(insertedSectionsIndecies),
      deletedSections: IndexSet(deletedSectionsIndecies),
      updatedSections: IndexSet(updatedSectionsIndecies)
    )
  }

  // MARK: - Utils

  fileprivate class func areCellableDatasEqual(cell1: Cell<CellState>, cell2: Cell<CellState>) -> Bool {
    return cell1.state == cell2.state
  }
}

// MARK: - Conveniens Extensions

func firstCellLike<
  CellState: Hashable
>(in cells: [Cell<CellState>], _ cell: Cell<CellState>) -> Cell<CellState>? {
  return cells.first { $0.state == cell.state }
}

func containsCell<
  CellState: Hashable
>(in cells: [Cell<CellState>], _ cell: Cell<CellState>) -> Bool {
  return cells.contains { $0.state == cell.state }
}

func firstIndexOfCell<
  CellState: Hashable
>(in cells: [Cell<CellState>], _ cell: Cell<CellState>) -> Array<Cell<CellState>>.Index? {
  return cells.firstIndex { $0.state == cell.state }
}

func firstSectionLike<
  SectionState: Hashable,
  CellState: Hashable
>(in sections: [Section<SectionState, CellState>], _ section: Section<SectionState, CellState>) -> Section<SectionState, CellState>? {
  return sections.first { $0.state  == section.state }
}

func containsSection<
  SectionState: Hashable,
  CellState: Hashable
>(in sections: [Section<SectionState, CellState>], _ section: Section<SectionState, CellState>) -> Bool {
  return sections.contains { $0.state  == section.state }
}

func firstIndexOfSection<
  SectionState: Hashable,
  CellState: Hashable
>(in sections: [Section<SectionState, CellState>],
  _ section: Section<SectionState, CellState>) -> Array<Section<SectionState, CellState>>.Index? {
  return sections.firstIndex { $0.state  == section.state }
}

fileprivate extension Section {

  func cellsOnly() -> [Cell<CellState>] {
    return cells
  }

  func supplyCellsOnly() -> [Cellable] {
    return supplementaryTypes.flatMap { supplementaries(for: $0) }
  }

  func firstCellLike(_ cell: Cell<CellState>) -> Cell<CellState>? {
    return cellsOnly().first { $0.state == cell.state }
  }

  func containsCell(_ cell: Cell<CellState>) -> Bool {
    return cellsOnly().contains { $0.state == cell.state }
  }

  func firstIndexOfCell(_ cell: Cell<CellState>) -> Array<Cell<CellState>>.Index? {
    return cellsOnly().firstIndex { $0.state == cell.state }
  }
}
