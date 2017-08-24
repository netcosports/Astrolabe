//
//  Accessor.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 7/1/16.
//  Copyright © 2016 Netcosports. All rights reserved.
//

import UIKit

public protocol Accessor: class {
  associatedtype Source: ReusableSource
  typealias Container = Source.Container

  var source: Source { get }
  var sections: [Sectionable] { get set }
  var containerView: Container { get }
}

public extension Accessor where Self: UIViewController {

  var sections: [Sectionable] {
    get {
      return source.sections
    }

    set (newValue) {
      source.sections = newValue
    }
  }

  var containerView: Container {
    return source.containerView
  }
}
