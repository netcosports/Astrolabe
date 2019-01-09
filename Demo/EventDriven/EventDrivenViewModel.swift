//
//  EventDrivenViewModel.swift
//  Demo
//
//  Created by Sergei Mikhan on 12/27/18.
//  Copyright © 2018 NetcoSports. All rights reserved.
//

import UIKit
import Astrolabe
import RxSwift
import RxCocoa

class EventDrivenViewModel {

  struct Input {
    let source: EventDrivenLoaderSource
    let visibility: Observable<Bool>
    let isLoading: Binder<Bool>
    let isErrorHidden: Binder<Bool>
    let isNoDataHidden: Binder<Bool>
  }

  typealias Cell = CollectionCell<TestCollectionCell>

  private var sections: [Sectionable] = []
  private let disposeBag = DisposeBag()
  private let input: Input
  init(input: Input) {
    self.input = input

    input.source.settings.loadingBehavior = [.initial, .paging, .autoupdate]
    input.source.settings.autoupdatePeriod = 30.0
    input.source.intentObservable.flatMapLatest({ [weak self] intent -> Observable<LoaderResultEvent> in
      guard let self = self else { return .empty() }
      return self.load(for: intent)
        .concat(Observable.just(.completed(intent: intent)))
    }).bind(to: input.source.sectionsObserver).disposed(by: disposeBag)

    input.visibility
      .map { InputControlEvent.visibilityChanged(visible: $0) }
      .bind(to: input.source.controlObserver)
      .disposed(by: disposeBag)

    input.source.stateObservable.map { state -> Bool in
      switch state {
        case .error: return false
        default: return true
      }
    }.bind(to: input.isErrorHidden).disposed(by: disposeBag)

    input.source.stateObservable.map { state -> Bool in
      switch state {
        case .empty: return false
        default: return true
      }
    }.bind(to: input.isNoDataHidden).disposed(by: disposeBag)

    input.source.stateObservable.map { state -> Bool in
      switch state {
        case .loading: return true
        default: return false
      }
    }.bind(to: input.isLoading).disposed(by: disposeBag)

    Observable<Int>.timer(10.0, scheduler: MainScheduler.instance).map { _ in
      LoaderResultEvent.softCurrent
    }.bind(to: input.source.sectionsObserver).disposed(by: disposeBag)
  }

  private func load(for intent: LoaderIntent) -> Observable<LoaderResultEvent> {
    let sections: [Sectionable]
    switch intent {
    case .page, .autoupdate:
      let result = [
        TestViewModel("Test title \(intent.page) - 1"),
        TestViewModel("Test title \(intent.page) - 2"),
        TestViewModel("Test title \(intent.page) - 3")
      ]
      let cells: [Cellable] = result.map { Cell(data: $0) }
      sections = [Section(cells: cells, page: intent.page)]
      self.sections = self.sections.merge(items: sections, for: intent)?.items ?? []
      return Observable<LoaderResultEvent>
        .just(LoaderResultEvent.soft(sections: self.sections, context: nil))
        .delay(1.0, scheduler: MainScheduler.instance)
    default:
      let result = [
        TestViewModel("Test title initials - 1"),
        TestViewModel("Test title initials - 2"),
        TestViewModel("Test title initials - 3")
      ]
      let cells: [Cellable] = result.map { Cell(data: $0) }
      sections = [Section(cells: cells, page: intent.page)]
      self.sections = self.sections.merge(items: sections, for: intent)?.items ?? []
      return Observable<LoaderResultEvent>
        .just(LoaderResultEvent.force(sections: self.sections, context: nil))
        .delay(1.0, scheduler: MainScheduler.instance)
    }
  }
}
