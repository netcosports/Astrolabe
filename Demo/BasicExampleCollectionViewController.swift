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

  var source: CollectionViewSource?

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white
    let source = CollectionViewSource(hostViewController: self, layout: collectionViewLayout())
    view.addSubview(source.containerView)
    source.containerView.snp.remakeConstraints { make in
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

    source.sections = [
      Section(cells: models.map { Cell(data: $0) }, minimumLineSpacing: 44.0, minimumInteritemSpacing: 44.0),
      Section(cells: models.map { Cell(data: $0) }, minimumLineSpacing: 44.0),
      Section(cells: models.map { Cell(data: $0) }, minimumInteritemSpacing: 44.0)
    ]
    source.containerView.reloadData()

    self.source = source
  }

  func collectionViewLayout() -> UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    layout.sectionInset = UIEdgeInsets(top: 30.0, left: 0.0, bottom: 30, right: 0.0)
    return layout
  }
}
