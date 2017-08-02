import XCTest
import Astrolabe
import Gnomon
import SwiftyJSON
import RxBlocking
import Nimble
import RxSwift

class Place2LoaderSpec: XCTestCase {

  override func setUp() {
    super.setUp()
    URLCache.shared.removeAllCachedResponses()
    Gnomon.logging = true
  }

  func testPlace2Loader() {
    do {
      let loader = TestP2L()
      let results = try load(p2Loader: loader, intent: .initial).toBlocking().toArray()
      expect(results).to(haveCount(2))

      expect(loader.didReceiveCount) == 2

      guard results[0] == nil else { return fail("cached section should be nil section") }

      guard let httpResult = results[1] else { return fail("nil section") }
      guard let cells = httpResult[0].cells as? [CollectionCell<TestViewCell>] else {
        return fail("invalid cells type")
      }
      expect(cells).to(haveCount(2))

      let testViewCell = TestViewCell()
      var expected = 123

      for data in cells {
        data.setup(with: testViewCell)
        expect(testViewCell.title) == String(expected)

        testViewCell.title = nil
        expected += 111
      }
    } catch let e {
      fail("\(e)")
    }
  }

  func testPlace2LoaderHttpCache() {
    do {
      let loader = TestP2L()

      let (request1, request2) = try loader.requests(for: .initial)
      _ = try Observable.zip(Gnomon.models(for: request1),
                             Gnomon.models(for: request2)).toBlocking().first()

      let results = try load(p2Loader: loader, intent: .initial).toBlocking().toArray()
      expect(results).to(haveCount(1))

      expect(loader.didReceiveCount) == 1

      guard let cachedResult = results[0] else { return fail("nil section") }
      guard let cells = cachedResult[0].cells as? [CollectionCell<TestViewCell>] else {
        return fail("invalid cells type")
      }
      expect(cells).to(haveCount(2))

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
