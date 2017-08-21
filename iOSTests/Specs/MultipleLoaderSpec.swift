import XCTest
import Astrolabe
import Gnomon
import SwiftyJSON
import RxBlocking
import Nimble
import RxSwift

class MultipleLoaderSpec: XCTestCase {

  override func setUp() {
    super.setUp()
    URLCache.shared.removeAllCachedResponses()
    Gnomon.logging = true
  }

  func testMultipleLoader() {
    do {
      let loader = TestML()
      let results = try astrLoad(mLoader: loader, intent: .initial).toBlocking().toArray()
      expect(results).to(haveCount(2))

      expect(loader.didReceiveCount) == 2

      guard let cachedResult = results[0] else { return fail("nil section") }
      expect(cachedResult[0].cells).to(haveCount(0))

      guard let httpResult = results[1] else { return fail("nil section") }
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
