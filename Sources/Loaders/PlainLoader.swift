import Gnomon
import RxSwift

public protocol PLoader: class {
  associatedtype PLResult: OptionalResult

  func request(for loadingIntent: LoaderIntent) throws -> Request<PLResult>

  func sections(from result: PLResult, loadingIntent: LoaderIntent) -> [Sectionable]?
}

public func load<T: PLoader>(pLoader: T, intent: LoaderIntent) -> SectionObservable {
  do {
    let request = try pLoader.request(for: intent)
    let observable: Observable<Response<T.PLResult>>
    switch intent {
    case .page, .autoupdate, .pullToRefresh:
      observable = Gnomon.models(for: request)
    case let .force(keepData) where keepData:
      observable = Gnomon.models(for: request)
    default:
      observable = Gnomon.cachedThenFetch(request)
    }
    return observable.flatMap { [weak pLoader] response -> SectionObservable in
      switch (intent, response.responseType) {
      case (.page, _), (.autoupdate, _), (.pullToRefresh, _): break
      case (.force(let keepData), _) where keepData: break
      case (_, .httpCache): return .empty()
      default: break
      }

      return .just(pLoader?.sections(from: response.result, loadingIntent: intent))
    }.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default)).observeOn(MainScheduler.instance)
  } catch {
    return .error(error)
  }
}
