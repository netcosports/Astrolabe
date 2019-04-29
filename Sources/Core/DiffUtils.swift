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
}

/** Error to throw */
public enum DiffError: Error {
  case error(String)
}

/** Utility class to manage differences between new and old sources */
open class DiffUtils<Data> {

  /**
   Calculate difference safely.
   If no difference found nil returned.
   If data inconsistent no error thrown but nil returned and assertion fired into DEBUG
   - parameter newSections: new sections source
   - parameter oldSections: old sections source
   - returns: CollectionUpdateContext instance or nil
   */
  open class func diff(
    new newSections: [Sectionable],
    old oldSections: [Sectionable]
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
    new newSections: [Sectionable],
    old oldSections: [Sectionable]
    ) throws -> CollectionUpdateContext? {

    /*
     Check validity of sections.
     - id
     - equals closure
     */
    let allSections = newSections + oldSections
    if let section = allSections.first(where: { $0.id.isEmpty || $0.equals == nil }) {
      throw DiffError.error("Check section id, equals closure: \(section)")
    }
    if Set(newSections.map({ $0.id })).count != newSections.count {
      throw DiffError.error("Check new section ids: collision detected")
    }
    if Set(oldSections.map({ $0.id })).count != oldSections.count {
      throw DiffError.error("Check old section ids: collision detected")
    }

    /*
     Check validity of section suppelementary cells.
     - id
     - equals closure
     - data equals closure
     */
    let allSupplyCellsOnly = allSections.compactMap({ $0.supplyCellsOnly() }).reduce([], +)
    if let cell = allSupplyCellsOnly.first(where: { $0.id.isEmpty || $0.equals == nil || ($0 as! DataHodler<Data>).dataEquals == nil }) {
      throw DiffError.error("Check supplementary cell id, equals closure, data equals closure: \(cell)")
    }
    try newSections.forEach { section in
      let supplyCellsOnly = section.supplyCellsOnly()
      if Set(supplyCellsOnly.map({ $0.id })).count != supplyCellsOnly.count {
        throw DiffError.error("Check supplementary cell ids: collision detected for new section \(section)")
      }
    }
    try oldSections.forEach { section in
      let supplyCellsOnly = section.supplyCellsOnly()
      if Set(supplyCellsOnly.map({ $0.id })).count != supplyCellsOnly.count {
        throw DiffError.error("Check supplementary cell ids: collision detected for old section \(section)")
      }
    }

    /*
     Check validity of cells
     - id
     - equals closure
     - data equals closure
     */
    let allCellsOnly = allSections.compactMap({ $0.cellsOnly() }).reduce([], +)
    if let cell = allCellsOnly.first(where: { $0.id.isEmpty || $0.equals == nil || ($0 as! DataHodler<Data>).dataEquals == nil }) {
      throw DiffError.error("Check cell id, equals closure, data equals closure: \(cell)")
    }
    try newSections.forEach { section in
      let cellsOnly = section.cellsOnly()
      if Set(cellsOnly.map({ $0.id })).count != cellsOnly.count {
        throw DiffError.error("Check cell ids: collision detected for new section \(section)")
      }
    }
    try oldSections.forEach { section in
      let cellsOnly = section.cellsOnly()
      if Set(cellsOnly.map({ $0.id })).count != cellsOnly.count {
        throw DiffError.error("Check cell ids: collision detected for old section \(section)")
      }
    }

    /*
     Detect inserted sections
     */
    let insertedSections = newSections.filter { newSection in
      return !oldSections.contains { newSection.equals!($0) }
    }
    var insertedSectionsIndecies = insertedSections.compactMap { insertedSection in
      return newSections.firstIndex { $0.equals!(insertedSection) }
    }

    /*
     Detect deleted sections
     */
    let deletedSections = oldSections.filter { oldSection in
      return !newSections.contains { $0.equals!(oldSection) }
    }
    var deletedSectionsIndecies = deletedSections.compactMap { deletedSection in
      return oldSections.firstIndex { $0.equals!(deletedSection) }
    }

    /*
     Detect updated sections.
     By checking index changes.
     By bypassing it's supplementary items and checking it's equals and dataEquals closures.
     */
    var updatedSectionsIndecies = [Int]()
    for (newSectionIndex, newSectionToDiscover) in newSections.enumerated() {

      /* Skip already inserted or deleted sections */
      if insertedSectionsIndecies.contains(newSectionIndex) ||
        deletedSectionsIndecies.contains(newSectionIndex) {
        continue
      }

      guard let oldSectionToDiscover = oldSections.first(where: { newSectionToDiscover.equals!($0) }) else {
        continue
      }

      /* Check if section moved */
      if let sameOldSectionIndex = oldSections.firstIndex(where: { $0.equals!(newSectionToDiscover) }),
        newSectionIndex != sameOldSectionIndex {
        updatedSectionsIndecies.append(newSectionIndex)
        continue
      }

      /*
       If at least one supplementary item has been changed, mark all section as reloaded
       Note: all cells in this section will also be re-requested from appropriate delegate
       */
      var updated = false
      let newSupplyCells = newSectionToDiscover.supplyCellsOnly()
      let oldSupplyCells = oldSectionToDiscover.supplyCellsOnly()
      if newSupplyCells.count == oldSupplyCells.count {
        for (index, newSupplyCell) in newSupplyCells.enumerated() {
          let oldSupplyCell = oldSupplyCells[index]
          if !newSupplyCell.equals!(oldSupplyCell) ||
            !(newSupplyCell as! DataHodler<Data>).dataEquals!((oldSupplyCell as! DataHodler<Data>).data, (newSupplyCell as! DataHodler<Data>).data) {
            updated = true
            break
          }
        }
      } else {
        updated = true
      }
      if updated {
        updatedSectionsIndecies.append(newSectionIndex)
      }
    }
    /* Make sure the same index not contained in inserted and deleted indecies */
    updatedSectionsIndecies.append(contentsOf: Set(insertedSectionsIndecies).intersection(deletedSectionsIndecies))
    insertedSectionsIndecies.removeAll { updatedSectionsIndecies.contains($0) }
    deletedSectionsIndecies.removeAll { updatedSectionsIndecies.contains($0) }

    /*
     Detect inserted/deleted/updated cells only in sections
     that are not inserted, deleted or updated which were detected from the above.
     */
    var insertedIndecies = [IndexPath]()
    var deletedIndecies = [IndexPath]()
    var updatedIndecies = [IndexPath]()

    for (newSectionIndex, newSectionToDiscover) in newSections.enumerated() {

      /* Skip already inserted, deleted and updated sections */
      if insertedSectionsIndecies.contains(newSectionIndex) ||
        deletedSectionsIndecies.contains(newSectionIndex) ||
        updatedSectionsIndecies.contains(newSectionIndex) {
        continue
      }

      guard let oldSectionToDiscover = oldSections.first(where: { newSectionToDiscover.equals!($0) }) else {
        continue
      }

      /*
       Detect inserted and deleted cells in current section normally.
       When detecting updated cells we compare it's index and datas
       using dedicated dataEquals closure assuming closure is provided
       (if not assertion will be fired or error thrown from verification section in the beginning)
       */

      var insertedIndeciesForSection = [IndexPath]()
      var deletedIndeciesForSection = [IndexPath]()
      var updatedIndeciesForSection = [IndexPath]()

      let newSectionCellsOnly = newSectionToDiscover.cellsOnly()
      for (newCellIndex, newCell) in newSectionCellsOnly.enumerated() {

        let indexPath: IndexPath = { IndexPath(row: newCellIndex, section: newSectionIndex) }()

        if let sameOldCell = oldSectionToDiscover.cellsOnly().first(where: { $0.equals!(newCell) }) {
          /* Check if cell moved otherwise compare datas */
          if let sameOldCellIndex = oldSectionToDiscover.cellsOnly().firstIndex(where: { $0.equals!(newCell) }),
            newCellIndex != sameOldCellIndex ||
            !(sameOldCell as! DataHodler<Data>).dataEquals!((sameOldCell as! DataHodler<Data>).data, (newCell as! DataHodler<Data>).data) {
            updatedIndeciesForSection.append(indexPath)
          }
        } else {
          insertedIndeciesForSection.append(indexPath)
        }
      }

      for (oldCellIndex, oldCell) in oldSectionToDiscover.cellsOnly().enumerated() {
        if !newSectionToDiscover.cellsOnly().contains(where: { $0.equals!(oldCell) }) {
          deletedIndeciesForSection.append(IndexPath(row: oldCellIndex, section: newSectionIndex))
        }
      }

      insertedIndecies.append(contentsOf: insertedIndeciesForSection)
      deletedIndecies.append(contentsOf: deletedIndeciesForSection)
      updatedIndecies.append(contentsOf: updatedIndeciesForSection)
    }

    /* Make sure the same index path not contained in inserted and deleted index paths */
    updatedIndecies.append(contentsOf: Array(Set(insertedIndecies).intersection(deletedIndecies)))
    insertedIndecies.removeAll { updatedIndecies.contains($0) }
    deletedIndecies.removeAll { updatedIndecies.contains($0) }

    print("--- is: \(insertedSectionsIndecies.count), ds: \(deletedSectionsIndecies.count), i: \(insertedIndecies.count), d: \(deletedIndecies.count), u: \(updatedIndecies.count)")

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
}

extension Sectionable {

  func cellsOnly() -> [Cellable] {
    return cells.filter { $0.type == .cell }
  }

  func supplyCellsOnly() -> [Cellable] {
    return supplementaryTypes.compactMap { supplementary(for: $0) }
  }
}
