//
//  BasicExampleCollectionViewController.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 3/23/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import UIKit
import Astrolabe
import SnapKit

class BasicExampleCollectionViewController: UIViewController {

  typealias Cell = CollectionCell<TestCollectionCell>
  let containerView = CollectionView<CollectionViewSource>()

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white
    containerView.collectionViewLayout = collectionViewLayout()
    view.addSubview(containerView)
    containerView.snp.remakeConstraints { make in
      make.edges.equalToSuperview()
    }

    let models = [
      TestViewModel("Test title 1"),
      TestViewModel("Test title 2"),
      TestViewModel("Test title 3"),
      TestViewModel("Test title 4"),
      TestViewModel("Test title 5"),
      TestViewModel("Test title 6")
    ]

    containerView.source.sections = [
      Section(cells: models.enumerated().map { index, data in
        Cell(data: data)
      }, minimumLineSpacing: 44.0, minimumInteritemSpacing: 44.0),
      Section(cells: models.enumerated().map { index, data in
        Cell(data: data)
      }, minimumLineSpacing: 44.0),
      Section(cells: models.enumerated().map { index, data in
        Cell(data: data)
      }, minimumInteritemSpacing: 44.0)
    ]
    containerView.reloadData()
  }

  func collectionViewLayout() -> UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    layout.sectionInset = UIEdgeInsets(top: 30.0, left: 0.0, bottom: 30, right: 0.0)
    return layout
  }
}
