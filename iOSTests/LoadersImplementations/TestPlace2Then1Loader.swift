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

class TestP2T1L: P2T1Loader {

  typealias P2T1LFirstResult1 = SingleOptionalResult<TestModel1>
  typealias P2T1LFirstResult2 = SingleOptionalResult<TestModel2>
  typealias P2T1LSecondResult = SingleOptionalResult<TestModel3>

  public func requests(for loadingIntent: LoaderIntent) throws -> TestP2T1L.P2T1LFirstRequests {
    return (
      try RequestBuilder().setURLString("\(Params.API.baseURL)/cache/20").setParams(["id1": "123"])
        .setXPath("args").build(),
      try RequestBuilder().setURLString("\(Params.API.baseURL)/cache/20").setParams(["id2": "234"])
        .setXPath("args").build()
    )
  }

  func request(for loadingIntent: LoaderIntent,
               from firstResults: TestP2T1L.P2T1LFirstResults) throws -> Request<P2T1LSecondResult> {
    return try RequestBuilder().setURLString("\(Params.API.baseURL)/cache/20").setParams(["id3": "345"])
      .setXPath("args").build()
  }

  typealias Cell = CollectionCell<TestViewCell>

  func sections(from results: TestP2T1L.P2T1LResults, loadingIntent: LoaderIntent) -> [Sectionable]? {
    if Thread.isMainThread { fail("sections should not be called in main thread") }
    guard let model1 = results.0.model, let model2 = results.1.model, let model3 = results.2.model else { return nil }
    return [Section(cells: [
      Cell(data: TestViewCell.ViewModel(model1)),
      Cell(data: TestViewCell.ViewModel(model2)),
      Cell(data: TestViewCell.ViewModel(model3))
    ])]
  }

  var didReceiveCount = 0

  func didReceive(results: TestP2T1L.P2T1LResults, loadingIntent: LoaderIntent) {
    if !Thread.isMainThread { fail("didReceive should be called in main thread") }
    didReceiveCount += 1
  }

}
