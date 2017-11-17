//
//  LoaderDecoratorSource.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/6/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import RxSwift

open class LoaderDecoratorSource<DecoratedSource: ReusableSource>: LoaderReusableSource {

  public typealias Container = DecoratedSource.Container

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
  public var loadingBehavior = LoadingBehavior.initial
  public var lastCellDisplayed: VoidClosure?

  public let source = DecoratedSource()
  fileprivate var loaderDisposeBag: DisposeBag?
  fileprivate var timerDisposeBag: DisposeBag?
  fileprivate var state = LoaderState.notInitiated

  public weak var loader: Loader?

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
    load(.page(page: nextPage()))
  }

  public func pullToRefresh() {
    load(.pullToRefresh)
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
      startAutoupdateIfNeeded()
    }
  }

  public func disappear() {
    if !loadingBehavior.contains(.autoupdateBackground) {
      timerDisposeBag = nil
    }
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

  // swiftlint:disable function_body_length
  // swiftlint:disable:next cyclomatic_complexity
  fileprivate func load(_ intent: LoaderIntent) {
    guard DispatchQueue.isMain else {
      return DispatchQueue.main.async {
        self.load(intent)
      }
    }

    if !needToHandleIntent(intent: intent) {
      return
    }

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
    sectionObservable.observeOn(MainScheduler.instance)
      .subscribe(
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
        strongSelf.state = .error(error)
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
        guard let containerView = strongSelf.containerView else { return }
        if cellsCountAfterLoad == 0 {
          strongSelf.state = .empty
          strongSelf.reloadDataWithEmptyDataSet()
        } else {
          strongSelf.state = .hasData
          guard let lastSection = strongSelf.sections.last else { return }
          guard let visibleItems = containerView.visibleItems else { return }
          let sectionsLastIndex = strongSelf.sections.count - 1
          let itemsLastIndex = lastSection.cells.count - 1

          if visibleItems.contains(where: { $0.section == sectionsLastIndex && $0.item == itemsLastIndex }) {
            strongSelf.handleLastCellDisplayed()
          }
        }
      }).disposed(by: loaderDisposeBag)

    self.loaderDisposeBag = loaderDisposeBag
    updateEmptyView?(state)
  }

  // swiftlint:enable function_body_length

  fileprivate var cellsCount: Int {
    return sections.reduce(0, { $0 + $1.cells.count })
  }

  fileprivate func updateSections(newSections: [Sectionable]?) {
    switch state {
    case .loading(let intent):
      guard let updatedSections = newSections else {
        return
      }

      switch intent {
      case .initial, .force, .pullToRefresh:
        sections = updatedSections
      default:
        // NOTE: the following checking is very important for paging logic,
        // without this logic we will have infinit reloading in case of last page;
        if updatedSections.count == 0 {
          return
        }
        if updatedSections.count == 1 && updatedSections.first?.cells.count == 0 {
          return
        }
        for updatedSection in updatedSections {
          let index = sections.index { section in
            return updatedSection.page == section.page
          }
          if let indexToReplace = index {
            sections[indexToReplace] = updatedSection
          } else {
            sections.append(updatedSection)
          }
        }
        registerCellsForSections()
      }
      containerView?.reloadData()
    default:
      assertionFailure("Should not be called in other state than loading")
    }
  }

  fileprivate func nextPage() -> Int {
    let maxPage = sections.map({ $0.page }).max()
    return (maxPage ?? 0) + 1
  }
}
