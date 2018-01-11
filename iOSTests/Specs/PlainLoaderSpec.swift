import XCTest
import Astrolabe
import Gnomon
import SwiftyJSON
import RxBlocking
import Nimble
import RxSwift

// swiftlint:disable file_length

class PlainLoaderSpec: XCTestCase {

  override func setUp() {
    super.setUp()
    URLCache.shared.removeAllCachedResponses()
    Gnomon.logging = true
  }

  func testPlainLoaderInitial() {
    do {
      let loader = TestPL()
      let results = try Astrolabe.load(pLoader: loader, intent: .initial).toBlocking().toArray()
      expect(results).to(haveCount(2))

      expect(loader.didReceiveCount) == 2

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
      _ = try Gnomon.models(for: loader.request(for: .initial, context: ())).toBlocking().toArray()

      let results = try Astrolabe.load(pLoader: loader, intent: .initial).toBlocking().toArray()
      expect(results).to(haveCount(1))

      expect(loader.didReceiveCount) == 1

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

}

extension PlainLoaderSpec {

  func testPlainLoaderPaging() {
    do {
      let loader = TestPL()

      let results = try Astrolabe.load(pLoader: loader, intent: .page(page: 2)).toBlocking().toArray()
      expect(results).to(haveCount(1))

      expect(loader.didReceiveCount) == 1

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
      _ = try Gnomon.models(for: loader.request(for: .page(page: 2), context: ())).toBlocking().toArray()

      let results = try Astrolabe.load(pLoader: loader, intent: .page(page: 2)).toBlocking().toArray()
      expect(results).to(haveCount(1))

      expect(loader.didReceiveCount) == 1

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

extension PlainLoaderSpec {

  func testPlainLoaderAutoupdate() {
    do {
      let loader = TestPL()

      let results = try Astrolabe.load(pLoader: loader, intent: .autoupdate).toBlocking().toArray()
      expect(results).to(haveCount(1))

      expect(loader.didReceiveCount) == 1

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

      _ = try Gnomon.models(for: loader.request(for: .autoupdate, context: ())).toBlocking().toArray()

      let results = try Astrolabe.load(pLoader: loader, intent: .autoupdate).toBlocking().toArray()
      expect(results).to(haveCount(1))

      expect(loader.didReceiveCount) == 1

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

extension PlainLoaderSpec {

  func testPlainLoaderPullToRefresh() {
    do {
      let loader = TestPL()

      let results = try Astrolabe.load(pLoader: loader, intent: .pullToRefresh).toBlocking().toArray()
      expect(results).to(haveCount(1))

      expect(loader.didReceiveCount) == 1

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

      _ = try Gnomon.models(for: loader.request(for: .pullToRefresh, context: ())).toBlocking().toArray()

      let results = try Astrolabe.load(pLoader: loader, intent: .pullToRefresh).toBlocking().toArray()
      expect(results).to(haveCount(1))

      expect(loader.didReceiveCount) == 1

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

extension PlainLoaderSpec {

  func testPlainLoaderForceUpdateDiscardOldData() {
    do {
      let loader = TestPL()

      let intent: LoaderIntent = .force(keepData: false)
      let results = try Astrolabe.load(pLoader: loader, intent: intent).toBlocking().toArray()
      expect(results).to(haveCount(2))

      expect(loader.didReceiveCount) == 2

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

}

extension PlainLoaderSpec {

  func testPlainLoaderForceUpdateDiscardOldDataHttpCache() {
    do {
      let loader = TestPL()

      let intent: LoaderIntent = .force(keepData: false)

      _ = try Gnomon.models(for: loader.request(for: intent, context: ())).toBlocking().toArray()

      let results = try Astrolabe.load(pLoader: loader, intent: intent).toBlocking().toArray()
      expect(results).to(haveCount(1))

      expect(loader.didReceiveCount) == 1

      guard let cacheResult = results[0] else { return fail("nil result") }
      guard let cells = cacheResult[0].cells as? [CollectionCell<TestViewCell>] else {
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

extension PlainLoaderSpec {

  func testPlainLoaderForceUpdateKeepOldData() {
    do {
      let loader = TestPL()

      let intent: LoaderIntent = .force(keepData: true)
      let results = try Astrolabe.load(pLoader: loader, intent: intent).toBlocking().toArray()
      expect(results).to(haveCount(1))

      expect(loader.didReceiveCount) == 1

      guard let cacheResult = results[0] else { return fail("nil result") }
      guard let cells = cacheResult[0].cells as? [CollectionCell<TestViewCell>] else {
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

  func testPlainLoaderForceUpdateKeepOldDataHttpCache() {
    do {
      let loader = TestPL()

      let intent: LoaderIntent = .force(keepData: true)

      _ = try Gnomon.models(for: loader.request(for: intent, context: ())).toBlocking().toArray()

      let results = try Astrolabe.load(pLoader: loader, intent: intent).toBlocking().toArray()
      expect(results).to(haveCount(1))

      expect(loader.didReceiveCount) == 1

      guard let cacheResult = results[0] else { return fail("nil result") }
      guard let cells = cacheResult[0].cells as? [CollectionCell<TestViewCell>] else {
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

// swiftlint:enable file_length
