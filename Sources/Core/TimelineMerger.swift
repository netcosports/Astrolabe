//
//  TimelineLoader.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 2/4/18.
//  Copyright © 2018 Netcosports. All rights reserved.
//

import UIKit
import RxSwift

public protocol TimelineLoader: class {
  associatedtype Item: Comparable

  typealias ItemsObservable = Observable<[Item]?>
  func performLoading(intent: LoaderIntent) -> ItemsObservable?
  func cells(for items: [Item], intent: LoaderIntent) -> [Cellable]
  func section(for cells: [Cellable], intent: LoaderIntent) -> Sectionable
}

public extension TimelineLoader {

  func section(for cells: [Cellable], intent: LoaderIntent) -> [Sectionable] {
      return [Section(cells: cells)]
  }
}

public class TimelineMerger<T: TimelineLoader>: Mergeable {
  public required init() {}

  public weak var loader: T?
  public typealias Item = T.Item
  public var items: [T.Item] = []

  public func loadItems(for intent: LoaderIntent) -> Observable<[T.Item]?>? {
    return loader?.performLoading(intent: intent)
  }

  public func merge<Source: ReusableSource>(newItems: [T.Item]?, into source: Source, for intent: LoaderIntent) {
    guard let items = newItems else { return }
    guard let loader = loader else { return }
    var mergedItems = self.items.filter { !items.contains($0) }
    mergedItems.append(contentsOf: items)
    mergedItems.sort()
    self.items = mergedItems
    source.sections = [loader.section(for: loader.cells(for: mergedItems, intent: intent), intent: intent)]
    source.registerCellsForSections()
    source.containerView?.reloadData()
  }
}

public typealias TimelineLoaderDecorator<DecoratedSource: ReusableSource, T: TimelineLoader> = GenericLoaderDecoratorSource<DecoratedSource, TimelineMerger<T>>
