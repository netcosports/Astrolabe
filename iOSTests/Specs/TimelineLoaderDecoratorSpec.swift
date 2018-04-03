//
//  TimelineLoaderDecoratorSpec.swift
//  iOSTests
//
//  Created by Sergei Mikhan on 3/12/18.
//  Copyright © 2018 NetcoSports. All rights reserved.
//

import XCTest
import Astrolabe
import RxSwift
import Nimble

private class ConfigurableLoader: Astrolabe.TimelineLoader {

  typealias Item = String
  typealias Cell = CollectionCell<TestViewCell>
  typealias Configuration = [LoaderIntent: [Item]]

  let configuration: Configuration
  init(configuration: Configuration) {
    self.configuration = configuration
  }

  func performLoading(intent: LoaderIntent) -> ItemsObservable? {
    if let itemsForIntent = configuration[intent] {
      return .just(itemsForIntent)
    } else {
      fail("Unexpected type of intent")
      return nil
    }
  }

  func cells(for items: [Item], intent: LoaderIntent) -> [Cellable] {
    return items.map { Cell(data: TestViewCell.ViewModel($0), id: $0) }
  }

  func section(for cells: [Cellable], intent: LoaderIntent) -> Sectionable {
    return Section(cells: cells, page: intent.page)
  }
}

extension ReusableSource {

  var allItems: [String] {
    if let section = sections.first {
      return section.cells.map { $0.id }
    } else {
      return []
    }
  }
}

class TimelineLoaderDecoratorSpec: XCTestCase {

  private typealias TimelineDecorator = TimelineLoaderDecorator<CollectionViewSource, ConfigurableLoader>

  func testAutoUpdate() {
    let initialPages    = ["A", "B", "C", "D", "E"]
    let autoupdatePages = ["A", "B", "C", "D", "E", "F", "H", "J"]

    let configuration: ConfigurableLoader.Configuration = [
      .initial: initialPages,
      .autoupdate: autoupdatePages
    ]
    let containerView = CollectionView<TimelineDecorator>()
    let source = containerView.source
    source.loadingBehavior = [.autoupdate]
    source.autoupdatePeriod = TimeInterval(0.5)
    let loader = ConfigurableLoader(configuration: configuration)
    source.merger.loader = loader

    waitUntil { done in
      source.stopProgress = {
        switch $0 {
        case .initial:
          expect(source.allItems).to(equal(initialPages))
        case .autoupdate:
          expect(source.allItems).to(equal(autoupdatePages))
          done()
        default:
          fail("Unexpected type of intent")
        }
      }
      source.appear()
    }
  }

  func testAppereance() {
    let initialPages    = ["A", "B", "C", "D", "E"]
    let appearancePages = ["A", "B", "C", "D", "E", "F", "H", "J", "O", "P"]

    let configuration: ConfigurableLoader.Configuration = [
      .initial: initialPages,
      .appearance: appearancePages
    ]
    let containerView = CollectionView<TimelineDecorator>()
    let source = containerView.source
    source.loadingBehavior = [.appearance]
    let loader = ConfigurableLoader(configuration: configuration)
    source.merger.loader = loader

    waitUntil { done in
      source.stopProgress = {
        switch $0 {
        case .initial:
          expect(source.allItems).to(equal(initialPages))
        case .appearance:
          expect(source.allItems).to(equal(appearancePages))
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
    let initialPages    = ["A", "B", "C"]
    let secondPages     = ["C", "D", "E"]
    let thirdPages      = ["H", "J", "O", "P"]

    let expectedSecondPages   = ["A", "B", "C", "D", "E"]
    let expectedThirdPages    = ["A", "B", "C", "D", "E", "H", "J", "O", "P"]

    let configuration: ConfigurableLoader.Configuration = [
      .initial: initialPages,
      .page(page: 1): secondPages,
      .page(page: 2): thirdPages,
      ]
    let containerView = CollectionView<TimelineDecorator>()
    let source = containerView.source
    source.loadingBehavior = [.paging]
    let loader = ConfigurableLoader(configuration: configuration)
    source.merger.loader = loader

    waitUntil { done in
      source.stopProgress = {
        switch $0 {
        case .initial:
          expect(source.allItems).to(equal(initialPages))
        case .page(let page):
          switch page {
          case 1: expect(source.allItems).to(equal(expectedSecondPages))
          case 2: expect(source.allItems).to(equal(expectedThirdPages))
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
