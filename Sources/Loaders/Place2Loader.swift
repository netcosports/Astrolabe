import Gnomon
import RxSwift
#if SWIFT_PACKAGE
  import Astrolabe
#endif

public protocol P2Loader: class {
  associatedtype P2LResult1: BaseModel
  associatedtype P2LResult2: BaseModel
  associatedtype Output

  typealias P2LRequests = (Request<P2LResult1>, Request<P2LResult2>)
  typealias P2LResults = (P2LResult1, P2LResult2)

  func requests(for loadingIntent: LoaderIntent) throws -> P2LRequests
  func sections(from results: P2LResults, loadingIntent: LoaderIntent) -> Output?
  func didReceive(results: P2LResults, loadingIntent: LoaderIntent)
}

public extension P2Loader {
  func didReceive(results: P2LResults, loadingIntent: LoaderIntent) {}
}

public protocol P2ContextLoader: class {
  associatedtype P2LResult1: BaseModel
  associatedtype P2LResult2: BaseModel
  associatedtype Context
  associatedtype Output

  typealias P2LRequests = (Request<P2LResult1>, Request<P2LResult2>)
  typealias P2LResults = (P2LResult1, P2LResult2)

  func requests(for loadingIntent: LoaderIntent, context: Context) throws -> P2LRequests
  func sections(from results: P2LResults, loadingIntent: LoaderIntent, context: Context) -> Output?
  func didReceive(results: P2LResults, loadingIntent: LoaderIntent, context: Context)
}

public extension P2ContextLoader {
  func didReceive(results: P2LResults, loadingIntent: LoaderIntent, context: Context) {}
}

public func load<T: P2Loader>(p2Loader loader: T, intent: LoaderIntent) -> Observable<T.Output?> {
  do {
    let (request1, request2) = try loader.requests(for: intent)
    let observable1 = Gnomon.cachedThenFetch(request1)
    let observable2 = Gnomon.cachedThenFetch(request2)

    return Observable.combineLatest(observable1, observable2).filter {
      switch ($0.type, $1.type) {
      case (.localCache, .localCache): return true
      case (.localCache, _), (_, .localCache): return false
      default: return true
      }
    }.flatMap { [weak loader] res1, res2 -> Observable<T.Output?> in
      if res1.type == .httpCache && res2.type == .httpCache {
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

public func load<T: P2ContextLoader>(p2Loader loader: T, intent: LoaderIntent, context: T.Context) -> Observable<T.Output?> {
  do {
    let (request1, request2) = try loader.requests(for: intent, context: context)
    let observable1 = Gnomon.cachedThenFetch(request1)
    let observable2 = Gnomon.cachedThenFetch(request2)

    return Observable.zip(observable1, observable2).flatMap { [weak loader] res1, res2 -> Observable<T.Output?> in
      if res1.type == .httpCache && res2.type == .httpCache {
        return .empty()
      } else {
        let results = (res1.result, res2.result)
        return Observable.just(loader?.sections(from: results, loadingIntent: intent, context: context)).do(onNext: { _ in
          loader?.didReceive(results: results, loadingIntent: intent, context: context)
        }).subscribeOn(MainScheduler.instance)
      }
    }.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default)).observeOn(MainScheduler.instance)
  } catch {
    return .error(error)
  }
}
