//
//  BasicTimelineExampleCollectionViewController.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 5/18/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import UIKit
import Astrolabe
import SnapKit
import RxSwift

class BasicTimelineExampleCollectionViewController: UIViewController {

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

  let containerView = CollectionView<TimelineLoaderDecoratorSource<CollectionViewSource>>()

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white
    containerView.source.loader = self
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
    layout.minimumLineSpacing = 60
    layout.minimumInteritemSpacing = 60
    layout.sectionInset = UIEdgeInsets(top: 60.0, left: 60.0, bottom: 60, right: 60.0)
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
}

extension BasicTimelineExampleCollectionViewController: Loader {

  func performLoading(intent: LoaderIntent) -> SectionObservable? {

    var result: [Sectionable]? = nil
    switch intent {
    case .page(let page):
      let cells: [Cellable] = [
        Cell(data: TestViewModel("page \(page - 1) - 1"), id: "\(page - 1)-1"),
        Cell(data: TestViewModel("page \(page) - 1"), id: "\(page)-1"),
        Cell(data: TestViewModel("page \(page) - 2"), id: "\(page)-2"),
        Cell(data: TestViewModel("page \(page) - 3"), id: "\(page)-3")
      ]
      result = [Section(cells: cells, page: page)]
    case .autoupdate:
      let cells: [Cellable] = [
        Cell(data: TestViewModel("Auto - 1 \(Date())"), id: "\(0)-1"),
        Cell(data: TestViewModel("Auto - 2 \(Date())"), id: "\(0)-2"),
        Cell(data: TestViewModel("Auto - 3 \(Date())"), id: "\(0)-3"),
        Cell(data: TestViewModel("Auto - 1 \(Date())"), id: "\(1)-1"),
        Cell(data: TestViewModel("Auto - 2 \(Date())"), id: "\(1)-2"),
        Cell(data: TestViewModel("Auto - 3 \(Date())"), id: "\(1)-3")
      ]
      result = [Section(cells: cells, page: 0)]
    default:
      let cells: [Cellable] = [
        Cell(data: TestViewModel("Init - 1"), id: "\(0)-1"),
        Cell(data: TestViewModel("Init - 2"), id: "\(0)-2"),
        Cell(data: TestViewModel("Init - 3"), id: "\(0)-3")
      ]
      result = [Section(cells: cells, page: 0)]
    }

    return SectionObservable.just(result).delay(1.0, scheduler: MainScheduler.instance)
  }
}
