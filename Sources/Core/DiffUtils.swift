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
   - parameters:
   - new: new sections source
   - old: old sections source
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
   - parameters:
   - new: new sections source
   - old: old sections source
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
     Check validity of cells
     - id
     - type
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
      return !oldSections.contains { oldSection in
        return newSection.equals!(oldSection)
      }
    }
    let insertedSectionsIndecies = IndexSet(insertedSections.compactMap { insertedSection in
      return newSections.firstIndex { $0.equals!(insertedSection) }
    })

    /*
     Detect deleted sections
     */
    let deletedSections = oldSections.filter { oldSection in
      return !newSections.contains { newSection in
        return newSection.equals!(oldSection)
      }
    }
    let deletedSectionsIndecies = IndexSet(deletedSections.compactMap { deletedSection in
      return oldSections.firstIndex { $0.equals!(deletedSection) }
    })

    /*
     Detect inserted/deleted/updated cells only in sections
     that are not inserted or deleted which were detected from the above.
     */
    var insertedIndecies = [IndexPath]()
    var deletedIndecies = [IndexPath]()
    var updatedIndecies = [IndexPath]()

    for (newSectionIndex, newSectionToDiscover) in newSections.enumerated() {

      /* skip already inserted or deleted sections */
      if insertedSections.contains(where: { insertedSection in
        return insertedSection.equals!(newSectionToDiscover)
      }) || deletedSections.contains(where: { deletedSection in
        return deletedSection.equals!(newSectionToDiscover)
      }) {
        continue
      }

      guard let oldSectionToDiscover = oldSections.first(where: { oldSection in
        return newSectionToDiscover.equals!(oldSection)
      }) else {
        continue
      }

      /*
       Detect inserted and deleted cells in current section normally.
       When detecting updated cells we compare it's datas
       using dedicated dataEquals closure assuming closure provided
       (if not assertion will be fired or error thrown from verification section in the beginning)
       */

      var insertedIndeciesForSection = [IndexPath]()
      var deletedIndeciesForSection = [IndexPath]()
      var updatedIndeciesForSection = [IndexPath]()

      for (newCellIndex, newCell) in newSectionToDiscover.cellsOnly().enumerated() {

        let indexPath: IndexPath = { IndexPath(row: newCellIndex, section: newSectionIndex) }()

        if let sameOldCell = oldSectionToDiscover.cellsOnly().first(where: { $0.equals!(newCell) }) {
          if !(sameOldCell as! DataHodler<Data>).dataEquals!((sameOldCell as! DataHodler<Data>).data, (newCell as! DataHodler<Data>).data) {
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
      insertedIndecies.count > 0 ||
      deletedIndecies.count > 0 ||
      updatedIndecies.count > 0 else {
        return nil
    }

    return CollectionUpdateContext(
      inserted: insertedIndecies,
      deleted: deletedIndecies,
      updated: updatedIndecies,
      insertedSections: insertedSectionsIndecies,
      deletedSections: deletedSectionsIndecies
    )
  }
}
