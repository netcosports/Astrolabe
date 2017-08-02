//
// Created by Vladimir Burdukov on 4/4/17.
// Copyright (c) 2017 CocoaPods. All rights reserved.
//

import Astrolabe
import Gnomon
import Nimble

class TextMixedLoader {

  var didReceiveMultipleCount = 0
  var didReceivePlainCount = 0

}

extension TextMixedLoader: MLoader {

  typealias MLResult = SingleOptionalResult<TestModel1>

  func requests(for loadingIntent: LoaderIntent) throws -> TextMixedLoader.MLRequests {
    return try (0...3).map { index -> Request<MLResult> in
      let id = String(123 + index * 111)
      return try RequestBuilder().setURLString("http://httpbin.org/get?id1=\(id)").setMethod(.GET)
        .setXPath("args").build()
    }
  }

  typealias Cell = CollectionCell<TestViewCell>

  func sections(from results: TextMixedLoader.MLResults, loadingIntent: LoaderIntent) -> [Sectionable]? {
    if Thread.isMainThread { fail("sections should not be called in main thread") }
    return [Section(cells: results.flatMap { $0.model }.map { Cell(data: TestViewCell.ViewModel($0)) })]
  }

  func didReceive(results: TextMixedLoader.MLResults, loadingIntent: LoaderIntent) {
    if !Thread.isMainThread { fail("didReceive should be called in main thread") }
    didReceiveMultipleCount += 1
  }

}

extension TextMixedLoader: PLoader {

  typealias PLResult = SingleOptionalResult<TestModel1>

  func request(for loadingIntent: LoaderIntent) throws -> Request<PLResult> {
    return try RequestBuilder().setURLString("http://httpbin.org/cache/20").setMethod(.GET)
      .setParams(["id1": "123"]).setXPath("args").build()
  }

  func sections(from result: PLResult, loadingIntent: LoaderIntent) -> [Sectionable]? {
    if Thread.isMainThread { fail("sections should not be called in main thread") }
    return [Section(cells: [result.model].flatMap { $0 }.map { Cell(data: TestViewCell.ViewModel($0)) })]
  }

  func didReceive(result: PLResult, loadingIntent: LoaderIntent) {
    if !Thread.isMainThread { fail("didReceive should be called in main thread") }
    didReceivePlainCount += 1
  }

}
