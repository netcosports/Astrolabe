import Gnomon
import RxSwift

public protocol MLoader: class {
  associatedtype MLResult: BaseModel
  associatedtype Output

  typealias MLRequests = [Request<MLResult>]
  typealias MLResults = [Result<MLResult, Error>]

  #if TEST
  var mLoaderResponses: [[Result<Response<MLResult>, Error>]] { get set }
  #endif

  func requests(for loadingIntent: LoaderIntent) throws -> MLRequests
  func sections(from results: MLResults, loadingIntent: LoaderIntent) -> Output?
  func didReceive(results: MLResults, loadingIntent: LoaderIntent)
}

public extension MLoader {
  func didReceive(results: MLResults, loadingIntent: LoaderIntent) {}
}

public func load<T: MLoader>(mLoader loader: T, intent: LoaderIntent) -> Observable<T.Output?> {
  do {
    let requests = try loader.requests(for: intent)
    let observable = Gnomon.cachedThenFetch(requests)

    return observable.flatMap { [weak loader] responses -> Observable<T.Output?> in
      #if TEST
      loader?.mLoaderResponses.append(responses)
      #endif

      let results = responses.map { $0.map { $0.result } }
      return Observable.just(loader?.sections(from: results, loadingIntent: intent)).do(onNext: { _ in
        loader?.didReceive(results: results, loadingIntent: intent)
      }).subscribeOn(MainScheduler.instance)
    }.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default)).observeOn(MainScheduler.instance)
  } catch {
    return .error(error)
  }
}
