//
//  BasicTimelineDataExampleCollectionViewController.swift
//  Demo
//
//  Created by Sergei Mikhan on 5/25/18.
//  Copyright © 2018 NetcoSports. All rights reserved.
//

import UIKit
import Astrolabe
import SnapKit
import RxSwift

class BasicTimelineDataExampleCollectionViewController: UIViewController, Loadable, Accessor {
  typealias Empty = CollectionCell<EmptyDataCollectionCell>
  
  let activityIndicator: UIActivityIndicatorView = {
    let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    activityIndicator.color = .black
    return activityIndicator
  } ()

  let containerView = CollectionView<LoaderDecoratorSource<CollectionViewSource>>()

  var sections: [Sectionable] {
    set {
      source.sections = newValue
    }

    get {
      return source.sections
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white
    containerView.source.loader = LoaderMediator(loader: self)
    containerView.source.loadingBehavior = [.initial, .paging, .autoupdate]
    containerView.source.startProgress = { [weak self] _ in
      self?.activityIndicator.startAnimating()
    }
    containerView.source.stopProgress = { [weak self] _ in
      self?.activityIndicator.stopAnimating()
    }
    containerView.source.noDataState = { state in
      return [Section(cells: [Empty(data: state)])]
    }

    containerView.collectionViewLayout = collectionViewLayout()

    view.addSubview(containerView)
    containerView.snp.remakeConstraints { make in
      make.edges.equalToSuperview()
    }

    view.addSubview(activityIndicator)
    activityIndicator.center = view.center
  }

  func collectionViewLayout() -> UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    layout.sectionInset = UIEdgeInsets(top: 30.0, left: 0.0, bottom: 30, right: 0.0)
    return layout
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    containerView.source.appear()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    containerView.source.disappear()
  }

  typealias Cell = CollectionCell<TestCollectionCell>
  typealias Item = TestViewModel
  var all: [Item] = []
  func load(for intent: LoaderIntent) -> Observable<[Item]?>? {

    var result: [Item]? = nil
    switch intent {
    case .page(let page):
      result = [
        TestViewModel("Test title \(page) - 1"),
        TestViewModel("Test title \(page) - 2"),
        TestViewModel("Test title \(page) - 3")
      ]
    default:
      result = [
        TestViewModel("Test title initials - 1"),
        TestViewModel("Test title initials - 2"),
        TestViewModel("Test title initials - 3")
      ]
    }
    return Observable<[Item]?>.just(result).delay(1.0, scheduler: MainScheduler.instance)
  }

  func merge(items: [Item]?, for intent: LoaderIntent) -> Observable<MergeResult?>? {
    guard let items = items else { return nil }
    var mergedItems = all.filter { !items.contains($0) }
    mergedItems.append(contentsOf: items)
    mergedItems.sort()
    all = mergedItems
    return .just((items: mergedItems, status: .hasUpdates))
  }

  func apply(mergeResult: MergeResult?, for intent: LoaderIntent) {
    guard let cells = mergeResult?.items?.map({ Cell(data: $0) }) else { return }
    sections = [Section(cells: cells, page: intent.page)]
    containerView.reloadData()
  }
}
