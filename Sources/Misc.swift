//
//  Misc.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/9/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit

extension Array {

  public mutating func stableSort(by areInIncreasingOrder: (Iterator.Element, Iterator.Element) -> Bool?) {

    let sorted = self.enumerated().sorted { (one, another) -> Bool in
      if let result = areInIncreasingOrder(one.element, another.element) {
        return result
      } else {
        return one.offset < another.offset
      }
    }
    self = sorted.map{ $0.element }
  }
}

