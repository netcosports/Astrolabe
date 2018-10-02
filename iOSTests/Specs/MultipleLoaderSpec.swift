import XCTest
import Astrolabe
import Gnomon
import SwiftyJSON
import RxBlocking
import Nimble
import RxSwift

extension Result: Equatable where T: Equatable {

  public static func == (lhs: Result<T>, rhs: Result<T>) -> Bool {
    switch (lhs, rhs) {
    case let (.ok(lhs), .ok(rhs)): return lhs == rhs
    default: return false
    }
  }

}

class MultipleLoaderSpec: XCTestCase {

  override func setUp() {
    super.setUp()
    URLCache.shared.removeAllCachedResponses()
    Gnomon.logging = true
  }

  func testMultipleLoader() {
    do {
      let loader = TestML()
      let results = try Astrolabe.load(mLoader: loader, intent: .initial).toBlocking().toArray()
      expect(results).to(haveCount(1))

      expect(loader.mLoaderResponses.map { $0.map { $0.value?.type }})
        == [Array(repeating: .some(ResponseType.regular), count: 4)]

      expect(loader.didReceiveCount) == 1

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

  func testMultipleLoaderOneRequestCached() {
    do {
      let loader = TestML()
      _ = try Gnomon.models(for: loader.requests(for: .initial)[1]).toBlocking().toArray()

      let results = try Astrolabe.load(mLoader: loader, intent: .initial).toBlocking().toArray()
      expect(results).to(haveCount(2))
      expect(loader.didReceiveCount) == 2

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

  func testMultipleLoaderAllRequestsCached() {
    do {
      let loader = TestML()
      for request in try loader.requests(for: .initial) {
        _ = try Gnomon.models(for: request).toBlocking().toArray()
      }

      let results = try Astrolabe.load(mLoader: loader, intent: .initial).toBlocking().toArray()
      expect(results).to(haveCount(2))

      expect(loader.mLoaderResponses.map { $0.map { $0.map { $0.type } }}) == [
        [.ok(ResponseType.localCache), .ok(ResponseType.localCache), .ok(ResponseType.localCache), .ok(ResponseType.localCache)],
        [.ok(ResponseType.regular), .ok(ResponseType.regular), .ok(ResponseType.regular), .ok(ResponseType.regular)]
      ]

      expect(loader.didReceiveCount) == 2

      do {
        guard let cachedResult = results[0] else { return fail("nil section") }
        guard let cells = cachedResult[0].cells as? [CollectionCell<TestViewCell>] else { return fail(
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
      }

      do {
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
      }
    } catch {
      fail("\(error)")
    }
  }

}
