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

class BaseViewController<T: UIView>: UIViewController, Accessor where T: AccessorView {

  let containerView = T()

  override func loadView() {
    super.loadView()
    source.hostViewController = self
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "\(type(of: self))"

    view.backgroundColor = .white
    view.addSubview(containerView)
    containerView.snp.remakeConstraints { make in
      make.edges.equalToSuperview()
    }

    if let cells = cells() {
      sections = [Section(cells: cells)]
    } else if let sections = allSections() {
      self.sections = sections
    }

    containerView.reloadData()
  }

  var sections: [Sectionable] {
    set {
      source.sections = newValue
    }

    get {
      return source.sections
    }
  }

  func cells() -> [Cellable]? {
    return nil
  }

  func allSections() -> [Sectionable]? {
    return nil
  }
}

class BaseTableViewController<T: TableViewSource>: BaseViewController<TableView<T>> { }

class BaseCollectionViewController<T: CollectionViewSource>: BaseViewController<CollectionView<T>> {

  override func loadView() {
    super.loadView()
    containerView.collectionViewLayout = collectionViewLayout()
  }

  func collectionViewLayout() -> UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    layout.sectionInset = UIEdgeInsets(top: 30.0, left: 0.0, bottom: 30, right: 0.0)
    return layout
  }
}

class BaseLoaderViewController<T: UIView>: BaseViewController<T>, Loadable, Containerable where T: AccessorView, T.Source: LoaderReusableSource {

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

  override func loadView() {
    super.loadView()

    containerView.source.loadingBehavior = [.initial, .paging]
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

    containerView.source.appear()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    containerView.source.disappear()
  }

  func load(for intent: LoaderIntent) -> Observable<[Sectionable]?>? {
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

  func apply(mergeResult: MergeResult?, for intent: LoaderIntent) {
    guard let items = mergeResult?.items else { return }
    source.sections = items
    source.registerCellsForSections()
    source.containerView?.reloadData()
  }

  func sections(for page: Int) -> [Sectionable]? {
    return []
  }
}

class BaseLoaderTableViewController<T: LoaderReusableSource>: BaseLoaderViewController<TableView<T>> where T.Container == UITableView { }

class BaseLoaderCollectionViewController<T: LoaderReusableSource>: BaseLoaderViewController<CollectionView<T>> where T.Container == UICollectionView {

  override func loadView() {
    super.loadView()
    containerView.collectionViewLayout = collectionViewLayout()
  }

  func collectionViewLayout() -> UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    layout.sectionInset = UIEdgeInsets(top: 30.0, left: 0.0, bottom: 30, right: 0.0)
    return layout
  }
}
