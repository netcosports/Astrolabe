//
//  BasicExampleViewController.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 3/23/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import UIKit
import Astrolabe
import SnapKit
import RxSwift

class BasicDataExampleCollectionViewController: UIViewController, Loadable, Accessor, Containerable {

  typealias Cell = CollectionCell<TestCollectionCell>
  typealias Header = CollectionCell<TestCollectionHeaderCell>
  typealias Empty = CollectionCell<EmptyDataCollectionCell>

  let activityIndicator: UIActivityIndicatorView = {
    let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    activityIndicator.color = .black
    return activityIndicator
  } ()

  let containerView = CollectionView<LoaderDecoratorSource<CollectionViewSource>>()

  var sections: [Sectionable] {
    set {
      source.sections = sections
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
    containerView.source.noDataCell = { state in
      return Empty(data: state)
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

  typealias Item = Sectionable
  func load(for intent: LoaderIntent) -> Observable<[Sectionable]?>? {

    let models: [TestViewModel]
    switch intent {
    case .page(let page):
      models = [
        TestViewModel("Test title \(page) - 1"),
        TestViewModel("Test title \(page) - 2"),
        TestViewModel("Test title \(page) - 3")
      ]
    default:
      models = [
        TestViewModel("Test title initials - 1"),
        TestViewModel("Test title initials - 2"),
        TestViewModel("Test title initials - 3")
      ]
    }

    let cells = models.map { Cell(data: $0) }
    let header: Cellable = Header(data: TestViewModel("Header"), type: CellType.header)
    let footer: Cellable = Header(data: TestViewModel("Footer"), type: CellType.footer)
    let section = MultipleSupplementariesSection(supplementaries: [header, footer], cells: cells, page: intent.page)

    return SectionObservable.just([section]).delay(1.0, scheduler: MainScheduler.instance)
  }
}
