import Gnomon
import RxSwift

public protocol P3Loader: class {
  associatedtype P3LResult1: OptionalResult
  associatedtype P3LResult2: OptionalResult
  associatedtype P3LResult3: OptionalResult

  typealias P3LRequests = (Request<P3LResult1>, Request<P3LResult2>, Request<P3LResult3>)
  typealias P3LResults = (P3LResult1, P3LResult2, P3LResult3)

  func requests(for loadingIntent: LoaderIntent) throws -> P3LRequests
  func sections(from results: P3LResults, loadingIntent: LoaderIntent) -> [Sectionable]?
  func didReceive(results: P3LResults, loadingIntent: LoaderIntent)
}

public extension P3Loader {
  func didReceive(results: P3LResults, loadingIntent: LoaderIntent) {}
}

public func load<T: P3Loader>(p3Loader loader: T, intent: LoaderIntent) -> SectionObservable {
  do {
    let (request1, request2, request3) = try loader.requests(for: intent)
    let observable1 = Gnomon.cachedThenFetch(request1)
    let observable2 = Gnomon.cachedThenFetch(request2)
    let observable3 = Gnomon.cachedThenFetch(request3)

    let zip = Observable.zip(observable1, observable2, observable3)
    return zip.flatMap { [weak loader] res1, res2, res3 -> SectionObservable in
      if res1.responseType == .httpCache && res2.responseType == .httpCache && res3.responseType == .httpCache {
        return .empty()
      } else {
        let results = (res1.result, res2.result, res3.result)
        return Observable.just(loader?.sections(from: results, loadingIntent: intent)).do(onNext: { _ in
          loader?.didReceive(results: results, loadingIntent: intent)
        }).subscribeOn(MainScheduler.instance)
      }
    }.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default)).observeOn(MainScheduler.instance)
  } catch {
    return .error(error)
  }
}
