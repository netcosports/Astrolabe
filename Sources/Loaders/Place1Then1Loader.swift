import Gnomon
import RxSwift
#if SWIFT_PACKAGE
  import Astrolabe
#endif

public protocol P1T1Loader: class {
  associatedtype P1T1LFirstResult: BaseModel
  associatedtype P1T1LSecondResult: BaseModel
  associatedtype Output

  typealias P1T1LFirstRequest = Request<P1T1LFirstResult>
  typealias P1T1LSecondRequest = Request<P1T1LSecondResult>
  typealias P1T1LResults = (P1T1LFirstResult, P1T1LSecondResult)

  func request(for loadingIntent: LoaderIntent) throws -> P1T1LFirstRequest
  func request(for loadingIntent: LoaderIntent, from result: P1T1LFirstResult) throws -> P1T1LSecondRequest

  func sections(from results: P1T1LResults, loadingIntent: LoaderIntent) -> Output?
  func didReceive(results: P1T1LResults, loadingIntent: LoaderIntent)
}

public extension P1T1Loader {
  func didReceive(results: P1T1LResults, loadingIntent: LoaderIntent) {}
}

public func load<T: P1T1Loader>(p1t1Loader loader: T, intent: LoaderIntent) -> Observable<T.Output?> {
  do {
    let request = try loader.request(for: intent)

    let cached = Gnomon.cachedModels(for: request).flatMap { [weak loader] res1 -> Observable<T.Output?> in
      guard let loader = loader else { return .just(nil) }
      let request = try loader.request(for: intent, from: res1.result)

      return Gnomon.cachedModels(for: request).flatMap { [weak loader] res2 -> Observable<T.Output?> in
        guard let loader = loader else { return .just(nil) }
        let results = (res1.result, res2.result)
        return Observable.just(loader.sections(from: results, loadingIntent: intent)).do(onNext: { [weak loader] _ in
          loader?.didReceive(results: results, loadingIntent: intent)
        }).subscribeOn(MainScheduler.instance)
      }
    }

    let http = Gnomon.models(for: request).flatMap { [weak loader] res1 -> Observable<T.Output?> in
      guard let loader = loader else { return .just(nil) }
      let request = try loader.request(for: intent, from: res1.result)

      return Gnomon.models(for: request).flatMap { [weak loader] res2 -> Observable<T.Output?> in
        guard let loader = loader else { return .just(nil) }
        if res1.type == .httpCache && res2.type == .httpCache {
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
