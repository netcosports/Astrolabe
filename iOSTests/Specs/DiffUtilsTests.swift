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

  fileprivate var emptySectionables = [Sectionable]()

  fileprivate func sectionablesWithParams(
    _ params: [SectionParams]
  ) -> [Sectionable] {

    return params.map { sectionParam in
      let section = SectionStub()
      section.id = sectionParam.id
      section.cells = sectionParam.cellParams.map { cellParam in
        return CellStub(id: cellParam.id, type: cellParam.type, data: cellParam.data)
      }
      return section
    }
  }

  fileprivate class CellStub: Cellable, DataHodler {

    typealias Data = Int?

    var data: Int?

    var dataEquals: ((Int?, Int?) -> Bool)?

    init(id: String, type: CellType, data: Int?, dataEquals: ((Int?, Int?) -> Bool)? = { $0 == $1 }) {
      self.id = id
      self.type = type
      self.data = data
      self.dataEquals = dataEquals
      equals = {
        if $0.id.isEmpty || self.id.isEmpty {
          return false
        } else {
          return self.id == $0.id
        }
      }
    }

    func register<T>(in container: T) where T : ContainerView {
      // not used
      fatalError()
    }

    func instance<T1, T2>(for container: T1, index: IndexPath) -> T2 where T1 : ContainerView, T2 : ReusableView {
      // not used
      fatalError()
    }

    func setup<T>(with cell: T) where T : ReusableView {
      // not used
      fatalError()
    }

    func size<T>(with container: T) -> CGSize where T : ContainerView {
      // not used
      fatalError()
    }

    var type: CellType

    var click: ClickClosure?

    var equals: EqualsClosure<Cellable>?

    var page: Int = 0

    var id: String = ""
  }

  fileprivate class SectionStub: Sectionable {

    init() {
      equals = {
        if $0.id.isEmpty || self.id.isEmpty {
          return false
        } else {
          return self.id == $0.id
        }
      }
    }

    var supplementaryTypes: [CellType] = []

    func supplementary(for type: CellType) -> Cellable? {
      // not used
      fatalError()
    }

    var cells: [Cellable] = []

    var equals: EqualsClosure<Sectionable>?

    var page: Int = 0

    var inset: UIEdgeInsets?

    var minimumLineSpacing: CGFloat?

    var minimumInteritemSpacing: CGFloat?

    var id: String = ""
  }

  override func spec() {

    describe("difference") {

      context("when sections") {

        context("with empty ids") {

          let sectionParams = [
            SectionParams(id: "", cellParams: []),
            SectionParams(id: "1", cellParams: [])
          ]

          it("for old sections") {

            let old = self.sectionablesWithParams(sectionParams)
            let new = self.emptySectionables

            expect { try DiffUtils.diffThrow(newSections: new, oldSections: old) }.to(throwError())
          }

          it("for new sections") {

            let old = [Sectionable]()
            let new = self.sectionablesWithParams(sectionParams)

            expect { try DiffUtils.diffThrow(newSections: new, oldSections: old) }.to(throwError())
          }

          it("for both sections") {

            let old = self.sectionablesWithParams(sectionParams)
            let new = self.sectionablesWithParams(sectionParams)

            expect { try DiffUtils.diffThrow(newSections: new, oldSections: old) }.to(throwError())
          }
        }

        context("are valid") {

          context("when cells") {

            it("with empty ids") {

              let old = self.emptySectionables
              let new = self.sectionablesWithParams(
                [
                  SectionParams(
                    id: "0",
                    cellParams: [
                      CellParams(id: "", type: .cell, data: 0),
                      CellParams(id: "1", type: .cell, data: 1)
                    ]),
                  SectionParams(
                    id: "1",
                    cellParams: [
                      CellParams(id: "1", type: .cell, data: 1),
                      CellParams(id: "", type: .cell, data: 0)
                    ])
                ]
              )

              expect { try DiffUtils.diffThrow(newSections: new, oldSections: old) }.to(throwError())
            }

            it("without equals closures") {


            }

            context("are valid") {

              context("with several supplementary cells") {

                it("no changes") {

                  let sections = [
                    SectionParams(
                      id: "0",
                      cellParams: [
                        CellParams(id: "???", type: .header, data: 0),
                        CellParams(id: "0", type: .cell, data: 0),
                        CellParams(id: "1", type: .cell, data: 1),
                        CellParams(id: "???", type: .footer, data: 0)
                      ]),
                    SectionParams(
                      id: "1",
                      cellParams: [
                        CellParams(id: "???", type: .header, data: 0),
                        CellParams(id: "0", type: .cell, data: 1),
                        CellParams(id: "1", type: .cell, data: 0),
                        CellParams(id: "???", type: .footer, data: 0)
                      ])
                  ]
                  let old = self.sectionablesWithParams(sections)
                  let new = self.sectionablesWithParams(sections)

                  expect(DiffUtils.diff(newSections: new, oldSections: old)).to(beNil())
                }

                it("inserting section") {

                  let old = self.sectionablesWithParams(
                    [
                      SectionParams(
                        id: "0",
                        cellParams: [
                          CellParams(id: "???", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "???", type: .footer, data: 0)
                        ])
                    ]
                  )
                  let new = self.sectionablesWithParams(
                    [
                      SectionParams(
                        id: "0",
                        cellParams: [
                          CellParams(id: "???", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "???", type: .footer, data: 0)
                        ]),
                      SectionParams(
                        id: "1",
                        cellParams: [
                          CellParams(id: "???", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 1),
                          CellParams(id: "1", type: .cell, data: 0),
                          CellParams(id: "???", type: .footer, data: 0)
                        ])
                    ]
                  )

                  let context = DiffUtils.diff(newSections: new, oldSections: old)
                  expect(context?.insertedSections) == IndexSet(integer: 1)
                  expect(context?.deletedSections) == IndexSet()
                  expect(context?.inserted) == [IndexPath]()
                  expect(context?.deleted) == [IndexPath]()
                  expect(context?.updated) == [IndexPath]()
                }

                it("deleting section") {

                  let old = self.sectionablesWithParams(
                    [
                      SectionParams(
                        id: "0",
                        cellParams: [
                          CellParams(id: "???", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "???", type: .footer, data: 0)
                        ]),
                      SectionParams(
                        id: "1",
                        cellParams: [
                          CellParams(id: "???", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 1),
                          CellParams(id: "1", type: .cell, data: 0),
                          CellParams(id: "???", type: .footer, data: 0)
                        ])
                    ]
                  )
                  let new = self.sectionablesWithParams(
                    [
                      SectionParams(
                        id: "1",
                        cellParams: [
                          CellParams(id: "0", type: .cell, data: 1),
                          CellParams(id: "1", type: .cell, data: 0),
                          CellParams(id: "???", type: .footer, data: 0)
                        ])
                    ]
                  )

                  let context = DiffUtils.diff(newSections: new, oldSections: old)
                  expect(context?.insertedSections) == IndexSet()
                  expect(context?.deletedSections) == IndexSet(integer: 0)
                  expect(context?.inserted) == [IndexPath]()
                  expect(context?.deleted) == [IndexPath]()
                  expect(context?.updated) == [IndexPath]()
                }

                it("inserting cell") {

                  let old = self.sectionablesWithParams(
                    [
                      SectionParams(
                        id: "0",
                        cellParams: [
                          CellParams(id: "???", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "???", type: .footer, data: 0)
                        ]),
                      SectionParams(
                        id: "1",
                        cellParams: [
                          CellParams(id: "???", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 1),
                          CellParams(id: "1", type: .cell, data: 0)
                        ])
                    ]
                  )
                  let new = self.sectionablesWithParams(
                    [
                      SectionParams(
                        id: "0",
                        cellParams: [
                          CellParams(id: "???", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "", type: .footer, data: 1) // inserted
                        ]),
                      SectionParams(
                        id: "1",
                        cellParams: [
                          CellParams(id: "0", type: .cell, data: 1),
                          CellParams(id: "1", type: .cell, data: 0),
                          CellParams(id: "", type: .header, data: 0), // inserted
                          CellParams(id: "2", type: .cell, data: 2) // inserted
                        ])
                    ]
                  )

                  let context = DiffUtils.diff(newSections: new, oldSections: old)
                  expect(context?.insertedSections) == IndexSet()
                  expect(context?.deletedSections) == IndexSet()
                  expect(context?.inserted) == [IndexPath(row: 2, section: 1)]
                  expect(context?.deleted) == [IndexPath]()
                  expect(context?.updated) == [IndexPath]()
                }

                it("deleting cell") {

                  let old = self.sectionablesWithParams(
                    [
                      SectionParams(
                        id: "0",
                        cellParams: [
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1), // deleted
                          CellParams(id: "", type: .footer, data: 0) // deleted
                        ]),
                      SectionParams(
                        id: "1",
                        cellParams: [
                          CellParams(id: "0", type: .cell, data: 1),
                          CellParams(id: "1", type: .cell, data: 0),
                          CellParams(id: "", type: .header, data: 0), // deleted
                          CellParams(id: "2", type: .cell, data: 2)
                        ])
                    ]
                  )
                  let new = self.sectionablesWithParams(
                    [
                      SectionParams(
                        id: "0",
                        cellParams: [
                          CellParams(id: "0", type: .cell, data: 0),
                        ]),
                      SectionParams(
                        id: "1",
                        cellParams: [
                          CellParams(id: "0", type: .cell, data: 1),
                          CellParams(id: "1", type: .cell, data: 0),
                          CellParams(id: "2", type: .cell, data: 2)
                        ])
                    ]
                  )

                  let context = DiffUtils.diff(newSections: new, oldSections: old)
                  expect(context?.insertedSections) == IndexSet()
                  expect(context?.deletedSections) == IndexSet()
                  expect(context?.inserted) == [IndexPath]()
                  expect(context?.deleted) == [IndexPath(row: 1, section: 0)]
                  expect(context?.updated) == [IndexPath]()
                }

                it("updating cell") {

                }
              }
            }
          }
        }
      }
    }
  }
}
