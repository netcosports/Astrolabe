//
//  Accessor.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 7/1/16.
//  Copyright © 2016 Netcosports. All rights reserved.
//

import UIKit

public protocol AccessorView: ContainerView {
  associatedtype Source: ReusableSource
  var source: Source { get }
}

public protocol Containerable: class {
  associatedtype Item
  var allItems: [Item] { get set }
}

public protocol Accessor: class {
  associatedtype Container: AccessorView
  typealias Source = Container.Source

  var source: Source { get }
  var containerView: Container { get }
  var sections: [Sectionable] { get set }
}

public extension Accessor {

  var source: Source {
    return containerView.source
  }

// FIXME: swift 4.2 compilator crashes when it's enabled,
// please return it back when it will be fixed
//  var sections: [Sectionable] {
//    get {
//      return source.sections
//    }
//
//    set {
//      source.sections = newValue
//    }
//  }

}

public extension Accessor where Self: Containerable {

  var allItems: [Sectionable] {
    get {
      return sections
    }

    set {
      sections = newValue
    }
  }

}
