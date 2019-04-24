//
//  DiffUtils.swift
//  Astrolabe-iOS
//
//  Created by Alexander Zhigulich on 4/23/19.
//

import Foundation

public struct CollectionUpdateContext {
  public let inserted: [IndexPath]
  public let deleted: [IndexPath]
  public let updated: [IndexPath]
  public let insertedSections: IndexSet
  public let deletedSections: IndexSet
}

public enum DiffError: Error {
  case error(String)
}

open class DiffUtils {

  open class func diff(
    newSections: [Sectionable],
    oldSections: [Sectionable]
  ) -> CollectionUpdateContext? {
    do {
      return try diffThrow(newSections: newSections, oldSections: oldSections)
    } catch DiffError.error(let message) {
      assertionFailure(message)
      return nil
    } catch let error {
      assertionFailure(error.localizedDescription)
      return nil
    }
  }

  open class func diffThrow(
    newSections: [Sectionable],
    oldSections: [Sectionable]
  ) throws -> CollectionUpdateContext? {

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

    if let cell = allSections.compactMap({ $0.cellsOnly() }).reduce([], +).first(where: { $0.id.isEmpty || $0.equals == nil /*|| $0.dataEquals == nil*/ }) {
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

    let insertedSections = newSections.filter { newSection in
      return !oldSections.contains { oldSection in
        return newSection.equals?(oldSection) ?? false
      }
    }
    let insertedSectionsIndecies = IndexSet(insertedSections.compactMap { insertedSection in
      return newSections.firstIndex { $0.equals?(insertedSection) ?? false }
    })

    let deletedSections = oldSections.filter { oldSection in
      return !newSections.contains { newSection in
        return newSection.equals?(oldSection) ?? false
      }
    }
    let deletedSectionsIndecies = IndexSet(deletedSections.compactMap { deletedSection in
      return oldSections.firstIndex { $0.equals?(deletedSection) ?? false }
    })

    var insertedIndecies = [IndexPath]()
    var deletedIndecies = [IndexPath]()
    var updatedIndecies = [IndexPath]()

    for (newSectionIndex, newSectionToDiscover) in newSections.enumerated() {

      if insertedSections.contains(where: { insertedSection in
        return insertedSection.equals?(newSectionToDiscover) ?? false
      }) || deletedSections.contains(where: { deletedSection in
        return deletedSection.equals?(newSectionToDiscover) ?? false
      }) {
        continue
      }

      guard let oldSectionToDiscover = oldSections.first(where: { oldSection in
        return newSectionToDiscover.equals?(oldSection) ?? false
      }) else {
        continue
      }

      var insertedIndeciesForSection = [IndexPath]()
      var deletedIndeciesForSection = [IndexPath]()
      var updatedIndeciesForSection = [IndexPath]()

      for (newCellIndex, newCell) in newSectionToDiscover.cellsOnly().enumerated() {
        if let sameOldCell = oldSectionToDiscover.cellsOnly().first(where: { $0.equals?(newCell) ?? false }) {
          //        if (sameOldCell as! DataHodler).dataEquals?((sameOldCell as! DataHodler).data, (newCell as! DataHodler).data) ?? false {
          //
          //        }
        } else {
          insertedIndeciesForSection.append(IndexPath(row: newCellIndex, section: newSectionIndex))
        }
      }

      for (oldCellIndex, oldCell) in oldSectionToDiscover.cellsOnly().enumerated() {
        if !newSectionToDiscover.cellsOnly().contains(where: { $0.equals?(oldCell) ?? false }) {
          deletedIndeciesForSection.append(IndexPath(row: oldCellIndex, section: newSectionIndex))
        }
      }

      insertedIndecies.append(contentsOf: insertedIndeciesForSection)
      deletedIndecies.append(contentsOf: deletedIndeciesForSection)
      updatedIndecies.append(contentsOf: updatedIndeciesForSection)
    }

    updatedIndecies.append(contentsOf: Array(Set(insertedIndecies).intersection(deletedIndecies)))
    insertedIndecies.removeAll { updatedIndecies.contains($0) }
    deletedIndecies.removeAll { updatedIndecies.contains($0) }

    print("--- is: \(insertedSectionsIndecies.count), ds: \(deletedSectionsIndecies.count), i: \(insertedIndecies.count), d: \(deletedIndecies.count), u: \(updatedIndecies.count)")

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
