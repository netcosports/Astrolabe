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

class BasicDataExampleCollectionViewController: UIViewController, Loadable, Accessor {

  typealias Cell = CollectionCell<TestCollectionCell>

  let activityIndicator: UIActivityIndicatorView = {
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    activityIndicator.color = .black
    return activityIndicator
  } ()

  let errorLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 22)
    label.textColor = UIColor.black
    label.text = "Error"
    label.textAlignment = .center
    label.isHidden = true
    return label
  }()

  let noDataLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 22)
    label.textColor = UIColor.black
    label.text = "No data"
    label.textAlignment = .center
    label.isHidden = true
    return label
  }()

  let containerView = CollectionView<LoaderDecoratorSource<CollectionViewSource>>()

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
    containerView.source.updateEmptyView = { [weak self] state in
      guard let strongSelf = self else { return }

      switch state {
      case .empty:
        strongSelf.noDataLabel.isHidden = false
        strongSelf.errorLabel.isHidden = true
      case .error:
        strongSelf.noDataLabel.isHidden = true
        strongSelf.errorLabel.isHidden = false
      default:
        strongSelf.noDataLabel.isHidden = true
        strongSelf.errorLabel.isHidden = true
      }
    }
    containerView.collectionViewLayout = collectionViewLayout()

    view.addSubview(containerView)
    containerView.snp.remakeConstraints { make in
      make.edges.equalToSuperview()
    }

    view.addSubview(activityIndicator)
    view.addSubview(noDataLabel)
    view.addSubview(errorLabel)
    noDataLabel.sizeToFit()
    errorLabel.sizeToFit()
    activityIndicator.center = view.center
    noDataLabel.center = view.center
    errorLabel.center = view.center
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

    var result: [Sectionable]? = nil
    switch intent {
    case .page(let page):
      let models = [
        TestViewModel("Test title \(page) - 1"),
        TestViewModel("Test title \(page) - 2"),
        TestViewModel("Test title \(page) - 3")
      ]
      let cells = models.map { Cell(data: $0) }

      result = [Section(cells: cells, page: page)]
    default:
      let models = [
        TestViewModel("Test title initials - 1"),
        TestViewModel("Test title initials - 2"),
        TestViewModel("Test title initials - 3")
      ]
      let cells = models.map { Cell(data: $0) }

      result = [Section(cells: cells, page: 0)]
    }

    return SectionObservable.just(result).delay(1.0, scheduler: MainScheduler.instance)
  }
}
