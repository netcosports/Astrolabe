//
//  Common.swift
//  Astrolabe
//
//  Created by Vladimir Burdukov on 10/2/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import SwiftyJSON

@testable import Gnomon
@testable import Astrolabe

struct TestModel1: DecodableModel {

  let id: String

  private enum CodingKeys: String, CodingKey {
    case id = "id1"
  }

}

struct TestModel2: DecodableModel {

  let id: String

  private enum CodingKeys: String, CodingKey {
    case id = "id2"
  }

}

struct TestModel3: DecodableModel {

  let id: String

  private enum CodingKeys: String, CodingKey {
    case id = "id3"
  }

}

struct TestModel4: DecodableModel {

  let id: String

  private enum CodingKeys: String, CodingKey {
    case id = "id4"
  }

}

class TestViewCell: CollectionViewCell, Reusable {

  struct ViewModel {
    let id: String

    init(_ id: String) {
      self.id = id
    }

    init(_ model: TestModel1) {
      self.id = model.id
    }

    init(_ model: TestModel2) {
      self.id = model.id
    }

    init(_ model: TestModel3) {
      self.id = model.id
    }

    init(_ model: TestModel4, context: String) {
      self.id = context + model.id
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
