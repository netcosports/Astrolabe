import Gnomon
import RxSwift

public protocol MLoader: class {
  associatedtype MLResult: OptionalResult

  typealias MLRequests = [Request<MLResult>]
  typealias MLResults = [MLResult]

  func requests(for loadingIntent: LoaderIntent) throws -> MLRequests

  func sections(from results: MLResults, loadingIntent: LoaderIntent) -> [Sectionable]?
}

public func load<T: MLoader>(mLoader: T, intent: LoaderIntent) -> SectionObservable {
  do {
    let requests = try mLoader.requests(for: intent)
    let observable = Gnomon.cachedThenFetch(requests)

    return observable.map { [weak mLoader] in
      return mLoader?.sections(from: $0.map { $0.result }, loadingIntent: intent)
    }.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default)).observeOn(MainScheduler.instance)
  } catch {
    return .error(error)
  }
}
