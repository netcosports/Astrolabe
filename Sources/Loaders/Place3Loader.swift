import Gnomon
import RxSwift

@available(*, unavailable, renamed: "P3Loader")
public protocol P3L: class {}

public protocol P3Loader: class {
  associatedtype P3LResult1: OptionalResult
  associatedtype P3LResult2: OptionalResult
  associatedtype P3LResult3: OptionalResult

  typealias P3LRequests = (Request<P3LResult1>, Request<P3LResult2>, Request<P3LResult3>)
  typealias P3LResults = (P3LResult1, P3LResult2, P3LResult3)

  func requests(for loadingIntent: LoaderIntent) throws -> P3LRequests

  func sections(from results: P3LResults, loadingIntent: LoaderIntent) -> [Sectionable]?
}

@available(*, unavailable, renamed: "load(p3Loader:intent:)")
public func load<T: P3Loader>(loader: T, intent: LoaderIntent) -> SectionObservable {
  return .just(nil)
}

public func load<T: P3Loader>(p3Loader: T, intent: LoaderIntent) -> SectionObservable {
  do {
    let (request1, request2, request3) = try p3Loader.requests(for: intent)
    let observable1 = Gnomon.cachedThenFetch(request1)
    let observable2 = Gnomon.cachedThenFetch(request2)
    let observable3 = Gnomon.cachedThenFetch(request3)

    let zip = Observable.zip(observable1, observable2, observable3)
    return zip.flatMap { [weak p3Loader] res1, res2, res3 -> SectionObservable in
      if res1.responseType == .httpCache && res2.responseType == .httpCache && res3.responseType == .httpCache {
        return .empty()
      } else {
        return .just(p3Loader?.sections(from: (res1.result, res2.result, res3.result), loadingIntent: intent))
      }
    }.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default)).observeOn(MainScheduler.instance)
  } catch let e {
    return .error(e)
  }
}
