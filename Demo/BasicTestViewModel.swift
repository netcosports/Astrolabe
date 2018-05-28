//
//  BasicTestViewModel.swift
//  Demo
//
//  Created by Sergei Mikhan on 5/28/18.
//  Copyright © 2018 NetcoSports. All rights reserved.
//

import RxSwift
import RxCocoa
import Astrolabe

class BasicTestViewModel: Loadable {

  let sectionPubliser = PublishSubject<[Sectionable]>()

  typealias Cell = CollectionCell<TestCollectionCell>
  typealias Item = TestViewModel
  fileprivate var all: [Item] = []

  func load(for intent: LoaderIntent) -> Observable<[Item]?>? {

    var result: [Item]? = nil
    switch intent {
    case .page(let page):
      result = [
        TestViewModel("Test title \(page) - 1"),
        TestViewModel("Test title \(page) - 2"),
        TestViewModel("Test title \(page) - 3")
      ]
    default:
      result = [
        TestViewModel("Test title initials - 1"),
        TestViewModel("Test title initials - 2"),
        TestViewModel("Test title initials - 3")
      ]
    }
    return Observable<[Item]?>.just(result).delay(1.0, scheduler: MainScheduler.instance)
  }

  func merge(items:[Item]?, for intent: LoaderIntent) -> Observable<[Item]?>? {
    guard let items = items else { return nil }
    var mergedItems = all.filter { !items.contains($0) }
    mergedItems.append(contentsOf: items)
    mergedItems.sort()
    all = mergedItems
    return .just(mergedItems)
  }

  func apply(items:[Item]?, for intent: LoaderIntent) {
    guard let cells = items?.map({ Cell(data: $0) }) else { return }
    sectionPubliser.onNext([Section(cells: cells, page: intent.page)])
  }
}
