//
//  DiffUtils.swift
//  Astrolabe-iOS
//
//  Created by Alexander Zhigulich on 4/23/19.
//

import Foundation

public struct CollectionUpdateContext {
  let inserted: [IndexPath]
  let deleted: [IndexPath]
  let updated: [IndexPath]
  let insertedSections: IndexSet
  let deletedSections: IndexSet
}

open class DiffUtils {

  open class func diff(
    newSections: [Sectionable],
    oldSections: [Sectionable]
  ) -> CollectionUpdateContext? {
    // assert ids and equals closures
    // exclude CellType header and footer

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

      for (newCellIndex, newCell) in newSectionToDiscover.cells.enumerated() {
        if let sameOldCell = oldSectionToDiscover.cells.first(where: { $0.equals?(newCell) ?? false }) {
          //        if (sameOldCell as! DataHodler).dataEquals?((sameOldCell as! DataHodler).data, (newCell as! DataHodler).data) ?? false {
          //
          //        }
        } else {
          insertedIndeciesForSection.append(IndexPath(row: newCellIndex, section: newSectionIndex))
        }
      }

      for (oldCellIndex, oldCell) in oldSectionToDiscover.cells.enumerated() {
        if !newSectionToDiscover.cells.contains(where: { $0.equals?(oldCell) ?? false }) {
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

    guard insertedSectionsIndecies.count > 0,
      deletedSectionsIndecies.count > 0,
      insertedIndecies.count > 0,
      deletedIndecies.count > 0,
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
