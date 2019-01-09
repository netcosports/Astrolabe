//
//  TestMultipleLoader.swift
//  Astrolabe
//
//  Created by Vladimir Burdukov on 12/2/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import Astrolabe
import Gnomon
import Nimble

class TestML: MLoader {

  var mLoaderResponses: [[Result<Response<MLResult>>]] = []

  typealias MLResult = TestModel1

  func requests(for loadingIntent: LoaderIntent) throws -> TestML.MLRequests {
    return try (0 ... 3).map { index -> Request<MLResult> in
      let id = String(123 + index * 111)
      return try Request(URLString: "\(Params.API.baseURL)/get?id1=\(id)").setMethod(.GET)
        .setXPath("args")
    }
  }

  typealias Cell = CollectionCell<TestViewCell>

  func sections(from results: TestML.MLResults, loadingIntent: LoaderIntent) -> [Sectionable]? {
    if Thread.isMainThread { fail("sections should not be called in main thread") }
    return [Section(cells: results.compactMap { $0.value }.map { Cell(data: TestViewCell.ViewModel($0)) })]
  }

  var didReceiveCount = 0

  func didReceive(results: TestML.MLResults, loadingIntent: LoaderIntent) {
    if !Thread.isMainThread { fail("didReceive should be called in main thread") }
    didReceiveCount += 1
  }

}
