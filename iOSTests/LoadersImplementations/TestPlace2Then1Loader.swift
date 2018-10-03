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

  typealias P2T1LFirstResult1 = TestModel1
  typealias P2T1LFirstResult2 = TestModel2
  typealias P2T1LSecondResult = TestModel3

  public func requests(for loadingIntent: LoaderIntent) throws -> TestP2T1L.P2T1LFirstRequests {
    return (
      try Request(URLString: "\(Params.API.baseURL)/cache/20").setParams(["id1": "123"])
        .setXPath("args"),
      try Request(URLString: "\(Params.API.baseURL)/cache/20").setParams(["id2": "234"])
        .setXPath("args")
    )
  }

  func request(for loadingIntent: LoaderIntent,
               from firstResults: TestP2T1L.P2T1LFirstResults) throws -> Request<P2T1LSecondResult> {
    return try Request(URLString: "\(Params.API.baseURL)/cache/20").setParams(["id3": "345"])
      .setXPath("args")
  }

  typealias Cell = CollectionCell<TestViewCell>

  func sections(from results: TestP2T1L.P2T1LResults, loadingIntent: LoaderIntent) -> [Sectionable]? {
    if Thread.isMainThread { fail("sections should not be called in main thread") }
    let model1 = results.0
    let model2 = results.1
    let model3 = results.2

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
