//
//  EventDrivenSourceSpec.swift
//  iOSTests
//
//  Created by Sergei Mikhan on 2/25/19.
//  Copyright © 2019 NetcoSports. All rights reserved.
//

import Astrolabe
import RxSwift
import RxTest
import Nimble
import Quick

public func equal<T: Equatable>(expectedEvents: [Recorded<Event<T>>]) -> Predicate<[Recorded<Event<T>>]> {
  return Predicate { (actualExpression: Expression<[Recorded<Event<T>>]>) throws -> PredicateResult in
    let msg = ExpectationMessage.expectedActualValueTo("equal <\(expectedEvents)>")
    if let actualEvents = try actualExpression.evaluate() {
      let result = zip(actualEvents, expectedEvents).reduce(true, { result, events -> Bool in
        return result &&
          events.0.time == events.1.time &&
          events.0.value == events.1.value
      })
      return PredicateResult(
        bool: result,
        message: msg
      )
    } else {
      return PredicateResult(
        status: .fail,
        message: msg.appendedBeNilHint()
      )
    }
  }
}

class EventDrivenSourceSpec: QuickSpec {

  typealias EventDrivenCollection = CollectionView<EventDrivenLoaderDecoratorSource<CollectionViewSource>>
  var scheduler: TestScheduler!
  var disposeBag: DisposeBag!
  var collectionView: EventDrivenCollection!

  override func spec() {
    describe("loading behaviors") {

      beforeEach {
        self.scheduler = TestScheduler(initialClock: 0)
        self.disposeBag = DisposeBag()
        self.collectionView = EventDrivenCollection()
        self.collectionView.source.scheduler = self.scheduler
      }

      context("paging") {
        beforeEach {
          self.collectionView.source.settings.loadingBehavior = [.initial, .paging]
        }

        it("has paginated on force") {
          let intents = self.scheduler.createObserver(LoaderIntent.self)
          self.scheduler.createColdObservable([
            .next(10, .visibilityChanged(visible: true))
          ]).bind(to: self.collectionView.source.controlObserver)
          .disposed(by: self.disposeBag)

          self.collectionView.source.intentObservable.bind(to: intents).disposed(by: self.disposeBag)
          self.scheduler.scheduleAt(50, action: {
            self.scheduler.stop()
          })
          self.scheduler.start()

          expect(intents.events).to(equal(expectedEvents: [
            .next(10, .initial),
            .next(40, .autoupdate)
            ]))
        }
      }

      context("autoupdateBackground") {
        beforeEach {
          self.collectionView.source.settings.loadingBehavior = [.initial, .autoupdateBackground, .appearance]
        }

        it("has started when view becomes visible") {
          let intents = self.scheduler.createObserver(LoaderIntent.self)
          self.scheduler.createColdObservable([
            .next(10, .visibilityChanged(visible: true))
          ]).bind(to: self.collectionView.source.controlObserver)
          .disposed(by: self.disposeBag)

          self.collectionView.source.intentObservable.bind(to: intents).disposed(by: self.disposeBag)
          self.scheduler.scheduleAt(50, action: {
            self.scheduler.stop()
          })
          self.scheduler.start()

          expect(intents.events).to(equal(expectedEvents: [
            .next(10, .initial),
            .next(40, .autoupdate)
          ]))
        }

        it("has started even if view is invisible") {
          let intents = self.scheduler.createObserver(LoaderIntent.self)

          self.scheduler.createColdObservable([
            .next(10, .visibilityChanged(visible: true)),
            .next(20, .visibilityChanged(visible: false)),
            .next(25, .visibilityChanged(visible: true))
          ]).bind(to: self.collectionView.source.controlObserver)
          .disposed(by: self.disposeBag)

          self.collectionView.source.intentObservable.bind(to: intents).disposed(by: self.disposeBag)

          self.scheduler.scheduleAt(80, action: {
            self.scheduler.stop()
          })

          self.scheduler.start()

          expect(intents.events).to(equal(expectedEvents: [
            .next(10, .initial),
            .next(25, .appearance),
            .next(40, .autoupdate),
            .next(70, .autoupdate)
          ]))
        }
      }

      context("autoupdate") {

        beforeEach {
          self.collectionView.source.settings.loadingBehavior = [.initial, .autoupdate, .appearance]
        }

        it("has started when view becomes visible") {
          let intents = self.scheduler.createObserver(LoaderIntent.self)
          self.scheduler.createColdObservable([
            .next(10, .visibilityChanged(visible: true))
          ]).bind(to: self.collectionView.source.controlObserver)
            .disposed(by: self.disposeBag)

          self.collectionView.source.intentObservable.bind(to: intents).disposed(by: self.disposeBag)
          self.scheduler.scheduleAt(50, action: {
            self.scheduler.stop()
          })
          self.scheduler.start()

          expect(intents.events).to(equal(expectedEvents: [
            .next(10, .initial),
            .next(40, .autoupdate)
          ]))
        }

        it("has not started when view becomes invisible") {
          let intents = self.scheduler.createObserver(LoaderIntent.self)

          self.scheduler.createColdObservable([
            .next(10, .visibilityChanged(visible: true)),
            .next(20, .visibilityChanged(visible: false)),
            .next(30, .visibilityChanged(visible: true))
            ]).bind(to: self.collectionView.source.controlObserver)
            .disposed(by: self.disposeBag)

          self.collectionView.source.intentObservable.bind(to: intents).disposed(by: self.disposeBag)

          self.scheduler.scheduleAt(40, action: {
            self.scheduler.stop()
          })

          self.scheduler.start()

          expect(intents.events).to(equal(expectedEvents: [
            .next(10, .initial),
            .next(30, .appearance)
          ]))
        }

        it("has restarted after view becomes visible") {
          let intents = self.scheduler.createObserver(LoaderIntent.self)

          self.scheduler.createColdObservable([
            .next(10, .visibilityChanged(visible: true)),
            .next(50, .visibilityChanged(visible: false)),
            .next(60, .visibilityChanged(visible: true))
            ]).bind(to: self.collectionView.source.controlObserver)
            .disposed(by: self.disposeBag)

          self.collectionView.source.intentObservable.bind(to: intents).disposed(by: self.disposeBag)

          self.scheduler.scheduleAt(100, action: {
            self.scheduler.stop()
          })

          self.scheduler.start()

          expect(intents.events).to(equal(expectedEvents: [
            .next(10, .initial),
            .next(40, .autoupdate),
            .next(60, .appearance),
            .next(90, .autoupdate)
          ]))
        }
      }
    }
  }
}
