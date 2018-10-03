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

  var pLoaderResponses: [Response<PLResult>] = []
  var mLoaderResponses: [[Result<Response<MLResult>>]] = []

}

extension TextMixedLoader: MLoader {

  typealias MLResult = TestModel1

  func requests(for loadingIntent: LoaderIntent) throws -> TextMixedLoader.MLRequests {
    return try (0...3).map { index -> Request<MLResult> in
      let id = String(123 + index * 111)
      return try Request(URLString: "\(Params.API.baseURL)/get?id1=\(id)").setMethod(.GET)
        .setXPath("args")
    }
  }

  typealias Cell = CollectionCell<TestViewCell>

  func sections(from results: TextMixedLoader.MLResults, loadingIntent: LoaderIntent) -> [Sectionable]? {
    if Thread.isMainThread { fail("sections should not be called in main thread") }
    return [Section(cells: results.compactMap { $0.value }.map { Cell(data: TestViewCell.ViewModel($0)) })]
  }

  func didReceive(results: TextMixedLoader.MLResults, loadingIntent: LoaderIntent) {
    if !Thread.isMainThread { fail("didReceive should be called in main thread") }
    didReceiveMultipleCount += 1
  }

}

extension TextMixedLoader: PLoader {

  typealias PLResult = TestModel1

  func request(for loadingIntent: LoaderIntent) throws -> Request<PLResult> {
    return try Request(URLString: "\(Params.API.baseURL)/cache/20").setMethod(.GET)
      .setParams(["id1": "123"]).setXPath("args")
  }

  func sections(from result: PLResult, loadingIntent: LoaderIntent) -> [Sectionable]? {
    if Thread.isMainThread { fail("sections should not be called in main thread") }
    return [Section(cells: [Cell(data: TestViewCell.ViewModel(result))])]
  }

  func didReceive(result: PLResult, loadingIntent: LoaderIntent) {
    if !Thread.isMainThread { fail("didReceive should be called in main thread") }
    didReceivePlainCount += 1
  }

}
