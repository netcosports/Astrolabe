//
//  EventDrivenLoaderDecoratordecoratedSource.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 2/4/18.
//  Copyright © 2018 Netcosports. All rights reserved.
//

import UIKit
import RxSwift

public enum InputControlEvent: Equatable {
  case force(keepCurrentDataBeforeUpdate: Bool)
  case forceNextPage
  case pullToRefresh
  case visibilityChanged(visible: Bool)
}

public enum LoaderResultEvent {
  case force(sections: [Sectionable], context: CollectionUpdateContext?)
  case soft(sections: [Sectionable], context: CollectionUpdateContext?)
  case failed(error: Error)
  case softCurrent
  case completed(intent: LoaderIntent)
}

public struct Settings {
  public var autoupdatePeriod: TimeInterval
  public var loadingBehavior: LoadingBehavior

  public init(autoupdatePeriod: TimeInterval = 30.0,
              loadingBehavior: LoadingBehavior = .initial) {
    self.autoupdatePeriod = autoupdatePeriod
    self.loadingBehavior = loadingBehavior
  }
}

public protocol EventDrivenLoaderSource: class {
  var settings: Settings { get set }

  var stateObservable: Observable<LoaderState> { get }
  var intentObservable: Observable<LoaderIntent> { get }
  var sectionsObservable: Observable<[Sectionable]> { get }

  var controlObserver: AnyObserver<InputControlEvent> { get }
  var sectionsObserver: AnyObserver<LoaderResultEvent> { get }
}

open class EventDrivenLoaderDecoratorSource<DecoratedSource: ReusableSource>: ReusableSource, EventDrivenLoaderSource {


  public typealias Container = DecoratedSource.Container

  public required init() {
    internalInit()
  }
  public var containerView: Container? {
    get { return decoratedSource.containerView }
    set { decoratedSource.containerView = newValue }
  }
  public var hostViewController: UIViewController? {
    get { return decoratedSource.hostViewController }
    set { decoratedSource.hostViewController = newValue }
  }
  public var sections: [Sectionable] {
    get { return decoratedSource.sections }
    set {
      decoratedSource.sections = newValue
      sectionsSubject.on(.next(sections))
      //print("---! newValue: \(unsafeBitCast(newValue, to: Int.self))")
    }
  }
  public var selectedCellIds: Set<String> {
    get { return decoratedSource.selectedCellIds }
    set { decoratedSource.selectedCellIds = newValue }
  }
  public var selectionBehavior: SelectionBehavior {
    get { return decoratedSource.selectionBehavior }
    set { decoratedSource.selectionBehavior = newValue }
  }
  public var selectionManagement: SelectionManagement {
    get { return decoratedSource.selectionManagement }
    set { decoratedSource.selectionManagement = newValue }
  }
  public func registerCellsForSections() {
    decoratedSource.registerCellsForSections()
  }
  public var lastCellDisplayed: VoidClosure?
  public var lastCellСondition: LastCellConditionClosure?
  public let decoratedSource = DecoratedSource()

  public var settings = Settings() {
    didSet {
      if settings.loadingBehavior.contains(.autoupdate) {
        switch self.state  {
        case .notInitiated: break
        default: startAutoupdateIfNeeded()
        }
      } else {
        timerDisposeBag = nil
      }
    }
  }
  public var controlObserver: AnyObserver<InputControlEvent> {
    return controlEventSubject.asObserver()
  }

  public var stateObservable: Observable<LoaderState> {
    return stateEventSubject.asObservable()
  }

  public var sectionsObservable: Observable<[Sectionable]> {
    return sectionsSubject.asObservable()
  }

  public var sectionsObserver: AnyObserver<LoaderResultEvent> {
    return sectionsEventSubject.asObserver()
  }

  public var intentObservable: Observable<LoaderIntent> {
    return intentSubject.asObservable().filter { [weak self] intent in
      guard let self = self else { return false }
      return self.needToHandle(intent: intent)
    }.do(onNext: { [weak self] intent in
      guard let self = self else { return }
      self.stateEventSubject.onNext(.loading(intent: intent))
      self.cellsCountBeforeLoad = self.cellsCount
    })
  }

  public var scheduler: SchedulerType = MainScheduler.instance {
    didSet {
      bind()
    }
  }

  fileprivate let controlEventSubject = PublishSubject<InputControlEvent>()
  fileprivate let stateEventSubject = BehaviorSubject<LoaderState>(value: .notInitiated)
  fileprivate let sectionsEventSubject = PublishSubject<LoaderResultEvent>()
  fileprivate let sectionsSubject = PublishSubject<[Sectionable]>()
  fileprivate let intentSubject = PublishSubject<LoaderIntent>()
  fileprivate let softReloadSubject = PublishSubject<[Sectionable]>()

  fileprivate var bindDisposeBag = DisposeBag()
  fileprivate var softReloadDisposeBag: DisposeBag?
  fileprivate var softCurrentReloadDisposeBag: DisposeBag?
  fileprivate var timerDisposeBag: DisposeBag?
  #warning("not sure we still need this with event based way")
  fileprivate var cellsCountBeforeLoad: Int = 0

  fileprivate var state: LoaderState {
    return (try? stateEventSubject.value()) ?? .notInitiated
  }

  fileprivate func bind() {
    let bindDisposeBag = DisposeBag()
    controlEventSubject.asObservable()
      .observeOn(scheduler)
      .subscribe(onNext: { [weak self] controlEvent in
        guard let self = self else { return }
        switch controlEvent {
        case .pullToRefresh:
          self.intentSubject.onNext(LoaderIntent.pullToRefresh)
        case .force(let keepCurrentDataBeforeUpdate):
          if !keepCurrentDataBeforeUpdate {
            self.sections = []
            self.containerView?.reloadData()
          }
          self.intentSubject.onNext(LoaderIntent.force(keepData: keepCurrentDataBeforeUpdate))
        case .visibilityChanged(let visible):
          if visible {
            self.appear()
          } else {
            self.disappear()
          }
        case .forceNextPage:
          self.handleLastCellDisplayed()
        }
      }).disposed(by: bindDisposeBag)

    sectionsEventSubject.asObservable()
      .observeOn(scheduler)
      .subscribe(onNext: { [weak self] reloadType in
        guard let self = self else { return }
        guard let containerView = self.containerView else { return }

        switch reloadType {
        case .force(let sections, let context):
          print("--- force: \(sections.count), \(context == nil ? "without" : "with") context")
          self.sections = sections
          self.reloadDataWithContext(context)
          self.unsubscribeSoftReload()
        case .soft(let sections, let context):
          print("--- soft: \(sections.count), \(context == nil ? "without" : "with") context")
          self.softReloadDisposeBag = self.startListenToDataSoftly { [weak self] in
            guard let self = self else { return }
            self.sections = sections
            self.reloadDataWithContext(context)
          }
        case .softCurrent:
          print("--- softCurrent")
          self.softCurrentReloadDisposeBag = self.startListenToDataSoftly { [weak self] in
            guard let self = self else { return }
            self.reloadDataWithContext(nil)
          }
        case .completed(let intent):
          print("--- completed \(intent.page)")
          let cellsCountAfterLoad = self.cellsCount
          if case .page = intent, cellsCountAfterLoad == self.cellsCountBeforeLoad {
            self.stateEventSubject.onNext(.hasData)
            return
          }
          if cellsCountAfterLoad == 0 {
            self.stateEventSubject.onNext(.empty)
            self.containerView?.reloadData()
          } else {
            self.stateEventSubject.onNext(.hasData)
            guard let lastSection = self.sections.last else { return }
            guard let visibleItems = containerView.visibleItems else { return }
            let sectionsLastIndex = self.sections.count - 1
            let itemsLastIndex = lastSection.cells.count - 1

            if visibleItems.contains(where: { $0.section == sectionsLastIndex && $0.item == itemsLastIndex }) {
              self.handleLastCellDisplayed()
            }
          }
        case .failed(let error):
          if self.cellsCount > 0 {
            self.stateEventSubject.onNext(.hasData)
          } else {
            self.stateEventSubject.onNext(.error(error))
            self.containerView?.reloadData()
          }
        }
      }).disposed(by: bindDisposeBag)
    self.bindDisposeBag = bindDisposeBag
  }

  fileprivate func internalInit() {
    self.decoratedSource.lastCellDisplayed = { [weak self] in
      self?.lastCellDisplayed?()
      self?.handleLastCellDisplayed()
    }
    self.decoratedSource.lastCellСondition = { [weak self] in
      return self?.lastCellСondition?($0, $1, $2) ?? false
    }
    
    bind()
  }

  fileprivate func startListenToDataSoftly(_ reload: @escaping () -> Void) -> DisposeBag? {
    guard let containerView = self.containerView else { return nil }

    let softReloadDisposeBag = DisposeBag()
    let delayedObservable: Observable<Void> = .just(())
    let scrollObservable: Observable<Void> = containerView.rx.contentOffset.map { _ in return () }

    Observable.merge(scrollObservable, delayedObservable)
      .debounce(0.15, scheduler: scheduler)
      .take(1)
      .subscribe(onNext: { [weak self] in
        guard self != nil else { return }
        reload()
    }).disposed(by: softReloadDisposeBag)
    return softReloadDisposeBag
  }

  fileprivate func reloadDataWithContext(_ context: CollectionUpdateContext?) {
    if let context = context {
      containerView?.batchUpdate(block: {
        self.containerView?.deleteSectionables(at: context.deletedSections)
        self.containerView?.delete(at: context.deleted)
        self.containerView?.reloadSectionables(at: context.updatedSections)
        self.containerView?.reload(at: context.updated)
        self.containerView?.insertSectionables(at: context.insertedSections)
        self.containerView?.insert(at: context.inserted)
      }, completion: nil)
    } else {
      containerView?.reloadData()
    }
  }

  fileprivate func unsubscribeSoftReload() {
    self.softReloadDisposeBag = nil
    self.softCurrentReloadDisposeBag = nil
  }

  fileprivate func appear() {
    switch state {
    case .notInitiated:
      stateEventSubject.onNext(.initiated)
      intentSubject.onNext(.initial)
    default:
      if settings.loadingBehavior.contains(.appearance) {
        intentSubject.onNext(.appearance)
      }
    }

    if settings.loadingBehavior.contains(.autoupdate) {
      startAutoupdateIfNeeded()
    }
  }

  fileprivate func disappear() {
    if !settings.loadingBehavior.contains(.autoupdateBackground) {
      timerDisposeBag = nil
    }
  }

  fileprivate func handleLastCellDisplayed() {
    if !settings.loadingBehavior.contains(.paging) {
      return
    }

    switch state {
    case .hasData:
      intentSubject.onNext(.page(page: nextPage))
    default:
      dump(state)
      print("Not ready for paging")
    }
  }

  fileprivate func startAutoupdateIfNeeded() {
    guard timerDisposeBag == nil else { return }
    let disposeBag = DisposeBag()
    Observable<Int>
      .interval(settings.autoupdatePeriod, scheduler: scheduler)
      .subscribe(onNext: { [weak self] _ in
      self?.intentSubject.onNext(.autoupdate)
    }).disposed(by: disposeBag)
    timerDisposeBag = disposeBag
  }

  fileprivate func needToHandle(intent: LoaderIntent) -> Bool {
    switch state {
    case .loading(let currentIntent):
      if intent == .force(keepData: false) || intent == .pullToRefresh {
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

  fileprivate var nextPage: Int {
    let maxPage = sections.map({ $0.page }).max()
    return (maxPage ?? 0) + 1
  }
}
