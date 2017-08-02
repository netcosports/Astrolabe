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
}

public func load<T: P1T1Loader>(p1t1Loader: T, intent: LoaderIntent) -> SectionObservable {
  do {
    let request = try p1t1Loader.request(for: intent)

    let cached = Gnomon.cachedModels(for: request).flatMap { [weak p1t1Loader] res1 -> SectionObservable in
      guard let request = try p1t1Loader?.request(for: intent, from: res1.result) else { return .just(nil) }
      return Gnomon.cachedModels(for: request).flatMap { [weak p1t1Loader] res2 -> SectionObservable in
        return .just(p1t1Loader?.sections(from: (res1.result, res2.result), loadingIntent: intent))
      }
    }

    let http = Gnomon.models(for: request).flatMap { [weak p1t1Loader] res1 -> SectionObservable in
      guard let request = try p1t1Loader?.request(for: intent, from: res1.result) else {
        throw "loader is equal to nil"
      }
      return Gnomon.models(for: request).flatMap { [weak p1t1Loader] res2 -> SectionObservable in
        if res1.responseType == .httpCache && res2.responseType == .httpCache {
          return .empty()
        } else {
          return .just(p1t1Loader?.sections(from: (res1.result, res2.result), loadingIntent: intent))
        }
      }
    }

    return cached.concat(http).subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default))
      .observeOn(MainScheduler.instance)
  } catch {
    return .error(error)
  }
}
