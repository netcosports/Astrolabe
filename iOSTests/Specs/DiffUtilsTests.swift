//
//  DiffUtilsTests.swift
//  iOSTests
//
//  Created by Alexander Zhigulich on 4/22/19.
//  Copyright © 2019 NetcoSports. All rights reserved.
//

import Quick
import Nimble
import Astrolabe

class DiffUtilsTests: QuickSpec {

  struct SectionParams {
    var id: String = ""
    var cellParams = [CellParams]()
  }

  struct CellParams {
    var id: String = ""
    var type: CellType = .cell
    var data: Int?
  }

  fileprivate var emptySectionables = [Sectionables]()

  fileprivate func sectionableWithParams(
    _ params: [SectionParams]
  ) -> [Sectionable] {

    return [Sectionable]()
  }

  override func spec() {

    describe("difference") {

      context("when invalid sections") {

        it("with empty ids") {

          let old = [Sectionable]()
          let new =
        }
      }

      context("when invalid cells") {

        it("with empty ids") {


        }

        it("without equals closures") {


        }
      }

      context("when data valid") {


      }
    }
  }
}
