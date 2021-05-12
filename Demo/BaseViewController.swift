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
