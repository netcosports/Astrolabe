import Gnomon
import RxSwift

@available(*, unavailable, renamed: "P2T1Loader")
public protocol P2T1L: class {}

public protocol P2T1Loader: class {
  associatedtype P2T1LFirstResult1: OptionalResult
  associatedtype P2T1LFirstResult2: OptionalResult
  associatedtype P2T1LSecondResult: OptionalResult

  typealias P2T1LFirstRequests = (Request<P2T1LFirstResult1>, Request<P2T1LFirstResult2>)
  typealias P2T1LFirstResults = (P2T1LFirstResult1, P2T1LFirstResult2)
  typealias P2T1LSecondRequest = Request<P2T1LSecondResult>
  typealias P2T1LResults = (P2T1LFirstResult1, P2T1LFirstResult2, P2T1LSecondResult)

  func requests(for loadingIntent: LoaderIntent) throws -> P2T1LFirstRequests

  func request(for loadingIntent: LoaderIntent, from firstResults: P2T1LFirstResults) throws -> P2T1LSecondRequest

  func sections(from results: P2T1LResults, loadingIntent: LoaderIntent) -> [Sectionable]?
}

@available(*, unavailable, renamed: "load(p2t1Loader:intent:)")
public func load<T: P2T1Loader>(loader: T, intent: LoaderIntent) -> SectionObservable {
  return .just(nil)
}

public func load<T: P2T1Loader>(p2t1Loader: T, intent: LoaderIntent) -> SectionObservable {
  do {
    let (request1, request2) = try p2t1Loader.requests(for: intent)

    let cachedZip = Observable.zip(Gnomon.cachedModels(for: request1),
                                   Gnomon.cachedModels(for: request2))
    let cached = cachedZip.flatMap { [weak p2t1Loader] res1, res2 -> SectionObservable in
      guard let request = try p2t1Loader?.request(for: intent, from: (res1.result, res2.result)) else {
        return .just(nil)
      }
      let observable = Gnomon.cachedModels(for: request)
      return observable.flatMap { [weak p2t1Loader] res -> SectionObservable in
        return .just(p2t1Loader?.sections(from: (res1.result, res2.result, res.result), loadingIntent: intent))
      }
    }

    let httpCached = Observable.zip(Gnomon.models(for: request1), Gnomon.models(for: request2))
    let http = httpCached.flatMap { [weak p2t1Loader] res1, res2 -> SectionObservable in
      guard let request = try p2t1Loader?.request(for: intent, from: (res1.result, res2.result)) else {
        return .just(nil)
      }
      let observable = Gnomon.models(for: request)
      return observable.flatMap { [weak p2t1Loader] res -> SectionObservable in
        if res.responseType == .httpCache {
          return .empty()
        } else {
          return .just(p2t1Loader?.sections(from: (res1.result, res2.result, res.result), loadingIntent: intent))
        }
      }
    }

    return cached.concat(http).subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default))
      .observeOn(MainScheduler.instance)
  } catch let e {
    return .error(e)
  }
}
