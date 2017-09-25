//
//  ReusePagerViewController.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/3/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe

class ExampleReusePagerItemViewController: BaseCollectionViewController<CollectionViewSource>, ReusedPageData {

  var data: Int? {
    didSet {
      if let page = data {
        sections = [CollectionGenerator<TestCollectionCell, TestCollectionCell>().section(page: page, cells: 20)]
        containerView.reloadData()
      }
    }
  }
}

class ReusePagerViewController: BaseCollectionViewController<CollectionViewReusedPagerSource> {

  typealias CellView = ReusedPagerCollectionViewCell<ExampleReusePagerItemViewController>
  typealias Cell = CollectionCell<CellView>

  typealias PageStripCell = CollectionCell<TestCollectionCell>

  var pageStripCollectionView: CollectionView<CollectionViewSource>?

  override func loadView() {
    super.loadView()

    pageStripCollectionView = CollectionView<CollectionViewSource>()
    pageStripCollectionView?.source.hostViewController = self
    pageStripCollectionView?.collectionViewLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        return layout
      }()

    if #available(iOS 10.0, *) {
      containerView.isPrefetchingEnabled = false
    }
  }

  override func collectionViewLayout() -> UICollectionViewFlowLayout {
    return CollectionViewReusedPagerSource.defaultLayout
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    guard let pageStripCollectionView = pageStripCollectionView else { return }

    title = "Reuse Pager Source"

    edgesForExtendedLayout = []
    extendedLayoutIncludesOpaqueBars = false
    automaticallyAdjustsScrollViewInsets = false

    view.backgroundColor = .white
    view.addSubview(pageStripCollectionView)
    view.addSubview(containerView)

    pageStripCollectionView.snp.remakeConstraints { make in
      make.leading.trailing.top.equalToSuperview()
      make.height.equalTo(64)
    }

    containerView.snp.remakeConstraints { make in
      make.leading.trailing.bottom.equalToSuperview()
      make.top.equalTo(pageStripCollectionView.snp.bottom)
    }

    let datas = (1..<1024).map { $0 }
    let cells: [Cellable] = datas.map { Cell(data: $0) }

    source.sections = [Section(cells: cells)]
    containerView.reloadData()

    let pageStripCells: [Cellable] = datas.enumerated().map { index, _ in
      PageStripCell(data: TestViewModel("\(index)")) { [weak self] in
        self?.source.rx.selectedItem.onNext(index)
      }
    }
    pageStripCollectionView.source.sections = [Section(cells: pageStripCells)]
    pageStripCollectionView.reloadData()
  }
}
