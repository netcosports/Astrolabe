//
//  DiffCollectionViewViewModel.swift
//  Demo
//
//  Created by Alexander Zhigulich on 4/29/19.
//  Copyright © 2019 NetcoSports. All rights reserved.
//

import UIKit
import Astrolabe
import RxSwift
import RxCocoa

class DiffCollectionViewViewModel {

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

    input.source.settings.loadingBehavior = [.initial, .autoupdate]
    input.source.settings.autoupdatePeriod = 0.1
    input.source.intentObservable
      .observeOn(SerialDispatchQueueScheduler(qos: .background))
      .flatMapLatest({ [weak self] intent -> Observable<LoaderResultEvent> in
        guard let self = self else { return .empty() }
        return self.load(for: intent)
          .concat(Observable.just(.completed(intent: intent)))
    }).bind(to: input.source.sectionsObserver).disposed(by: disposeBag)

    self.input.source.sectionsObservable.subscribe { [weak self] sections in
      self?.sections = sections.element ?? []
      }.disposed(by: disposeBag)

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

    Observable<Int>.interval(0.1, scheduler: SerialDispatchQueueScheduler(qos: .background)).map { _ in
      LoaderResultEvent.force(sections: [], context: nil)
      }.bind(to: input.source.sectionsObserver).disposed(by: disposeBag)

//    Observable<Int>.interval(0.3, scheduler: MainScheduler.instance).map { _ in
//      LoaderResultEvent.softCurrent
//      }.bind(to: input.source.sectionsObserver).disposed(by: disposeBag)
  }

  private func load(for intent: LoaderIntent) -> Observable<LoaderResultEvent> {

    let oldSections = self.sections
    let newSections: [Sectionable] = (0...Int.random(in: 0...2)).shuffled().map { sectionIndex in
      print("--- section[\(sectionIndex)]:")
      let section = MultipleSupplementariesSection(
        supplementaries: [CellType.header, CellType.footer].suffix(from: Int.random(in: 0...2)).shuffled().map { supplyType in
          print("      --- supply[\(supplyType)]:")
          return Cell(
            data: TestViewModel("Supply \(sectionIndex) - \(supplyType)"),
            id: "supply_\(sectionIndex)_\(supplyType)",
            type: supplyType,
            dataEquals: { $0 == $1 })
        },
        cells: (0...Int.random(in: 0...2)).shuffled().map { cellIndex in
          print("      --- cell[\(cellIndex)]:")
          return Cell(
            data: TestViewModel("\(sectionIndex) - \(cellIndex)"),
            id: "cell_\(sectionIndex)_\(cellIndex)",
            dataEquals: { $0 == $1 })
        })
      section.id = "section_\(sectionIndex)"
      return section
    }

    if intent == .initial {
      return Observable<LoaderResultEvent>.just(LoaderResultEvent.force(
        sections: newSections,
        context: nil
      ))
    } else {
      let context = DiffUtils<TestViewModel>.diff(new: newSections, old: oldSections)

      return Observable<LoaderResultEvent>.just(LoaderResultEvent.force(
        sections: newSections,
        context: context
      ))
    }
  }
}
