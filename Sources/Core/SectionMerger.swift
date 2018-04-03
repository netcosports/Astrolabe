//
//  SectionMerger.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 3/11/18.
//

import UIKit
import RxSwift

extension Array {

  public mutating func stableSort(by areInIncreasingOrder: (Iterator.Element, Iterator.Element) -> Bool?) {

    let sorted = self.enumerated().sorted { (one, another) -> Bool in
      if let result = areInIncreasingOrder(one.element, another.element) {
        return result
      } else {
        return one.offset < another.offset
      }
    }
    self = sorted.map{ $0.element }
  }
}

public typealias SectionObservable = Observable<[Sectionable]?>
public typealias ObservableClosure = () -> SectionObservable?
public protocol Loader: class {
  func performLoading(intent: LoaderIntent) -> SectionObservable?
}

public class SectionMerger: Mergeable {
  public required init() {}

  public typealias Item = Sectionable
  public weak var loader: Loader?
  public func loadItems(for intent: LoaderIntent) -> Observable<[Sectionable]?>? {
    return loader?.performLoading(intent: intent)
  }

  public func merge<Source: ReusableSource>(newItems: [Sectionable]?, into source: Source, for intent: LoaderIntent) {
    guard let updatedSections = newItems else {
      return
    }

    switch intent {
    case .initial, .force, .pullToRefresh:
      source.sections = updatedSections
    default:
      // NOTE: the following checking is very important for paging logic,
      // without this logic we will have infinit reloading in case of last page;
      let hasCells = updatedSections.count != 0 &&
        !(updatedSections.count == 1 && updatedSections.first?.cells.count == 0)
      guard hasCells else { return }

      let sectionByPages = Dictionary(grouping: updatedSections, by: { $0.page })
      for sectionsByPage in sectionByPages {
        if let indexToReplace = source.sections.index(where: { sectionsByPage.key == $0.page }) {
          source.sections = source.sections.filter { $0.page != sectionsByPage.key }
          let updatedSectionsForPage = sectionsByPage.value.reversed()
          updatedSectionsForPage.forEach {
            source.sections.insert($0, at: indexToReplace)
          }
        } else {
          source.sections.append(contentsOf: sectionsByPage.value)
        }
      }
      source.sections.stableSort(by: {
        guard $0.page != $1.page else { return nil }
        return $0.page < $1.page
      })
      source.registerCellsForSections()
    }
    source.containerView?.reloadData()
  }
}

public class LoaderDecoratorSource<DecoratedSource: ReusableSource>: GenericLoaderDecoratorSource<DecoratedSource, SectionMerger> {

  public weak var loader: Loader? {
    set(newValue) {
      merger.loader = newValue
    }

    get {
      return merger.loader
    }
  }
}
