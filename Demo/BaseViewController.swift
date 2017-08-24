//
//  BaseViewController.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/10/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import UIKit
import Astrolabe
import RxSwift

extension String: Error {
}

enum LoaderResult {
  case infinitePaging
  case emptyPage1
  case emptyPage4
  case errorPage1
  case errorPage4
}

class BaseViewController<T: ReusableSource>: UIViewController, Accessor {

  typealias Source = T
  var source = Source()

  override func loadView() {
    super.loadView()
    if let source = createSource() {
      self.source = source
    }
    source.hostViewController = self
  }

  func createSource() -> Source? {
    return nil
  }

  func container() -> UIView? {
    return nil
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "\(type(of: self))"

    view.backgroundColor = .white
    view.addSubview(container()!)
    container()!.snp.remakeConstraints { make in
      make.edges.equalToSuperview()
    }

    if let cells = cells() {
      sections = [Section(cells: cells)]
    } else if let sections = sections() {
      self.sections = sections
    }

    containerView.reloadData()
  }

  func cells() -> [Cellable]? {
    return nil
  }

  func sections() -> [Sectionable]? {
    return nil
  }
}

class BaseTableViewController<T: TableViewSource>: BaseViewController<T> {

  override func container() -> UIView? {
    return source.containerView
  }
}

class BaseCollectionViewController<T: CollectionViewSource>: BaseViewController<T> {

  func collectionViewLayout() -> UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    layout.sectionInset = UIEdgeInsets(top: 30.0, left: 0.0, bottom: 30, right: 0.0)
    return layout
  }

  override func container() -> UIView? {
    return source.containerView
  }
}

class BaseLoaderViewController<T: ReusableSource>: BaseViewController<T>, Loader {

  convenience init(type: LoaderResult) {
    self.init()
    self.type = type
  }

  var type: LoaderResult = .infinitePaging

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

  typealias LoaderSource = LoaderDecoratorSource<T>

  var loaderSource: LoaderSource!

  override func loadView() {
    super.loadView()
    loaderSource = LoaderSource(source: source, loader: self)

    loaderSource.loadingBehavior = [.initial, .paging]
    loaderSource.startProgress = { [weak self] _ in
      self?.activityIndicator.startAnimating()
    }
    loaderSource.stopProgress = { [weak self] _ in
      self?.activityIndicator.stopAnimating()
    }

    loaderSource.updateEmptyView = { [weak self] state in
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
  }

  override func viewDidLoad() {
    super.viewDidLoad()

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

    loaderSource.appear()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    loaderSource.disappear()
  }

  func performLoading(intent: LoaderIntent) -> SectionObservable? {
    var currentPage = 1
    var result: [Sectionable]? = nil
    switch intent {
    case .page(let page):
      currentPage = page
      result = sections(for: page)
    default:
      result = sections(for: 1)
    }

    switch type {
    case .infinitePaging:
      return SectionObservable.just(result).delay(1.0, scheduler: MainScheduler.instance)
    case .emptyPage1:
      return SectionObservable.just([]).delay(1.0, scheduler: MainScheduler.instance)
    case .errorPage1:
      return SectionObservable.just([]).delay(1.0, scheduler: MainScheduler.instance).flatMapLatest({ _ in
        return SectionObservable.error("Error")
      })
    case .emptyPage4:
      if currentPage > 3 {
        return SectionObservable.just([]).delay(1.0, scheduler: MainScheduler.instance)
      } else {
        return SectionObservable.just(result).delay(1.0, scheduler: MainScheduler.instance)
      }
    case .errorPage4:
      if currentPage > 3 {
        return SectionObservable.just([]).delay(1.0, scheduler: MainScheduler.instance).flatMapLatest({ _ in
          return SectionObservable.error("Error")
        })
      } else {
        return SectionObservable.just(result).delay(1.0, scheduler: MainScheduler.instance)
      }
    }
  }

  func sections(for page: Int) -> [Sectionable]? {
    return []
  }
}

class BaseLoaderTableViewController<T: TableViewSource>: BaseLoaderViewController<T> {

  override func container() -> UIView? {
    return source.containerView
  }
}

class BaseLoaderCollectionViewController<T: CollectionViewSource>: BaseLoaderViewController<T> {

  func collectionViewLayout() -> UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    layout.sectionInset = UIEdgeInsets(top: 30.0, left: 0.0, bottom: 30, right: 0.0)
    return layout
  }

  override func container() -> UIView? {
    return source.containerView
  }
}
