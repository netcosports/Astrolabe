//
//  TestPlace3Loader.swift
//  Astrolabe
//
//  Created by Vladimir Burdukov on 12/2/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import Astrolabe
import Gnomon
import Nimble

class TestP3L: P3Loader {

  typealias P3LResult1 = TestModel1
  typealias P3LResult2 = TestModel2
  typealias P3LResult3 = TestModel3

  func requests(for loadingIntent: LoaderIntent) throws -> TestP3L.P3LRequests {
    return (
      try Request(URLString: "\(Params.API.baseURL)/cache/20").setMethod(.GET).setParams(["id1": "123"])
        .setXPath("args"),
      try Request(URLString: "\(Params.API.baseURL)/cache/20").setMethod(.GET).setParams(["id2": "234"])
        .setXPath("args"),
      try Request(URLString: "\(Params.API.baseURL)/cache/20").setMethod(.GET).setParams(["id3": "345"])
        .setXPath("args")
    )
  }

  typealias Cell = CollectionCell<TestViewCell>

  func sections(from results: TestP3L.P3LResults, loadingIntent: LoaderIntent) -> [Sectionable]? {
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

  func didReceive(results: TestP3L.P3LResults, loadingIntent: LoaderIntent) {
    if !Thread.isMainThread { fail("didReceive should be called in main thread") }
    didReceiveCount += 1
  }

}
