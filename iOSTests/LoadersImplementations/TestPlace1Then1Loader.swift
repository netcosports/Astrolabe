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

class TestP1T1L: P1T1Loader {

  typealias P1T1LFirstResult = TestModel1
  typealias P1T1LSecondResult = TestModel2

  func request(for loadingIntent: LoaderIntent) throws -> TestP1T1L.P1T1LFirstRequest {
    return try RequestBuilder().setURLString("\(Params.API.baseURL)/cache/20").setParams(["id1": "123"])
      .setXPath("args").build()
  }

  func request(for loadingIntent: LoaderIntent,
               from result: TestP1T1L.P1T1LFirstResult) throws -> TestP1T1L.P1T1LSecondRequest {
    return try RequestBuilder().setURLString("\(Params.API.baseURL)/cache/20").setParams(["id2": "234"])
      .setXPath("args").build()
  }

  typealias Cell = CollectionCell<TestViewCell>

  func sections(from results: TestP1T1L.P1T1LResults, loadingIntent: LoaderIntent) -> [Sectionable]? {
    if Thread.isMainThread { fail("sections should not be called in main thread") }
    let model1 = results.0
    let model2 = results.1

    return [Section(cells: [
      Cell(data: TestViewCell.ViewModel(model1)),
      Cell(data: TestViewCell.ViewModel(model2))
    ])]
  }

  var didReceiveCount = 0

  func didReceive(results: TestP1T1L.P1T1LResults, loadingIntent: LoaderIntent) {
    if !Thread.isMainThread { fail("didReceive should be called in main thread") }
    didReceiveCount += 1
  }

}
