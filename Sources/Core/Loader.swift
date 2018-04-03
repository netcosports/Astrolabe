//
//  Loader.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/9/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import RxSwift

public enum LoaderState {
  case notInitiated
  case initiated
  case loading(intent: LoaderIntent)
  case hasData
  case error(Error)
  case empty
}

let defaultReloadInterval: TimeInterval = 30
public typealias ProgressClosure = (LoaderIntent) -> Void
public typealias EmptyViewClosure = (LoaderState) -> Void

public enum LoaderIntent {
  case initial
  case appearance
  case force(keepData: Bool)
  case pullToRefresh
  case autoupdate
  case page(page: Int)
}

extension LoaderIntent: Equatable {

}

public protocol Pagable {
  var page: Int { get }
}

extension LoaderIntent: Pagable {
  public var page: Int {
    var page = 0
    switch self {
    case .page(let index):
      page = index
    default:
      break
    }
    return page
  }
}

public func == (lhs: LoaderIntent, rhs: LoaderIntent) -> Bool {
  switch (lhs, rhs) {

  case (.initial, .initial):
    return true

  case (.pullToRefresh, .pullToRefresh):
    return true

  case (.appearance, .appearance):
    return true

  case (.autoupdate, .autoupdate):
    return true

  case (let .force(keepData1), let .force(keepData2)):
    return keepData1 == keepData2

  case (let .page(page1), let .page(page2)):
    return page1 == page2

  default:
    return false
  }
}

public struct LoadingBehavior: OptionSet {
  public let rawValue: Int

  public init(rawValue: Int) { self.rawValue = rawValue }

  public static let initial = LoadingBehavior(rawValue: 1 << 0)
  public static let appearance = LoadingBehavior(rawValue: 1 << 1)
  public static let autoupdate = LoadingBehavior(rawValue: 1 << 2)
  public static let autoupdateBackground = LoadingBehavior(rawValue: 3 << 2)
  public static let paging = LoadingBehavior(rawValue: 1 << 5)
}

public protocol LoaderReusableSource: ReusableSource {
    var startProgress: ProgressClosure? { get set }
    var stopProgress: ProgressClosure? { get set }
    var updateEmptyView: EmptyViewClosure? { get set }
    var autoupdatePeriod: TimeInterval { get set }
    var loadingBehavior: LoadingBehavior { get set }

    func forceReloadData(keepCurrentDataBeforeUpdate: Bool)
    func forceLoadNextPage()
    func pullToRefresh()
    func appear()
    func disappear()
    func cancelLoading()
    func reloadDataWithEmptyDataSet()
}
