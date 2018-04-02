import Gnomon
import RxSwift

public protocol PLoader: class {
  associatedtype PLResult: OptionalResult

  typealias PLRequest = Request<PLResult>
  
  func request(for loadingIntent: LoaderIntent) throws -> PLRequest
  func sections(from result: PLResult, loadingIntent: LoaderIntent) -> [Sectionable]?
  func didReceive(result: PLResult, loadingIntent: LoaderIntent)
}

public extension PLoader {
  func didReceive(result: PLResult, loadingIntent: LoaderIntent) {}
}

public protocol PContextLoader: class {
  associatedtype PLResult: OptionalResult
  associatedtype Context

  typealias PLRequest = Request<PLResult>

  func request(for loadingIntent: LoaderIntent, context: Context) throws -> PLRequest
  func sections(from result: PLResult, loadingIntent: LoaderIntent, context: Context) -> [Sectionable]?
  func didReceive(result: PLResult, loadingIntent: LoaderIntent, context: Context)
}

public extension PContextLoader {
  func didReceive(result: PLResult, loadingIntent: LoaderIntent, context: Context) {}
}

public func load<T: PLoader>(pLoader loader: T, intent: LoaderIntent) -> SectionObservable {
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

public func load<T: PContextLoader>(pLoader loader: T, intent: LoaderIntent, context: T.Context) -> SectionObservable {
  do {
    let request = try loader.request(for: intent, context: context)
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

      return Observable.just(loader?.sections(from: response.result, loadingIntent: intent, context: context)).do(onNext: { _ in
        loader?.didReceive(result: response.result, loadingIntent: intent, context: context)
      }).subscribeOn(MainScheduler.instance)
    }.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default)).observeOn(MainScheduler.instance)
  } catch {
    return .error(error)
  }
}
