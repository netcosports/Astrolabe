//
//  PagerViewController.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/3/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe

class PagerViewController: BaseCollectionViewController<CollectionViewPagerSource>, CollectionViewPager {

  override func loadView() {
    super.loadView()
    source.pager = self
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    edgesForExtendedLayout = []
    extendedLayoutIncludesOpaqueBars = false
    automaticallyAdjustsScrollViewInsets = false

    title = "Pager Source"

    view.backgroundColor = .white
    view.addSubview(containerView)
    containerView.snp.remakeConstraints { make in
      make.edges.equalToSuperview()
    }

    source.reloadData()
  }

  override func collectionViewLayout() -> UICollectionViewFlowLayout {
    return CollectionViewPagerSource.layout
  }

  var pages: [Page] {
    return [
      Page(controller: TableSourceViewController(), id: "source"),
      Page(controller: TableLoaderSourceViewController(), id: "loader"),
      Page(controller: CollectionLoaderSourceViewController(), id: "collection_loader")
    ]
  }
}
