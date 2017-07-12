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

  override func createSource() -> Source? {
    return CollectionViewSource(hostViewController: self, layout: collectionViewLayout())
  }

  var data: Int? {
    didSet {
      if let page = data {
        sections = [CollectionGenerator<TestCollectionCell, TestCollectionCell>().section(page: page, cells: 20)]
        containerView.reloadData()
      }
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    print("will appear \(data ?? Int.min)")
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    print("did appear \(data ?? Int.min)")
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    print("will disappear \(data ?? Int.min)")
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    print("did disappear \(data ?? Int.min)")
  }

}

class ReusePagerViewController: UIViewController, Accessor {

  typealias Source = CollectionViewReusedPagerSource
  typealias CellView = ReusedPagerCollectionViewCell<ExampleReusePagerItemViewController>
  typealias Cell = CollectionCell<CellView>

  typealias PageStripCell = CollectionCell<TestCollectionCell>
  typealias PageStripSource = CollectionViewSource

  var pageStripSource: PageStripSource!
  var source: Source!

  override func loadView() {
    super.loadView()

    source = Source(hostViewController: self)
    pageStripSource = PageStripSource(hostViewController: self, layout: {
      let layout = UICollectionViewFlowLayout()
      layout.scrollDirection = .horizontal
      layout.minimumLineSpacing = 10
      layout.minimumInteritemSpacing = 10
      return layout
    }())

    if #available(iOS 10.0, *) {
      containerView.isPrefetchingEnabled = false
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Reuse Pager Source"

    edgesForExtendedLayout = []
    extendedLayoutIncludesOpaqueBars = false
    automaticallyAdjustsScrollViewInsets = false

    view.backgroundColor = .white
    view.addSubview(pageStripSource.containerView)
    view.addSubview(containerView)

    pageStripSource.containerView.snp.remakeConstraints { make in
      make.leading.trailing.top.equalToSuperview()
      make.height.equalTo(64)
    }

    containerView.snp.remakeConstraints { make in
      make.leading.trailing.bottom.equalToSuperview()
      make.top.equalTo(pageStripSource.containerView.snp.bottom)
    }

    let datas = (1..<1024).map { $0 }
    let cells: [Cellable] = datas.map { Cell(data: $0) }

    sections = [Section(cells: cells)]
    containerView.reloadData()

    let pageStripCells: [Cellable] = datas.enumerated().map { index, _ in
      PageStripCell(data: TestViewModel("\(index)")) {
        self.source.rx.selectedItem.onNext(index)
      }
    }
    pageStripSource.sections = [Section(cells: pageStripCells)]
    pageStripSource.containerView.reloadData()
  }
}
