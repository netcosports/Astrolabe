//
//  Common.swift
//  Astrolabe
//
//  Created by Vladimir Burdukov on 10/2/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import Gnomon
import Astrolabe
import SwiftyJSON

struct TestModel1: JSONModel {

  let id: String

  init(_ json: JSON) throws {
    guard let _id = json["id1"].string else { throw "can't parse id" }
    id = _id
  }

}

struct TestModel2: JSONModel {

  let id: String

  init(_ json: JSON) throws {
    guard let _id = json["id2"].string else { throw "can't parse id" }
    id = _id
  }

}

struct TestModel3: JSONModel {

  let id: String

  init(_ json: JSON) throws {
    guard let _id = json["id3"].string else { throw "can't parse id" }
    id = _id
  }

}

struct TestModel4: JSONModel {

  let id: String

  init(_ json: JSON) throws {
    guard let _id = json["id3"].string else { throw "can't parse id" }
    id = _id
  }

}

class TestViewCell: CollectionViewCell, Reusable {

  struct ViewModel {
    let id: String

    init(_ id: String) {
      self.id = id
    }

    init(_ model: TestModel1) {
      id = model.id
    }

    init(_ model: TestModel2) {
      id = model.id
    }

    init(_ model: TestModel3) {
      id = model.id
    }

    init(_ model: TestModel4, context: String) {
      id = context + model.id
    }
  }

  var title: String?

  func setup(with data: ViewModel) {
    title = data.id
  }

  static func size(for data: ViewModel, containerSize: CGSize) -> CGSize {
    return .zero
  }

}
