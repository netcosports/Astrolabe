//
//  Loader.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/9/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import RxSwift

public typealias SectionObservable = Observable<[Sectionable]?>
public typealias ObservableClosure = () -> SectionObservable?

public enum LoaderState {
  case notInitiated
  case initiated
  case loading(intent: LoaderIntent)
  case hasData
  case error(Error)
  case empty
}

let defaultReloadInterval: TimeInterval = 30
public typealias ProgressClosure = (LoaderIntent) -> Void
public typealias EmptyViewClosure = (LoaderState) -> Void

public enum LoaderIntent {
  case initial
  case appearance
  case force(keepData: Bool)
  case pullToRefresh
  case autoupdate
  case page(page: Int)
}

extension LoaderIntent: Equatable {

}

public protocol Pageable {
  var page: Int { get }
}

extension LoaderIntent: Pageable {
  public var page: Int {
    var page = 0
    switch self {
    case .page(let index):
      page = index
    default:
      break
    }
    return page
  }
}

public func == (lhs: LoaderIntent, rhs: LoaderIntent) -> Bool {
  switch (lhs, rhs) {

  case (.initial, .initial):
    return true

  case (.pullToRefresh, .pullToRefresh):
    return true

  case (.appearance, .appearance):
    return true

  case (.autoupdate, .autoupdate):
    return true

  case (let .force(keepData1), let .force(keepData2)):
    return keepData1 == keepData2

  case (let .page(page1), let .page(page2)):
    return page1 == page2

  default:
    return false
  }
}

public struct LoadingBehavior: OptionSet {
  public let rawValue: Int

  public init(rawValue: Int) { self.rawValue = rawValue }

  public static let initial = LoadingBehavior(rawValue: 1 << 0)
  public static let appearance = LoadingBehavior(rawValue: 1 << 1)
  public static let autoupdate = LoadingBehavior(rawValue: 1 << 2)
  public static let autoupdateBackground = LoadingBehavior(rawValue: 3 << 2)
  public static let paging = LoadingBehavior(rawValue: 1 << 5)
}

public protocol LoaderReusableSource: ReusableSource {
    var startProgress: ProgressClosure? { get set }
    var stopProgress: ProgressClosure? { get set }
    var updateEmptyView: EmptyViewClosure? { get set }
    var autoupdatePeriod: TimeInterval { get set }
    var loadingBehavior: LoadingBehavior { get set }

    func forceReloadData(keepCurrentDataBeforeUpdate: Bool)
    func forceLoadNextPage()
    func pullToRefresh()
    func appear()
    func disappear()
    func cancelLoading()
    func reloadDataWithEmptyDataSet()
}

public protocol Loadable: class {
  associatedtype Item

  func load(for intent: LoaderIntent) -> Observable<[Item]?>?
  func merge(items: [Item]?, for intent: LoaderIntent) -> Observable<[Item]?>?
  func apply(items:[Item]?, for intent: LoaderIntent)
}

public protocol LoaderMediatorProtocol: class {
  func load<T: LoaderReusableSource>(into source: T, for intent: LoaderIntent) -> Observable<Void>
}

public class LoaderMediator<Loader: Loadable>: LoaderMediatorProtocol {

  typealias Item = Loader.Item

  weak var loader: Loader?
  public init(loader: Loader) {
    self.loader = loader
  }

  public func load<T: LoaderReusableSource>(into source: T, for intent: LoaderIntent) -> Observable<Void> {
    guard let observable = loader?.load(for: intent) else { return .empty() }

    return observable.flatMap { [weak self] items -> Observable<[Item]?> in
      guard let merged = self?.loader?.merge(items:items, for: intent) else { return .empty() }
      return merged
    }.observeOn(MainScheduler.instance)
     .do(onNext: { [weak self] mergedItems in
        self?.loader?.apply(items:mergedItems, for: intent)
      }).map({ _ -> Void in () })
  }
}

public extension Loadable where Self: Containerable, Item == Sectionable {

  func merge(items:[Item]?, for intent: LoaderIntent) -> Observable<[Item]?>? {
    guard let updatedSections = items else { return .just(allItems) }
    var merged: [Item] = allItems

    switch intent {
    case .initial, .force, .pullToRefresh:
      allItems = updatedSections
      return .just(updatedSections)
    default:
      // NOTE: the following checking is very important for paging logic,
      // without this logic we will have infinit reloading in case of last page;
      let hasCells = updatedSections.count != 0 &&
        !(updatedSections.count == 1 && updatedSections.first?.cells.count == 0)
      guard hasCells else {
        allItems = updatedSections
        return .just(merged)
      }

      let sectionByPages = Dictionary(grouping: updatedSections, by: { $0.page })
      for sectionsByPage in sectionByPages {
        if let indexToReplace = merged.index(where: { sectionsByPage.key == $0.page }) {
          merged = merged.filter { $0.page != sectionsByPage.key }
          let updatedSectionsForPage = sectionsByPage.value.reversed()
          updatedSectionsForPage.forEach {
            merged.insert($0, at: indexToReplace)
          }
        } else {
          merged.append(contentsOf: sectionsByPage.value)
        }
      }
      merged.stableSort(by: {
        guard $0.page != $1.page else { return nil }
        return $0.page < $1.page
      })
      allItems = merged
      return .just(merged)
    }
  }
}

public extension Loadable where Self: Accessor, Item == Sectionable {

  func apply(items: [Item]?, for intent: LoaderIntent) {
    guard let items = items else { return }
    source.sections = items
    source.registerCellsForSections()
    source.containerView?.reloadData()
  }
}
