//
//  TestPlace1Then2Loader.swift
//  Astrolabe
//
//  Created by Vladimir Burdukov on 12/2/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import Astrolabe
import Gnomon
import Nimble

class TestP1T2L: P1T2Loader {

  var throwOnCache = false

  typealias P1T2LFirstResult = SingleOptionalResult<TestModel1>
  typealias P1T2LSecondResult1 = SingleOptionalResult<TestModel2>
  typealias P1T2LSecondResult2 = SingleOptionalResult<TestModel3>

  func request(for loadingIntent: LoaderIntent) throws -> Request<TestP1T2L.P1T2LFirstResult> {
    return try RequestBuilder().setURLString("\(Params.API.baseURL)/cache/20").setParams(["id1": "123"])
      .setXPath("args").build()
  }

  func requests(for loadingIntent: LoaderIntent,
                from result: TestP1T2L.P1T2LFirstResult) throws -> TestP1T2L.P1T2LSecondRequests {
    if throwOnCache {
      throwOnCache = false
      throw "should throw second requests, sorry"
    }
    return (
      try RequestBuilder().setURLString("\(Params.API.baseURL)/cache/20").setParams(["id2": "234"])
        .setXPath("args").build(),
      try RequestBuilder().setURLString("\(Params.API.baseURL)/cache/20").setParams(["id3": "345"])
        .setXPath("args").build()
    )
  }

  typealias Cell = CollectionCell<TestViewCell>

  func sections(from results: TestP1T2L.P1T2LResults, loadingIntent: LoaderIntent) -> [Sectionable]? {
    if Thread.isMainThread { fail("sections should not be called in main thread") }
    guard let model1 = results.0.model, let model2 = results.1.model, let model3 = results.2.model else { return nil }
    return [Section(cells: [
      Cell(data: TestViewCell.ViewModel(model1)),
      Cell(data: TestViewCell.ViewModel(model2)),
      Cell(data: TestViewCell.ViewModel(model3))
    ])]
  }

  var didReceiveCount = 0

  func didReceive(results: TestP1T2L.P1T2LResults, loadingIntent: LoaderIntent) {
    if !Thread.isMainThread { fail("didReceive should be called in main thread") }
    didReceiveCount += 1
  }

}
