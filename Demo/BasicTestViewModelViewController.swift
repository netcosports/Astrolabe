//
//  BasicTestViewModelViewController.swift
//  Demo
//
//  Created by Sergei Mikhan on 5/28/18.
//  Copyright © 2018 NetcoSports. All rights reserved.
//

import UIKit
import Astrolabe
import RxSwift

class BasicTestViewModelViewController: UIViewController, Accessor {
  typealias Empty = CollectionCell<EmptyDataCollectionCell>
  
  let activityIndicator: UIActivityIndicatorView = {
    let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    activityIndicator.color = .black
    return activityIndicator
  } ()

  let containerView = CollectionView<LoaderDecoratorSource<CollectionViewSource>>()
  let viewModel = BasicTestViewModel()
  let disposeBag = DisposeBag()

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

    containerView.source.loader = LoaderMediator(loader: viewModel)
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

    viewModel.sectionPubliser.subscribe(onNext: { [weak self] sections in
      self?.sections = sections
      self?.containerView.reloadData()
    }).disposed(by: disposeBag)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    containerView.source.appear()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    containerView.source.disappear()
  }

  func collectionViewLayout() -> UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    layout.sectionInset = UIEdgeInsets(top: 30.0, left: 0.0, bottom: 30, right: 0.0)
    return layout
  }
}
