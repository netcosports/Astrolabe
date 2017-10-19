//
//  ThreadingSpec.swift
//  Demo
//
//  Created by Vladimir Burdukov on 13/10/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import XCTest
import Astrolabe
import Nimble
import RxSwift

private class Loader: Astrolabe.Loader {

  func performLoading(intent: LoaderIntent) -> SectionObservable? {
    return .just([])
  }

}

class ThreadingSpec: XCTestCase {

  func testStartProgress() {
    let source = LoaderDecoratorSource<CollectionViewSource>()
    let loader = Loader()
    source.loader = loader

    waitUntil { done in
      source.startProgress = { _ in
        MainScheduler.ensureExecutingOnScheduler()
        done()
      }

      DispatchQueue.global(qos: .background).async {
        source.appear()
      }
    }
  }

  func testStopProgress() {
    let source = LoaderDecoratorSource<CollectionViewSource>()
    let loader = Loader()
    source.loader = loader

    waitUntil { done in
      source.stopProgress = { _ in
        MainScheduler.ensureExecutingOnScheduler()
        done()
      }

      DispatchQueue.global(qos: .background).async {
        source.appear()
      }
    }
  }

  func testUpdateEmptyView() {
    let source = LoaderDecoratorSource<CollectionViewSource>()
    let loader = Loader()
    source.loader = loader

    waitUntil { done in
      source.updateEmptyView = { _ in
        MainScheduler.ensureExecutingOnScheduler()
        done()
      }

      DispatchQueue.global(qos: .background).async {
        source.appear()
      }
    }
  }

}
