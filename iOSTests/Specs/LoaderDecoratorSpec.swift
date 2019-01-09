//
//  LoaderDecoratorSpec.swift
//  Demo
//
//  Created by Sergei Mikhan on 10/03/18.
//  Copyright © 2018 NetcoSports. All rights reserved.
//

import XCTest
import Astrolabe
import Nimble

extension LoaderIntent: Hashable {

  public var hashValue: Int {
    switch self {
      case .initial: return 0
      case .appearance: return 1
      case .force(let keepData): return keepData ? 2 : 3
      case .pullToRefresh: return 4
      case .autoupdate: return 5
      case .page(let page): return 6 + page
    }
  }
}

struct SectionDescriptor: Equatable {
  let page: Int
  let id: Int

  init(_ page: Int, _ id: Int) {
    self.page = page
    self.id = id
  }

  static public func == (lhs: SectionDescriptor, rhs: SectionDescriptor) -> Bool {
    return lhs.page == rhs.page && lhs.id == rhs.id
  }
}

typealias SD = SectionDescriptor

private class ConfigurableLoader: Astrolabe.Loadable, Containerable {
  typealias Configuration = [LoaderIntent: [SD]]

  var allItems: [Sectionable] = []
  let configuration: Configuration
  let source: CollectionViewSource

  init(configuration: Configuration, source: CollectionViewSource) {
    self.configuration = configuration
    self.source = source
  }

  func load(for intent: LoaderIntent) -> SectionObservable? {
    if let pagesForIntent = configuration[intent] {
      return .just(pagesForIntent.compactMap { ConfigurableLoader.section(with: $0) })
    } else {
      fail("Unexpected type of intent")
      return nil
    }
  }

  func apply(mergeResult: MergeResult?, for intent: LoaderIntent) {
    guard let items = mergeResult?.items else { return }
    source.sections = items
    source.containerView?.reloadData()
  }

  typealias Cell = CollectionCell<TestViewCell>
  fileprivate static func section(with sd: SD) -> Sectionable? {
    let viewModel = TestViewCell.ViewModel("id")
    let cells: [Cellable] = (0..<sd.id).map { _ in Cell(data: viewModel) }
    return Section(cells: cells, page: sd.page)
  }
}

extension Array where Element == Sectionable {

  var sectionDescriptors: [SD] {
    // NOTE: to identify sections correctly we are using cells count
    // in real project, using cell id is more efficient way
    return self.map { SD($0.page, $0.cells.count) }
  }
}

class LoaderDecoratorSpec: XCTestCase {

  func testAutoUpdate() {
    let initialPages    = [SD(0, 1), SD(1, 1), SD(5, 1)]
    let autoupdatePages = [SD(0, 1), SD(1, 3), SD(1, 2), SD(1, 1), SD(2, 2), SD(4, 2), SD(5, 2)]

    let configuration: ConfigurableLoader.Configuration = [
      .initial: initialPages,
      .autoupdate: autoupdatePages
    ]
    let containerView = CollectionView<LoaderDecoratorSource<CollectionViewSource>>()
    let source = containerView.source
    source.loadingBehavior = [.autoupdate]
    source.autoupdatePeriod = TimeInterval(0.5)
    let loader = ConfigurableLoader(configuration: configuration, source: source.source)
    source.loader = LoaderMediator(loader: loader)

    waitUntil { [weak source, weak loader] done in
      source?.stopProgress = {
        guard let source = source else { return }
        guard let loader = loader else { return }
        switch $0 {
        case .initial:
          expect(source.sections.sectionDescriptors).to(equal(initialPages))
          expect(loader.allItems.sectionDescriptors).to(equal(initialPages))
        case .autoupdate:
          expect(source.sections.sectionDescriptors).to(equal(autoupdatePages))
          expect(loader.allItems.sectionDescriptors).to(equal(autoupdatePages))
          done()
        default:
          fail("Unexpected type of intent")
        }
      }
      source?.appear()
    }
  }

  func testAppereance() {
    let initialPages    = [SD(0, 1), SD(1, 1), SD(5, 1)]
    let appearancePages = [SD(0, 1), SD(1, 1), SD(1, 2), SD(1, 3), SD(3, 1), SD(4, 1), SD(5, 1)]

    let configuration: ConfigurableLoader.Configuration = [
      .initial: initialPages,
      .appearance: appearancePages
    ]
    let containerView = CollectionView<LoaderDecoratorSource<CollectionViewSource>>()
    let source = containerView.source
    source.loadingBehavior = [.appearance]
    let loader = ConfigurableLoader(configuration: configuration, source: source.source)
    source.loader = LoaderMediator(loader: loader)

    waitUntil { [weak source, weak loader] done in
      source?.stopProgress = {
        guard let source = source else { return }
        guard let loader = loader else { return }
        switch $0 {
        case .initial:
          expect(source.sections.sectionDescriptors).to(equal(initialPages))
          expect(loader.allItems.sectionDescriptors).to(equal(initialPages))
        case .appearance:
          expect(source.sections.sectionDescriptors).to(equal(appearancePages))
          expect(loader.allItems.sectionDescriptors).to(equal(appearancePages))
          done()
        default:
          fail("Unexpected type of intent")
        }
      }
      // NOTE: since for initial appearance will be fired .initial intent
      // instead of .appearance we need to call disapper and appear again
      source?.appear()
      source?.disappear()
      source?.appear()
    }
  }

  func testPaging() {
    let initialPages    = [SD(0, 1), SD(1, 1)]
    let secondPages     = [SD(2, 2), SD(3, 2), SD(4, 2)]
    let thirdPages      = [SD(5, 3), SD(6, 3), SD(7, 3)]
    let foursPages      = [SD(8, 0)]

    let expectedSecondPages   = initialPages + secondPages
    let expectedThirdPages    = initialPages + secondPages + thirdPages
    let expectedFoursPages    = expectedThirdPages

    let configuration: ConfigurableLoader.Configuration = [
      .initial: initialPages,
      .page(page: 2): secondPages,
      .page(page: 5): thirdPages,
      .page(page: 8): foursPages
    ]
    let containerView = CollectionView<LoaderDecoratorSource<CollectionViewSource>>()
    let source = containerView.source
    source.loadingBehavior = [.paging]
    let loader = ConfigurableLoader(configuration: configuration, source: source.source)
    source.loader = LoaderMediator(loader: loader)

    waitUntil { [weak source, weak loader] done in
      source?.stopProgress = {
        guard let source = source else { return }
        guard let loader = loader else { return }
        switch $0 {
        case .initial:
          expect(source.sections.sectionDescriptors).to(equal(initialPages))
          source.forceLoadNextPage()
        case .page(let page):
          switch page {
          case 2:
            expect(source.sections.sectionDescriptors).to(equal(expectedSecondPages))
            expect(loader.allItems.sectionDescriptors).to(equal(expectedSecondPages))
            source.forceLoadNextPage()
          case 5:
            expect(source.sections.sectionDescriptors).to(equal(expectedThirdPages))
            expect(loader.allItems.sectionDescriptors).to(equal(expectedThirdPages))
            source.forceLoadNextPage()
          case 8:
            expect(source.sections.sectionDescriptors).to(equal(expectedFoursPages))
            expect(loader.allItems.sectionDescriptors).to(equal(expectedFoursPages))
            done()
          default: fail("Unexpected page number")
          }
        default:
          fail("Unexpected type of intent")
        }
      }
      source?.appear()
    }
  }
}
