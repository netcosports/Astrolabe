import Gnomon
import RxSwift

@available(*, unavailable, renamed: "P2Loader")
public protocol P2L: class {}

public protocol P2Loader: class {
  associatedtype P2LResult1: OptionalResult
  associatedtype P2LResult2: OptionalResult

  typealias P2LRequests = (Request<P2LResult1>, Request<P2LResult2>)
  typealias P2LResults = (P2LResult1, P2LResult2)

  func requests(for loadingIntent: LoaderIntent) throws -> P2LRequests
  func sections(from results: P2LResults, loadingIntent: LoaderIntent) -> [Sectionable]?
}

@available(*, unavailable, renamed: "load(p2Loader:intent:)")
public func load<T: P2Loader>(loader: T, intent: LoaderIntent) -> SectionObservable {
  return .just(nil)
}

public func load<T: P2Loader>(p2Loader: T, intent: LoaderIntent) -> SectionObservable {
  do {
    let (request1, request2) = try p2Loader.requests(for: intent)
    let observable1 = Gnomon.cachedThenFetch(request1)
    let observable2 = Gnomon.cachedThenFetch(request2)

    let zip = Observable.zip(observable1, observable2)
    return zip.flatMap { [weak p2Loader] res1, res2 -> SectionObservable in
      print("\(res1.responseType) \(res2.responseType)")
      if res1.responseType == .httpCache && res2.responseType == .httpCache {
        return .empty()
      } else {
        return .just(p2Loader?.sections(from: (res1.result, res2.result), loadingIntent: intent))
      }
    }.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default)).observeOn(MainScheduler.instance)
  } catch let e {
    return .error(e)
  }
}
