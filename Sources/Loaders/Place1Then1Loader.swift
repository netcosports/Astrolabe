import Gnomon
import RxSwift

public protocol P1T1Loader: class {
  associatedtype P1T1LFirstResult: OptionalResult
  associatedtype P1T1LSecondResult: OptionalResult

  typealias P1T1LFirstRequest = Request<P1T1LFirstResult>
  typealias P1T1LSecondRequest = Request<P1T1LSecondResult>
  typealias P1T1LResults = (P1T1LFirstResult, P1T1LSecondResult)

  func request(for loadingIntent: LoaderIntent) throws -> P1T1LFirstRequest
  func request(for loadingIntent: LoaderIntent, from result: P1T1LFirstResult) throws -> P1T1LSecondRequest

  func sections(from results: P1T1LResults, loadingIntent: LoaderIntent) -> [Sectionable]?
  func didReceive(results: P1T1LResults, loadingIntent: LoaderIntent)
}

public extension P1T1Loader {
  func didReceive(results: P1T1LResults, loadingIntent: LoaderIntent) {}
}

public func load<T: P1T1Loader>(p1t1Loader loader: T, intent: LoaderIntent) -> SectionObservable {
  do {
    let request = try loader.request(for: intent)

    let cached = Gnomon.cachedModels(for: request).flatMap { [weak loader] res1 -> SectionObservable in
      guard let loader = loader else { return .just(nil) }
      guard let request = try? loader.request(for: intent, from: res1.result) else { return .just(nil) }
      return Gnomon.cachedModels(for: request).flatMap { [weak loader] res2 -> SectionObservable in
        guard let loader = loader else { return .just(nil) }
        let results = (res1.result, res2.result)
        return Observable.just(loader.sections(from: results, loadingIntent: intent)).do(onNext: { [weak loader] _ in
          loader?.didReceive(results: results, loadingIntent: intent)
        }).subscribeOn(MainScheduler.instance)
      }
    }

    let http = Gnomon.models(for: request).flatMap { [weak loader] res1 -> SectionObservable in
      guard let loader = loader else { return .just(nil) }
      let request = try loader.request(for: intent, from: res1.result)

      return Gnomon.models(for: request).flatMap { [weak loader] res2 -> SectionObservable in
        guard let loader = loader else { return .just(nil) }
        if res1.responseType == .httpCache && res2.responseType == .httpCache {
          return .empty()
        } else {
          let results = (res1.result, res2.result)
          return Observable.just(loader.sections(from: results, loadingIntent: intent)).do(onNext: { [weak loader] _ in
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
