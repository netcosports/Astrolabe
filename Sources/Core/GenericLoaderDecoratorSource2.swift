//
//  GenericLoaderDecoratorSource.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 2/4/18.
//  Copyright © 2018 Netcosports. All rights reserved.
//

import UIKit
import RxSwift

public protocol Loadable: class {
  associatedtype Item

  func load(for intent: LoaderIntent) -> Observable<[Item]?>?
  func merge(items:[Item]?, into all:[Item]?, for intent: LoaderIntent) -> [Item]?
  func apply(mergedItems:[Item]?, into currentItems:[Item]?, for intent: LoaderIntent)

  var all: [Item]? { get }
}

public extension Loadable where Self: Accessor, Item == Sectionable {

  func merge(items:[Item]?, into all:[Item]?, for intent: LoaderIntent) -> [Item]? {
    guard let updatedSections = items else { return all }

    var merged: [Item] = []
    if let all = all { merged = all }

    switch intent {
    case .initial, .force, .pullToRefresh:
      return updatedSections
    default:
      // NOTE: the following checking is very important for paging logic,
      // without this logic we will have infinit reloading in case of last page;
      let hasCells = updatedSections.count != 0 &&
        !(updatedSections.count == 1 && updatedSections.first?.cells.count == 0)
      guard hasCells else { return merged }

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
      return merged
    }
  }

  func apply(mergedItems:[Item]?, into currentItems:[Item]?, for intent: LoaderIntent) {
    guard let mergedItems = mergedItems else { return }
    source.sections = mergedItems
    source.registerCellsForSections()
    source.containerView?.reloadData()
  }

  var all: [Item]? {
    return sections
  }
}

protocol Loader2 {
  func loader<T: Loadable>() -> T
}

open class GenericLoaderDecoratorSource2<DecoratedSource: ReusableSource, Loader: Loadable>: LoaderReusableSource {

  public typealias Container = DecoratedSource.Container
  public typealias Item = Loader.Item

  public required init() {
    internalInit()
  }
  public var containerView: Container? {
    get { return source.containerView }
    set { source.containerView = newValue }
  }
  public var hostViewController: UIViewController? {
    get { return source.hostViewController }
    set { source.hostViewController = newValue }
  }
  public var sections: [Sectionable] {
    get { return source.sections }
    set { source.sections = newValue }
  }
  public var selectedCellIds: Set<String> {
    get { return source.selectedCellIds }
    set { source.selectedCellIds = newValue }
  }
  public var selectionBehavior: SelectionBehavior {
    get { return source.selectionBehavior }
    set { source.selectionBehavior = newValue }
  }
  public var selectionManagement: SelectionManagement {
    get { return source.selectionManagement }
    set { source.selectionManagement = newValue }
  }

  public func registerCellsForSections() {
    source.registerCellsForSections()
  }

  public var startProgress: ProgressClosure?
  public var stopProgress: ProgressClosure?
  public var updateEmptyView: EmptyViewClosure?
  public var autoupdatePeriod = defaultReloadInterval
  public var loadingBehavior = LoadingBehavior.initial {
    didSet {
      if loadingBehavior.contains(.autoupdate) {
        switch state {
        case .notInitiated: break
        default: startAutoupdateIfNeeded()
        }
      } else {
        timerDisposeBag = nil
      }
    }
  }
  public var lastCellDisplayed: VoidClosure?

  public let source = DecoratedSource()
  fileprivate var loaderDisposeBag: DisposeBag?
  fileprivate var timerDisposeBag: DisposeBag?
  fileprivate var state = LoaderState.notInitiated
  public var loader: Loader?

  fileprivate func internalInit() {
    self.source.lastCellDisplayed = { [weak self] in
      self?.lastCellDisplayed?()
      self?.handleLastCellDisplayed()
    }
  }

  public func forceReloadData(keepCurrentDataBeforeUpdate: Bool) {
    load(.force(keepData: keepCurrentDataBeforeUpdate))
  }

  public func forceLoadNextPage() {
    load(.page(page: nextPage))
  }

  public func pullToRefresh() {
    load(.pullToRefresh)
  }

  open func appear() {
    switch state {
    case .notInitiated:
      state = .initiated
      load(.initial)
    default:
      if loadingBehavior.contains(.appearance) {
        load(.appearance)
      }
    }

    if loadingBehavior.contains(.autoupdate) {
      startAutoupdateIfNeeded()
    }
  }

  open func disappear() {
    if !loadingBehavior.contains(.autoupdateBackground) {
      timerDisposeBag = nil
    }
  }

  open func cancelLoading() {
    loaderDisposeBag = nil
    state = .initiated
  }

  public func reloadDataWithEmptyDataSet() {
    containerView?.reloadData()
    updateEmptyView?(state)
  }

  fileprivate func handleLastCellDisplayed() {
    if !loadingBehavior.contains(.paging) {
      return
    }

    switch state {
    case .hasData:
      load(.page(page: nextPage))
    default:
      dump(state)
      print("Not ready for paging")
    }
  }

  fileprivate func startAutoupdateIfNeeded() {
    guard timerDisposeBag == nil else { return }
    let disposeBag = DisposeBag()
    Observable<Int>.interval(autoupdatePeriod, scheduler: MainScheduler.instance).subscribe(onNext: { [weak self] _ in
      self?.load(.autoupdate)
    }).disposed(by: disposeBag)
    timerDisposeBag = disposeBag
  }

  fileprivate func needToHandleIntent(intent: LoaderIntent) -> Bool {
    switch state {
    case .loading(let currentIntent):
      if intent == .force(keepData: false) || intent == .pullToRefresh {
        cancelLoading()
        return true
      } else if currentIntent == intent {
        return false
      } else {
        switch (intent, currentIntent) {
        case (.page, .page): return false
        default: return true
        }
      }
    default:
      return true
    }
  }

  // swiftlint:disable function_body_length
  // swiftlint:disable:next cyclomatic_complexity
  fileprivate func load(_ intent: LoaderIntent) {
    guard DispatchQueue.isMain else {
      return DispatchQueue.main.async {
        self.load(intent)
      }
    }

    guard needToHandleIntent(intent: intent) else { return }

    if intent == .force(keepData: false) {
      sections = []
      reloadDataWithEmptyDataSet()
    }
    guard let observable = loader?.load(for: intent) else { return }
    let all = loader?.all
    let cellsCountBeforeLoad = cellsCount
    startProgress?(intent)
    state = .loading(intent: intent)
    let loaderDisposeBag = DisposeBag()
    self.loaderDisposeBag = loaderDisposeBag
    observable
      .map { [weak self] items -> [Item]? in
        guard let `self` = self else { return nil }
        switch self.state {
        case .loading:
          return self.loader?.merge(items:items, into: all, for: intent)
        default: assertionFailure("Should not be called in other state than loading")
        }
        return nil
      }
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] mergedItems in
        guard let `self` = self else { return }
        switch self.state {
        case .loading:
          self.loader?.apply(mergedItems:mergedItems, into:all, for: intent)
        default: assertionFailure("Should not be called in other state than loading")
        }
      }, onError: { [weak self] error in
        guard let `self` = self else { return }
        self.state = self.cellsCount > 0 ? .hasData : .error(error)
        self.reloadDataWithEmptyDataSet()
      }, onCompleted: { [weak self] in
        guard let `self` = self else { return }
        let cellsCountAfterLoad = self.cellsCount

        switch intent {
        case .page:
          if cellsCountAfterLoad == cellsCountBeforeLoad {
            self.state = .hasData
            return
          }
        default: break
        }
        guard let containerView = self.containerView else { return }
        if cellsCountAfterLoad == 0 {
          self.state = .empty
          self.reloadDataWithEmptyDataSet()
        } else {
          self.state = .hasData
          guard let lastSection = self.sections.last else { return }
          guard let visibleItems = containerView.visibleItems else { return }
          let sectionsLastIndex = self.sections.count - 1
          let itemsLastIndex = lastSection.cells.count - 1

          if visibleItems.contains(where: { $0.section == sectionsLastIndex && $0.item == itemsLastIndex }) {
            self.handleLastCellDisplayed()
          }
        }
      }, onDisposed: { [weak self] in
        self?.stopProgress?(intent)
      }).disposed(by: loaderDisposeBag)

    updateEmptyView?(state)
  }

  fileprivate var cellsCount: Int {
    return sections.reduce(0, { $0 + $1.cells.count })
  }

  fileprivate var nextPage: Int {
    let maxPage = sections.map({ $0.page }).max()
    return (maxPage ?? 0) + 1
  }
}
