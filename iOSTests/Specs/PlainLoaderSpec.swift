import XCTest
import Astrolabe
import Gnomon
import SwiftyJSON
import RxBlocking
import Nimble
import RxSwift

class PlainLoaderSpec: XCTestCase {

  override func setUp() {
    super.setUp()
    URLCache.shared.removeAllCachedResponses()
    Gnomon.logging = true
  }

  func testPlainLoader() {
    do {
      let loader = TestPL()
      let results = try load(pLoader: loader, intent: .initial).toBlocking().toArray()
      expect(results).to(haveCount(2))

      guard let cachedResult = results[0] else { return fail("nil result") }
      expect(cachedResult[0].cells).to(haveCount(0))

      guard let httpResult = results[1] else { return fail("nil result") }
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

  func testPlainLoaderInitialHttpCache() {
    do {
      let loader = TestPL()
      _ = try Gnomon.models(for: loader.request(for: .initial)).toBlocking().toArray()

      let results = try load(pLoader: loader, intent: .initial).toBlocking().toArray()
      expect(results).to(haveCount(1))

      guard let cachedResult = results[0] else { return fail("nil result") }
      guard let cells = cachedResult[0].cells as? [CollectionCell<TestViewCell>] else {
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

  func testPlainLoaderPaging() {
    do {
      let loader = TestPL()

      let results = try load(pLoader: loader, intent: .page(page: 2)).toBlocking().toArray()
      expect(results).to(haveCount(1))

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

  func testPlainLoaderPagingHttpCache() {
    do {
      let loader = TestPL()
      _ = try Gnomon.models(for: loader.request(for: .page(page: 2))).toBlocking().toArray()

      let results = try load(pLoader: loader, intent: .page(page: 2)).toBlocking().toArray()
      expect(results).to(haveCount(1))

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

  func testPlainLoaderAutoupdate() {
    do {
      let loader = TestPL()

      let results = try load(pLoader: loader, intent: .autoupdate).toBlocking().toArray()
      expect(results).to(haveCount(1))

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

  func testPlainLoaderAutoupdateHttpCache() {
    do {
      let loader = TestPL()

      _ = try Gnomon.models(for: loader.request(for: .autoupdate)).toBlocking().toArray()

      let results = try load(pLoader: loader, intent: .autoupdate).toBlocking().toArray()
      expect(results).to(haveCount(1))

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

  func testPlainLoaderPullToRefresh() {
    do {
      let loader = TestPL()

      let results = try load(pLoader: loader, intent: .pullToRefresh).toBlocking().toArray()
      expect(results).to(haveCount(1))

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

  func testPlainLoaderPullToRefreshHttpCache() {
    do {
      let loader = TestPL()

      _ = try Gnomon.models(for: loader.request(for: .pullToRefresh)).toBlocking().toArray()

      let results = try load(pLoader: loader, intent: .pullToRefresh).toBlocking().toArray()
      expect(results).to(haveCount(1))

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

}
