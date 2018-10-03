//
//  TestPlace2Loader.swift
//  Astrolabe
//
//  Created by Vladimir Burdukov on 10/2/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import Astrolabe
import Gnomon
import Nimble

class TestP2L: P2Loader {

  typealias P2LResult1 = TestModel1
  typealias P2LResult2 = TestModel2

  func requests(for loadingIntent: LoaderIntent) throws -> TestP2L.P2LRequests {
    return (
      try RequestBuilder().setURLString("\(Params.API.baseURL)/cache/20").setMethod(.GET)
        .setParams(["id1": "123"]).setXPath("args").build(),
      try RequestBuilder().setURLString("\(Params.API.baseURL)/cache/20").setMethod(.GET)
        .setParams(["id2": "234"]).setXPath("args").build()
    )
  }

  typealias Cell = CollectionCell<TestViewCell>

  func sections(from results: TestP2L.P2LResults, loadingIntent: LoaderIntent) -> [Sectionable]? {
    if Thread.isMainThread { fail("sections should not be called in main thread") }

    let model1 = results.0
    let model2 = results.1

    return [Section(cells: [
      Cell(data: TestViewCell.ViewModel(model1)),
      Cell(data: TestViewCell.ViewModel(model2))
    ])]
  }

  var didReceiveCount = 0

  func didReceive(results: TestP2L.P2LResults, loadingIntent: LoaderIntent) {
    if !Thread.isMainThread { fail("didReceive should be called in main thread") }
    didReceiveCount += 1
  }

}
