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

public typealias CellObservable = Observable<[Cellable]?>
public typealias CellObservableClosure = () -> CellObservable?

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
public typealias NoDataStateClosure = (LoaderState) -> [Sectionable]

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
  @available(*, deprecated, message: "Use noDataCell closure")
  var updateEmptyView: EmptyViewClosure? { get set }
  var noDataState: NoDataStateClosure? { get set }
  var autoupdatePeriod: TimeInterval { get set }
  var loadingBehavior: LoadingBehavior { get set }
  var loader: LoaderMediatorProtocol? { get set }

  func forceReloadData(keepCurrentDataBeforeUpdate: Bool)
  func forceLoadNextPage()
  func pullToRefresh()
  func appear()
  func disappear()
  func cancelLoading()
  func reloadDataWithEmptyDataSet()
}

public enum MergeStatus {
  case hasUpdates
  case equalWithCurrent
}

public protocol Loadable: class {

  associatedtype Item

  typealias MergeResult = (items: [Item]?, status: MergeStatus)

  func load(for intent: LoaderIntent) -> Observable<[Item]?>?
  func merge(items: [Item]?, for intent: LoaderIntent) -> Observable<MergeResult?>?
  func apply(mergeResult: MergeResult?, for intent: LoaderIntent)
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

    return observable.flatMap { [weak self] items -> Observable<Loader.MergeResult?> in
      guard let merged = self?.loader?.merge(items: items, for: intent) else { return .empty() }
      return merged
    }.observeOn(MainScheduler.instance)
     .do(onNext: { [weak self] mergeResult in
        self?.loader?.apply(mergeResult: mergeResult, for: intent)
      }).map { _ in () }
  }
}

extension Array where Element == Sectionable {

  public mutating func merge(items: [Sectionable]?, for intent: LoaderIntent) -> (items: [Sectionable]?, status: MergeStatus)? {
    guard let updatedSections = items else {
      return (items: self, status: .equalWithCurrent)
    }
    var merged: [Sectionable] = self

    switch intent {
    case .initial, .force, .pullToRefresh:
      self.removeAll()
      self.append(contentsOf: updatedSections)
      return (items: updatedSections, status: .hasUpdates)
    default:
      // NOTE: the following checking is very important for paging logic,
      // without this logic we will have infinite reloading in case of last page;
      let hasCells = updatedSections.count != 0 &&
        !(updatedSections.count == 1 && updatedSections.first?.cells.count == 0)
      guard hasCells else {
        self.removeAll()
        self.append(contentsOf: merged)
        return (items: merged, status: .equalWithCurrent)
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
      self.removeAll()
      self.append(contentsOf: merged)
      return (items: merged, status: .hasUpdates)
    }
  }
}

public extension Loadable where Self: Containerable, Item == Sectionable {

  func merge(items: [Item]?, for intent: LoaderIntent) -> Observable<MergeResult?>? {
    return .just(allItems.merge(items: items, for: intent))
  }
}

public extension Loadable where Self: Accessor, Item == Sectionable {

  func apply(mergeResult: MergeResult?, for intent: LoaderIntent) {
    guard let mergeResult = mergeResult else { return }
    guard mergeResult.status != .equalWithCurrent else { return }
    guard let items = mergeResult.items else { return }
    source.sections = items
    source.registerCellsForSections()
    source.containerView?.reloadData()
  }

}
