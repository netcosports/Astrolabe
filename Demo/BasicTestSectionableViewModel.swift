//
//  BasicTestSectionableViewModel.swift
//  Demo
//
//  Created by Sergei Mikhan on 6/20/18.
//  Copyright © 2018 NetcoSports. All rights reserved.
//

import RxSwift
import RxCocoa
import Astrolabe

class BasicTestSectionableViewModel: Loadable, Containerable {

  let sectionPubliser = PublishSubject<[Sectionable]>()

  typealias Cell = CollectionCell<TestCollectionCell>
  typealias Item = Sectionable

  var allItems: [Item] = []

  func load(for intent: LoaderIntent) -> Observable<[Item]?>? {
    var result: [TestViewModel]
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
    let cells: [Cellable] = result.map { Cell(data: $0) }
    return Observable<[Item]?>
      .just([Section(cells: cells, page: intent.page)])
      .delay(1.0, scheduler: MainScheduler.instance)
  }

  func apply(mergeResult: MergeResult?, for intent: LoaderIntent) {
    guard let items = mergeResult?.items else { return }
    sectionPubliser.onNext(items)
  }
}
