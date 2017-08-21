import Gnomon
import RxSwift

public protocol PLoader: class {
  associatedtype PLResult: OptionalResult

  func request(for loadingIntent: LoaderIntent) throws -> Request<PLResult>
  func sections(from result: PLResult, loadingIntent: LoaderIntent) -> [Sectionable]?
  func didReceive(result: PLResult, loadingIntent: LoaderIntent)
}

public extension PLoader {
  func didReceive(result: PLResult, loadingIntent: LoaderIntent) {}
}

public func astrLoad<T: PLoader>(pLoader loader: T, intent: LoaderIntent) -> SectionObservable {
  do {
    let request = try loader.request(for: intent)
    let observable: Observable<Response<T.PLResult>>
    switch intent {
    case .page, .autoupdate, .pullToRefresh:
      observable = Gnomon.models(for: request)
    case let .force(keepData) where keepData:
      observable = Gnomon.models(for: request)
    default:
      observable = Gnomon.cachedThenFetch(request)
    }
    return observable.flatMap { [weak loader] response -> SectionObservable in
      switch (intent, response.responseType) {
      case (.page, _), (.autoupdate, _), (.pullToRefresh, _): break
      case (.force(let keepData), _) where keepData: break
      case (_, .httpCache): return .empty()
      default: break
      }

      return Observable.just(loader?.sections(from: response.result, loadingIntent: intent)).do(onNext: { _ in
        loader?.didReceive(result: response.result, loadingIntent: intent)
      }).subscribeOn(MainScheduler.instance)
    }.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default)).observeOn(MainScheduler.instance)
  } catch {
    return .error(error)
  }
}
