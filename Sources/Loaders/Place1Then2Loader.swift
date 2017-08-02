import Gnomon
import RxSwift

public protocol P1T2Loader: class {
  associatedtype P1T2LFirstResult: OptionalResult
  associatedtype P1T2LSecondResult1: OptionalResult
  associatedtype P1T2LSecondResult2: OptionalResult

  typealias P1T2LSecondRequests = (Request<P1T2LSecondResult1>, Request<P1T2LSecondResult2>)
  typealias P1T2LResults = (P1T2LFirstResult, P1T2LSecondResult1, P1T2LSecondResult2)

  func request(for loadingIntent: LoaderIntent) throws -> Request<P1T2LFirstResult>

  func requests(for loadingIntent: LoaderIntent, from firstResult: P1T2LFirstResult) throws -> P1T2LSecondRequests

  func sections(from results: P1T2LResults, loadingIntent: LoaderIntent) -> [Sectionable]?
}

public func load<T: P1T2Loader>(p1t2Loader: T, intent: LoaderIntent) -> SectionObservable {
  do {
    let request = try p1t2Loader.request(for: intent)

    let cached = Gnomon.cachedModels(for: request).flatMap { [weak p1t2Loader] response -> SectionObservable in
      guard let (request1, request2) = try p1t2Loader?.requests(for: intent, from: response.result) else {
        return .just(nil)
      }
      let observable1 = Gnomon.cachedModels(for: request1)
      let observable2 = Gnomon.cachedModels(for: request2)

      let zip = Observable.zip(observable1, observable2) {
        ($0, $1)
      }

      return zip.flatMap { [weak p1t2Loader] res1, res2 -> SectionObservable in
        return .just(p1t2Loader?.sections(from: (response.result, res1.result, res2.result), loadingIntent: intent))
      }
    }

    let http = Gnomon.models(for: request).flatMap { [weak p1t2Loader] response -> SectionObservable in
      guard let (request1, request2) = try p1t2Loader?.requests(for: intent, from: response.result) else {
        throw "loader is equal to nil"
      }
      let observable1 = Gnomon.models(for: request1)
      let observable2 = Gnomon.models(for: request2)

      let zip = Observable.zip(observable1, observable2)

      return zip.flatMap { [weak p1t2Loader] res1, res2 -> SectionObservable in
        if response.responseType == .httpCache && res1.responseType == .httpCache && res2.responseType == .httpCache {
          return .empty()
        } else {
          return .just(p1t2Loader?.sections(from: (response.result, res1.result, res2.result), loadingIntent: intent))
        }
      }
    }

    return cached.concat(http).subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default))
      .observeOn(MainScheduler.instance)
  } catch {
    return .error(error)
  }
}
