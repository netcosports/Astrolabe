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
  func didReceive(results: P1T2LResults, loadingIntent: LoaderIntent)
}

public extension P1T2Loader {
  func didReceive(results: P1T2LResults, loadingIntent: LoaderIntent) {}
}

public func load<T: P1T2Loader>(p1t2Loader loader: T, intent: LoaderIntent) -> SectionObservable {
  do {
    let request = try loader.request(for: intent)

    let cached = Gnomon.cachedModels(for: request).flatMap { [weak loader] response -> SectionObservable in
      guard let (request1, request2) = try loader?.requests(for: intent, from: response.result) else {
        return .just(nil)
      }
      let observable1 = Gnomon.cachedModels(for: request1)
      let observable2 = Gnomon.cachedModels(for: request2)

      return Observable.zip(observable1, observable2).flatMap { [weak loader] res1, res2 -> SectionObservable in
        let results = (response.result, res1.result, res2.result)
        return Observable.just(loader?.sections(from: results, loadingIntent: intent)).do(onNext: { _ in
          loader?.didReceive(results: results, loadingIntent: intent)
        }).subscribeOn(MainScheduler.instance)
      }
    }

    let http = Gnomon.models(for: request).flatMap { [weak loader] response -> SectionObservable in
      guard let (request1, request2) = try loader?.requests(for: intent, from: response.result) else {
        throw "loader is equal to nil"
      }
      let observable1 = Gnomon.models(for: request1)
      let observable2 = Gnomon.models(for: request2)

      let zip = Observable.zip(observable1, observable2)

      return zip.flatMap { [weak loader] res1, res2 -> SectionObservable in
        if response.responseType == .httpCache && res1.responseType == .httpCache && res2.responseType == .httpCache {
          return .empty()
        } else {
          let results = (response.result, res1.result, res2.result)
          return Observable.just(loader?.sections(from: results, loadingIntent: intent)).do(onNext: { _ in
            loader?.didReceive(results: results, loadingIntent: intent)
          }).subscribeOn(MainScheduler.instance)
        }
      }
    }

    return cached.concat(http).subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default))
      .observeOn(MainScheduler.instance)
  } catch {
    return .error(error)
  }
}
