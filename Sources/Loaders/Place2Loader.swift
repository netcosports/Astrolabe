import Gnomon
import RxSwift

public protocol P2Loader: class {
  associatedtype P2LResult1: OptionalResult
  associatedtype P2LResult2: OptionalResult

  typealias P2LRequests = (Request<P2LResult1>, Request<P2LResult2>)
  typealias P2LResults = (P2LResult1, P2LResult2)

  func requests(for loadingIntent: LoaderIntent) throws -> P2LRequests
  func sections(from results: P2LResults, loadingIntent: LoaderIntent) -> [Sectionable]?
  func didReceive(results: P2LResults, loadingIntent: LoaderIntent)
}

public extension P2Loader {
  func didReceive(results: P2LResults, loadingIntent: LoaderIntent) {}
}

public func load<T: P2Loader>(p2Loader loader: T, intent: LoaderIntent) -> SectionObservable {
  do {
    let (request1, request2) = try loader.requests(for: intent)
    let observable1 = Gnomon.cachedThenFetch(request1)
    let observable2 = Gnomon.cachedThenFetch(request2)

    return Observable.zip(observable1, observable2).flatMap { [weak loader] res1, res2 -> SectionObservable in
      if res1.responseType == .httpCache && res2.responseType == .httpCache {
        return .empty()
      } else {
        let results = (res1.result, res2.result)
        return Observable.just(loader?.sections(from: results, loadingIntent: intent)).do(onNext: { _ in
          loader?.didReceive(results: results, loadingIntent: intent)
        }).subscribeOn(MainScheduler.instance)
      }
    }.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default)).observeOn(MainScheduler.instance)
  } catch {
    return .error(error)
  }
}
