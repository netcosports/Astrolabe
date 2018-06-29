//
// Created by Vladimir Burdukov on 4/4/17.
// Copyright (c) 2017 CocoaPods. All rights reserved.
//

import Astrolabe
import XCTest
import Gnomon
import SwiftyJSON
import RxBlocking
import Nimble
import RxSwift

class MixedLoaderSpec: XCTestCase {

  override func setUp() {
    super.setUp()
    URLCache.shared.removeAllCachedResponses()
    Gnomon.logging = true
  }

  func testPlainLoader() {
    do {
      let loader = TextMixedLoader()
      let results: [[Sectionable]?] = try Astrolabe.load(pLoader: loader, intent: .initial).toBlocking().toArray()
      expect(results).to(haveCount(1))

      expect(loader.didReceivePlainCount) == 1

      guard let httpResult = results[0] else { return fail("nil result") }
      guard let cells = httpResult[0].cells as? [CollectionCell<TestViewCell>] else {
        return fail("invalid cells type")
      }

      expect(cells).to(haveCount(1))

      let testViewCell = TestViewCell()
      var expected = 123

      for data in cells {
        data.setup(with: testViewCell)
        expect(testViewCell.title) == String(expected)

        testViewCell.title = nil
        expected += 111
      }
    } catch {
      fail("\(error)")
    }
  }

  func testMultipleLoader() {
    do {
      let loader = TextMixedLoader()
      let results = try Astrolabe.load(mLoader: loader, intent: .initial).toBlocking().toArray()
      expect(results).to(haveCount(1))

      expect(loader.didReceiveMultipleCount) == 1

      guard let httpResult = results[0] else { return fail("nil section") }
      guard let cells = httpResult[0].cells as? [CollectionCell<TestViewCell>] else { return fail(
        "invalid cells type") }
      expect(cells).to(haveCount(4))

      let testViewCell = TestViewCell()
      var expected = 123

      for data in cells {
        data.setup(with: testViewCell)
        expect(testViewCell.title) == String(expected)

        testViewCell.title = nil
        expected += 111
      }
    } catch {
      fail("\(error)")
    }
  }

}
