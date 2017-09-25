//
//  TimelineLoaderDecoratorSource.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/9/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import RxSwift

// TODO: we can leverage a big part of regular loader
// needs to be fixed
open class TimelineLoaderDecoratorSource<DecoratedSource: ReusableSource>: LoaderReusableSource {

  public typealias Container = DecoratedSource.Container

  public required init() {
    self.source = DecoratedSource()
    internalInit()
  }

  public var containerView: Container? {
    get {
      return source.containerView
    }

    set(newValue) {
      source.containerView = newValue
    }
  }

  public var hostViewController: UIViewController? {
    get {
      return source.hostViewController
    }

    set(newValue) {
      source.hostViewController = newValue
    }
  }

  public var sections: [Sectionable] {
    get {
      return source.sections
    }

    set(newValue) {
      source.sections = newValue
    }
  }

  public func registerCellsForSections() {
    source.registerCellsForSections()
  }

  public var startProgress: ProgressClosure?
  public var stopProgress: ProgressClosure?
  public var updateEmptyView: EmptyViewClosure?
  public var autoupdatePeriod = defaultReloadInterval
  public var loadingBehavior = LoadingBehavior.initial

  public var lastCellDisplayed: VoidClosure?
  public var selectedCell = ""
  public var selectionManagement: SelectionManagement = .none

  public weak var loader: Loader?

  fileprivate var source: DecoratedSource
  fileprivate var loaderDisposeBag: DisposeBag?
  fileprivate var timerDisposeBag: DisposeBag?
  fileprivate var state = LoaderState.notInitiated
  fileprivate var lastRequestedPage = 0

  fileprivate func internalInit() {
    self.source.lastCellDisplayed = { [weak self] in
      self?.lastCellDisplayed?()
      self?.handleLastCellDisplayed()
    }
  }

  public func forceReloadData(keepCurrentDataBeforeUpdate: Bool) {
    load(.force(keepData: keepCurrentDataBeforeUpdate))
  }

  public func pullToRefresh() {
    load(.pullToRefresh)
  }

  public func forceLoadNextPage() {
    load(.page(page: nextPage()))
  }

  public func appear() {
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
      startAutoupdate()
    }
  }

  public func disappear() {
    timerDisposeBag = nil
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
      load(.page(page: nextPage()))
    default:
      dump(state)
      print("Not ready for paging")
    }
  }

  fileprivate func startAutoupdate() {
    let disposeBag = DisposeBag()
    let timerObservable = Observable<Int>.interval(autoupdatePeriod, scheduler: MainScheduler.instance)
    timerObservable.subscribe(onNext: { [weak self] _ in
      self?.load(.autoupdate)
    }).addDisposableTo(disposeBag)
    timerDisposeBag = disposeBag
  }

  fileprivate var cellsCount: Int {
    return sections.reduce(0, {$0 + $1.cells.count})
  }

  fileprivate func needToHandleIntent(intent: LoaderIntent) -> Bool {
    switch state {
    case .loading(let currentIntent):
      if intent == .force(keepData: false) || intent == .pullToRefresh {
        loaderDisposeBag = nil
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
}

extension TimelineLoaderDecoratorSource {

  // swiftlint:disable:next function_body_length cyclomatic_complexity
  fileprivate func load(_ intent: LoaderIntent) {
    if !needToHandleIntent(intent: intent) { return }

    if intent == .force(keepData: false) {
      sections = []
      reloadDataWithEmptyDataSet()
    }

    guard let sectionObservable = loader?.performLoading(intent: intent) else {
      return
    }
    let cellsCountBeforeLoad = cellsCount
    startProgress?(intent)
    state = .loading(intent: intent)
    let loaderDisposeBag = DisposeBag()
    sectionObservable.map({ [weak self] sections -> [Sectionable]? in
      return self?.merge(incomming: sections, for: intent)
    }).observeOn(MainScheduler.instance)
      .subscribe (
        onNext: { [weak self] sections in
          self?.updateSections(newSections: sections)
        }, onError: { [weak self] error in
          guard let strongSelf = self else { return }
          strongSelf.stopProgress?(intent)

          switch intent {
          case .page:
            if strongSelf.cellsCount > 0 {
              strongSelf.state = .hasData
              return
            }
          default:
            ()
          }
          strongSelf.state = .error
          strongSelf.reloadDataWithEmptyDataSet()
        }, onCompleted: { [weak self] in
          guard let strongSelf = self else { return }
          strongSelf.stopProgress?(intent)
          let cellsCountAfterLoad = strongSelf.cellsCount

          switch intent {
          case .page:
            if cellsCountAfterLoad == cellsCountBeforeLoad {
              strongSelf.state = .hasData
              return
            }
          default:
            ()
          }
          if cellsCountAfterLoad == 0 {
            strongSelf.state = .empty
            strongSelf.reloadDataWithEmptyDataSet()
          } else {
            guard let containerView = strongSelf.containerView else { return }

            strongSelf.state = .hasData
            guard let lastSection = strongSelf.sections.last else { return }
            guard let visibleItems = containerView.visibleItems else { return }
            let sectionsLastIndex = strongSelf.sections.count - 1
            let itemsLastIndex = lastSection.cells.count - 1

            if visibleItems.contains(where: { $0.section == sectionsLastIndex && $0.item == itemsLastIndex }) {
              strongSelf.handleLastCellDisplayed()
            }
          }
      }).addDisposableTo(loaderDisposeBag)
    self.loaderDisposeBag = loaderDisposeBag
    updateEmptyView?(state)
  }

  fileprivate func merge(incomming: [Sectionable]?, for intent: LoaderIntent) -> [Sectionable]? {
    #if DEBUG
    check(sections: incomming)
    #endif

    switch intent {
    case .initial, .force, .pullToRefresh:
      if let incomming = incomming?.first {
        return [incomming]
      }
      return nil
    default: break
    }

    guard let sectionToMerge = incomming?.first else { return nil }
    guard let original = sections.first else { return incomming }

    let incommingCells = Set<String>(sectionToMerge.cells.map { $0.id })
    let originalCells = Set<String>(original.cells.map { $0.id })
    var result = incommingCells.union(originalCells)

    let cells: [Cellable]
    switch intent {
    case .page:
      cells = original.cells + sectionToMerge.cells
    default:
      cells = sectionToMerge.cells + original.cells
    }

    let resultCells = cells.flatMap { cell -> Cellable? in
      let id = cell.id
      if result.contains(id) {
        result.remove(id)
        if let incommingCell = sectionToMerge.cells.first(where: { $0.id == id }) {
          return incommingCell
        }
        return cell
      } else {
        return nil
      }
    }

    return [Section(cells: resultCells)]
  }

  fileprivate func check(sections: [Sectionable]?) {
    guard let sections = sections else { return }

    if sections.count > 1 {
      assertionFailure("We can process only one section")
    }

    guard let section = sections.first else { return }
    if section.supplementaryTypes.count > 0 {
      assertionFailure("No supplementary view supported")
    }

    let cells = section.cells.map({ $0.id })
    let ids = Set<String>(cells)

    if cells.count != ids.count {
      assertionFailure("All cells should have unique id")
    }
  }

  fileprivate func updateSections(newSections: [Sectionable]?) {
    switch state {
    case .loading(let intent):
      guard let updatedSections = newSections else {
        return
      }

      switch intent {
      case .initial, .force, .pullToRefresh:
        lastRequestedPage = 0
      case .page(let page):
        lastRequestedPage = page
      default: break
      }

      sections = updatedSections
      registerCellsForSections()
      containerView?.reloadData()
    default:
      assertionFailure("Should not be called in other state than loading")
    }
  }

  fileprivate func nextPage() -> Int {
    return lastRequestedPage + 1
  }
}
