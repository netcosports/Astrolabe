//
//  DiffCollectionViewController.swift
//  Demo
//
//  Created by Alexander Zhigulich on 4/29/19.
//  Copyright © 2019 NetcoSports. All rights reserved.
//

import UIKit
import Astrolabe
import RxSwift

class DiffCollectionViewController: UIViewController {

  fileprivate let visibilitySubject = PublishSubject<Bool>()

  let activityIndicator: UIActivityIndicatorView = {
    let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
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
  } ()

  let noDataLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 22)
    label.textColor = UIColor.black
    label.text = "No data"
    label.textAlignment = .center
    label.isHidden = true
    return label
  } ()

  let disposeBag = DisposeBag()
  let containerView = CollectionView<EventDrivenLoaderDecoratorSource<CollectionViewSource>>()
  let viewModel: DiffCollectionViewViewModel

  init() {
    let input = DiffCollectionViewViewModel.Input(
      source: containerView.source,
      visibility: visibilitySubject.asObservable(),
      isLoading: activityIndicator.rx.isAnimating,
      isErrorHidden: errorLabel.rx.isHidden,
      isNoDataHidden: noDataLabel.rx.isHidden
    )
    viewModel = DiffCollectionViewViewModel(input: input)
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
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

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    visibilitySubject.onNext(true)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    visibilitySubject.onNext(false)
  }

  func collectionViewLayout() -> UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    layout.sectionInset = UIEdgeInsets(top: 30.0, left: 0.0, bottom: 30, right: 0.0)
    return layout
  }
}
