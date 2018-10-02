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
      let results = try Astrolabe.load(p2Loader: loader, intent: .initial).toBlocking().toArray()
      expect(results).to(haveCount(1))

      expect(loader.didReceiveCount) == 1

      guard let httpResult = results[0] else { return fail("nil section") }
      guard let cells = httpResult[0].cells as? [CollectionCell<TestViewCell>] else {
        return fail("invalid cells type")
      }
      expect(cells).to(haveCount(2))

      let testViewCell = TestViewCell()

      cells[0].setup(with: testViewCell)
      expect(testViewCell.title) == "123"

      cells[1].setup(with: testViewCell)
      expect(testViewCell.title) == "234"
    } catch {
      fail("\(error)")
    }
  }

  func testPlace2LoaderAllCached() {
    do {
      let loader = TestP2L()

      let (request1, request2) = try loader.requests(for: .initial)
      _ = try Observable.zip(Gnomon.models(for: request1),
                             Gnomon.models(for: request2)).toBlocking().first()

      let results = try Astrolabe.load(p2Loader: loader, intent: .initial).toBlocking().toArray()
      expect(results).to(haveCount(1))

      expect(loader.didReceiveCount) == 1

      guard let cachedResult = results[0] else { return fail("nil section") }
      guard let cells = cachedResult[0].cells as? [CollectionCell<TestViewCell>] else {
        return fail("invalid cells type")
      }
      expect(cells).to(haveCount(2))

      let testViewCell = TestViewCell()

      cells[0].setup(with: testViewCell)
      expect(testViewCell.title) == "123"

      cells[1].setup(with: testViewCell)
      expect(testViewCell.title) == "234"
    } catch {
      fail("\(error)")
    }
  }

  func testPlace2LoaderFirstCached() {
    do {
      let loader = TestP2L()

      let (request1, _) = try loader.requests(for: .initial)
      _ = try Gnomon.models(for: request1).toBlocking().first()

      let results = try Astrolabe.load(p2Loader: loader, intent: .initial).toBlocking().toArray()
      expect(results).to(haveCount(1))

      expect(loader.didReceiveCount) == 1

      guard let httpResult = results[0] else { return fail("nil section") }
      guard let cells = httpResult[0].cells as? [CollectionCell<TestViewCell>] else {
        return fail("invalid cells type")
      }
      expect(cells).to(haveCount(2))

      let testViewCell = TestViewCell()

      cells[0].setup(with: testViewCell)
      expect(testViewCell.title) == "123"

      cells[1].setup(with: testViewCell)
      expect(testViewCell.title) == "234"
    } catch {
      fail("\(error)")
    }
  }

  func testPlace2LoaderSecondCached() {
    do {
      let loader = TestP2L()

      let (_, request2) = try loader.requests(for: .initial)
      _ = try Gnomon.models(for: request2).toBlocking().first()

      let results = try Astrolabe.load(p2Loader: loader, intent: .initial).toBlocking().toArray()
      expect(results).to(haveCount(1))

      expect(loader.didReceiveCount) == 1

      guard let cachedResult = results[0] else { return fail("nil section") }
      guard let cells = cachedResult[0].cells as? [CollectionCell<TestViewCell>] else {
        return fail("invalid cells type")
      }
      expect(cells).to(haveCount(2))

      let testViewCell = TestViewCell()

      cells[0].setup(with: testViewCell)
      expect(testViewCell.title) == "123"

      cells[1].setup(with: testViewCell)
      expect(testViewCell.title) == "234"
    } catch {
      fail("\(error)")
    }
  }

}
