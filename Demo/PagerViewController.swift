//
//  PagerViewController.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/3/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe

class PagerViewController: UIViewController, CollectionViewPager {
  typealias Source = CollectionViewPagerSource
  var source: Source?

  override func loadView() {
    super.loadView()

    source = Source(hostViewController: self, pager: self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    guard let source = source else { return }

    edgesForExtendedLayout = []
    extendedLayoutIncludesOpaqueBars = false
    automaticallyAdjustsScrollViewInsets = false

    title = "Pager Source"

    view.backgroundColor = .white
    view.addSubview(source.containerView)
    source.containerView.snp.remakeConstraints { make in
      make.edges.equalToSuperview()
    }

    source.reloadData()
  }

  var pages: [Page] {
    return [
      Page(controller: TableSourceViewController(), id: "source"),
      Page(controller: TableLoaderSourceViewController(), id: "loader"),
      Page(controller: TableStyledSourceViewController(), id: "styled")
    ]
  }
}
