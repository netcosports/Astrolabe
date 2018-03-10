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

private class ConfigurableLoader: Astrolabe.Loader {
  typealias Configuration = [LoaderIntent: [SD]]
  let configuration: Configuration
  init(configuration: Configuration) {
    self.configuration = configuration
  }

  func performLoading(intent: LoaderIntent) -> SectionObservable? {
    if let pagesForIntent = configuration[intent] {
      return .just(pagesForIntent.flatMap { ConfigurableLoader.section(with: $0) })
    } else {
      fail("Unexpected type of intent")
      return nil
    }
  }

  typealias Cell = CollectionCell<TestViewCell>
  fileprivate static func section(with sd: SD) -> Sectionable? {
    let viewModel = TestViewCell.ViewModel("id")
    let cells: [Cellable] = (0..<sd.id).map { _ in Cell(data: viewModel) }
    return Section(cells: cells, page: sd.page)
  }
}

extension ReusableSource {

  var sectionDescriptors: [SD] {
    // NOTE: to identify sections correctly we are using cells count
    // in real project, using cell id is more efficient way
    return sections.map { SD($0.page, $0.cells.count) }
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
    let loader = ConfigurableLoader(configuration: configuration)
    source.loader = loader

    waitUntil { done in
      source.stopProgress = {
        switch $0 {
        case .initial:
          expect(source.sectionDescriptors).to(equal(initialPages))
        case .autoupdate:
          expect(source.sectionDescriptors).to(equal(autoupdatePages))
          done()
        default:
          fail("Unexpected type of intent")
        }
      }
      source.appear()
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
    let loader = ConfigurableLoader(configuration: configuration)
    source.loader = loader

    waitUntil { done in
      source.stopProgress = {
        switch $0 {
        case .initial:
          expect(source.sectionDescriptors).to(equal(initialPages))
        case .appearance:
          expect(source.sectionDescriptors).to(equal(appearancePages))
          done()
        default:
          fail("Unexpected type of intent")
        }
      }
      // NOTE: since for initial appearance will be fired .initial intent
      // instead of .appearance we need to call disapper and appear again
      source.appear()
      source.disappear()
      source.appear()
    }
  }

  func testPaging() {
    let initialPages    = [SD(0, 1), SD(1, 1)]
    let secondPages     = [SD(2, 2), SD(3, 2), SD(4, 2)]
    let thirdPages      = [SD(5, 3), SD(6, 3), SD(7, 3)]

    let expectedSecondPages   = [SD(0, 1), SD(1, 1), SD(2, 2), SD(3, 2), SD(4, 2)]
    let expectedThirdPages    = [SD(0, 1), SD(1, 1), SD(2, 2), SD(3, 2), SD(4, 2), SD(5, 3), SD(6, 3), SD(7, 3)]

    let configuration: ConfigurableLoader.Configuration = [
      .initial: initialPages,
      .page(page: 2): secondPages,
      .page(page: 5): thirdPages,
    ]
    let containerView = CollectionView<LoaderDecoratorSource<CollectionViewSource>>()
    let source = containerView.source
    source.loadingBehavior = [.paging]
    let loader = ConfigurableLoader(configuration: configuration)
    source.loader = loader

    waitUntil { done in
      source.stopProgress = {
        switch $0 {
        case .initial:
          expect(source.sectionDescriptors).to(equal(initialPages))
        case .page(let page):
          switch page {
          case 2: expect(source.sectionDescriptors).to(equal(expectedSecondPages))
          case 5: expect(source.sectionDescriptors).to(equal(expectedThirdPages))
            done()
          default: fail("Unexpected page number")
          }
        default:
          fail("Unexpected type of intent")
        }
      }
      source.appear()
      source.forceLoadNextPage()
      source.forceLoadNextPage()
    }
  }
}
