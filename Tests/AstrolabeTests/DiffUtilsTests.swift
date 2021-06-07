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

import UIKit

class DiffUtilsTests: QuickSpec {

  struct SectionParams: Hashable {
    var id: String = ""
    var cellParams = [CellParams]()
    var supplyParams = [CellParams]()
  }

  struct CellParams: Hashable {
    func hash(into hasher: inout Hasher) {
      hasher.combine(id)
      hasher.combine(type)
      hasher.combine(data)
    }

    static func == (lhs: DiffUtilsTests.CellParams, rhs: DiffUtilsTests.CellParams) -> Bool {
      return lhs.id == rhs.id &&
             lhs.type == rhs.type &&
             lhs.data == rhs.data
    }

    var id: String = ""
    var type: CellType = .cell
    var data: Int = -1
    var dataEquals: EqualsClosure<Cellable>?
  }

  fileprivate var emptySectionables = [Sectionable]()
  //fileprivate let simpleDataEquals: EqualsClosure<Cellable> = { $0 == $1 }

  fileprivate func sectionablesWithParams(
    _ params: [SectionParams]
  ) -> [Sectionable] {

    return params.map { sectionParam in
      let section = SectionStub()
      section.id = sectionParam.id
      section.supplementaryTypes = sectionParam.supplyParams.map { $0.type }
      section.supplementaryCells = sectionParam.supplyParams.map { cellParam in
        return CellStub(id: cellParam.id, type: cellParam.type, data: cellParam.data)
      }
      section.cells = sectionParam.cellParams.map { cellParam in
        return CellStub(id: cellParam.id, type: cellParam.type, data: cellParam.data)
      }
      return section
    }
  }

  fileprivate class CellStub: DataHodler<Int>, Cellable {

    init(id: String, type: CellType, data: Int) {
      self.type = type
      super.init(data: data)
      self.id = id
      self.equals = {
        guard !$0.id.isEmpty && !self.id.isEmpty else {
          assertionFailure("id of a cell must not be empty string")
          return false
        }
        guard let anotherCell = $0 as? Self else {
          return false
        }
        return anotherCell.data == self.data
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
      self.equals = {
        guard !$0.id.isEmpty && !self.id.isEmpty else {
          assertionFailure("id of a section must not be empty string")
          return false
        }
        return self.id == $0.id
      }
    }

    var supplementaryTypes: [CellType] = []

    var supplementaryCells: [Cellable] = []


    func supplementaries(for type: CellType) -> [Cellable] {
      return supplementaryCells.filter { $0.type == type }
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

        it("with empty ids") {

          let old = self.sectionablesWithParams(
            [
              SectionParams(id: "", cellParams: [], supplyParams: []),
              SectionParams(id: "1", cellParams: [], supplyParams: [])
            ]
          )
          let new = self.sectionablesWithParams(
            [
              SectionParams(id: "", cellParams: [], supplyParams: []),
              SectionParams(id: "3", cellParams: [], supplyParams: [])
            ]
          )

          expect { try DiffUtils.diffOrThrow(new: new, old: old) }.to(throwError())
        }

        it("with id collisions") {

          let old = self.sectionablesWithParams(
            [
              SectionParams(id: "1", cellParams: [], supplyParams: []),
              SectionParams(id: "1", cellParams: [], supplyParams: [])
            ]
          )
          let new = self.sectionablesWithParams(
            [
              SectionParams(id: "3", cellParams: [], supplyParams: []),
              SectionParams(id: "3", cellParams: [], supplyParams: [])
            ]
          )

          expect { try DiffUtils.diffOrThrow(new: new, old: old) }.to(throwError())
        }

        context("with supplementary cells") {

          it("with empty ids") {

            let old = self.sectionablesWithParams(
              [
                SectionParams(
                  id: "1",
                  cellParams: [],
                  supplyParams: [
                    CellParams(id: "", type: .footer, data: 1),
                  ]),
                SectionParams(id: "2", cellParams: [], supplyParams: [])
              ]
            )
            let new = self.sectionablesWithParams(
              [
                SectionParams(id: "1", cellParams: [], supplyParams: []),
                SectionParams(
                  id: "2",
                  cellParams: [],
                  supplyParams: [
                    CellParams(id: "", type: .header, data: 1),
                  ])
              ]
            )

            expect { try DiffUtils.diffOrThrow(new: new, old: old) }.to(throwError())
          }

          it("with id collisions") {

            let old = self.sectionablesWithParams(
              [
                SectionParams(
                  id: "1",
                  cellParams: [],
                  supplyParams: [
                    CellParams(id: "1", type: .footer, data: 1),
                    CellParams(id: "1", type: .header, data: 1),
                  ]),
                SectionParams(id: "2", cellParams: [], supplyParams: [])
              ]
            )
            let new = self.sectionablesWithParams(
              [
                SectionParams(id: "1", cellParams: [], supplyParams: []),
                SectionParams(
                  id: "2",
                  cellParams: [],
                  supplyParams: [
                    CellParams(id: "1", type: .header, data: 1),
                  ])
              ]
            )

            expect { try DiffUtils.diffOrThrow(new: new, old: old) }.to(throwError())
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
                    ], supplyParams: []),
                  SectionParams(
                    id: "1",
                    cellParams: [
                      CellParams(id: "1", type: .cell, data: 1),
                      CellParams(id: "", type: .cell, data: 0)
                    ], supplyParams: [])
                ]
              )

              expect { try DiffUtils.diffOrThrow(new: new, old: old) }.to(throwError())
            }

            it("with id collisions") {

              let old = self.sectionablesWithParams(
                [
                  SectionParams(
                    id: "0",
                    cellParams: [
                      CellParams(id: "0", type: .cell, data: 0),
                      CellParams(id: "0", type: .cell, data: 1)
                    ], supplyParams: [])
                ]
              )
              let new = self.sectionablesWithParams(
                [
                  SectionParams(
                    id: "0",
                    cellParams: [
                      CellParams(id: "1", type: .cell, data: 0),
                      CellParams(id: "1", type: .cell, data: 1)
                    ], supplyParams: [])
                ]
              )

              expect { try DiffUtils.diffOrThrow(new: new, old: old) }.to(throwError())
            }

            it("without data equals closures") {

              let old = self.sectionablesWithParams(
                [
                  SectionParams(
                    id: "0",
                    cellParams: [
                      CellParams(id: "", type: .cell, data: 0),
                      CellParams(id: "1", type: .cell, data: 1, dataEquals: nil)
                    ], supplyParams: [])
                ]
              )
              let new = self.sectionablesWithParams(
                [
                  SectionParams(
                    id: "0",
                    cellParams: [
                      CellParams(id: "0", type: .cell, data: 0),
                      CellParams(id: "1", type: .cell, data: 1, dataEquals: nil)
                    ], supplyParams: []),
                  SectionParams(
                    id: "1",
                    cellParams: [
                      CellParams(id: "1", type: .cell, data: 1),
                      CellParams(id: "2", type: .cell, data: 0)
                    ], supplyParams: [])
                ]
              )

              expect { try DiffUtils.diffOrThrow(new: new, old: old) }.to(throwError())
            }

            context("are valid") {

              context("with several valid supplementary cells") {

                it("no changes") {

                  let sections = [
                    SectionParams(
                      id: "0",
                      cellParams: [
                        CellParams(id: "?", type: .header, data: 0),
                        CellParams(id: "0", type: .cell, data: 0),
                        CellParams(id: "1", type: .cell, data: 1),
                        CellParams(id: "??", type: .footer, data: 0)
                      ],
                      supplyParams: [
                        CellParams(id: "0", type: .header, data: 0),
                        CellParams(id: "1", type: .footer, data: 1)
                      ]
                    ),
                    SectionParams(
                      id: "1",
                      cellParams: [
                        CellParams(id: "?", type: .header, data: 0),
                        CellParams(id: "0", type: .cell, data: 0),
                        CellParams(id: "1", type: .cell, data: 1),
                        CellParams(id: "??", type: .footer, data: 0)
                      ],
                      supplyParams: [
                        CellParams(id: "0", type: .header, data: 0),
                        CellParams(id: "1", type: .footer, data: 1)
                      ]
                    )
                  ]
                  let old = self.sectionablesWithParams(sections)
                  let new = self.sectionablesWithParams(sections)

                  expect(DiffUtils.diff(new: new, old: old)).to(beNil())
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
                        ],
                        supplyParams: [
                          CellParams(id: "0", type: .header, data: 0),
                          CellParams(id: "1", type: .footer, data: 1)
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
                        ],
                        supplyParams: [
                          CellParams(id: "0", type: .header, data: 0),
                          CellParams(id: "1", type: .footer, data: 1)
                        ]),
                      SectionParams(
                        id: "1",
                        cellParams: [
                          CellParams(id: "???", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "???", type: .footer, data: 0)
                        ],
                        supplyParams: [
                          CellParams(id: "0", type: .header, data: 0),
                          CellParams(id: "1", type: .footer, data: 1)
                        ])
                    ]
                  )

                  let context = DiffUtils.diff(new: new, old: old)
                  expect(context?.insertedSections) == IndexSet(integer: 1)
                  expect(context?.deletedSections) == IndexSet()
                  expect(context?.updatedSections) == IndexSet()
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
                        ],
                        supplyParams: [
                          CellParams(id: "0", type: .header, data: 0),
                          CellParams(id: "1", type: .footer, data: 1)
                        ]),
                      SectionParams(
                        id: "1",
                        cellParams: [
                          CellParams(id: "???", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "???", type: .footer, data: 0)
                        ],
                        supplyParams: [
                          CellParams(id: "0", type: .header, data: 0),
                          CellParams(id: "1", type: .footer, data: 1)
                        ])
                    ]
                  )
                  let new = self.sectionablesWithParams(
                    [
                      SectionParams(
                        id: "1",
                        cellParams: [
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "???", type: .footer, data: 0)
                        ],
                        supplyParams: [
                          CellParams(id: "0", type: .header, data: 0),
                          CellParams(id: "1", type: .footer, data: 1)
                        ])
                    ]
                  )

                  let context = DiffUtils.diff(new: new, old: old)
                  expect(context?.insertedSections) == IndexSet(integer: 0)
                  expect(context?.deletedSections) == IndexSet(arrayLiteral: 0, 1)
                  expect(context?.updatedSections) == IndexSet()
                  expect(context?.inserted) == [IndexPath]()
                  expect(context?.deleted) == [IndexPath]()
                  expect(context?.updated) == [IndexPath]()
                }

                context("updating section") {

                  it("when deleted and inserted has intersection") {

                    let old = self.sectionablesWithParams([
                      SectionParams(
                        id: "0",
                        cellParams: [
                          CellParams(id: "?", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "??", type: .footer, data: 0)
                        ],
                        supplyParams: []
                      ),
                      SectionParams(
                        id: "1",
                        cellParams: [
                          CellParams(id: "?", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "??", type: .footer, data: 0)
                        ],
                        supplyParams: []
                      ),
                      SectionParams(
                        id: "3",
                        cellParams: [
                          CellParams(id: "?", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "??", type: .footer, data: 0)
                        ],
                        supplyParams: []
                      )
                      ]
                    )
                    let new = self.sectionablesWithParams([
                      SectionParams(
                        id: "3",
                        cellParams: [
                          CellParams(id: "?", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "??", type: .footer, data: 0)
                        ],
                        supplyParams: []
                      ),
                      SectionParams(
                        id: "1",
                        cellParams: [
                          CellParams(id: "?", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "??", type: .footer, data: 0)
                        ],
                        supplyParams: []
                      ),
                      SectionParams(
                        id: "0",
                        cellParams: [
                          CellParams(id: "?", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "??", type: .footer, data: 0)
                        ],
                        supplyParams: []
                      )
                      ]
                    )

                    let context = DiffUtils.diff(new: new, old: old)
                    expect(context?.insertedSections) == IndexSet(arrayLiteral: 0, 2)
                    expect(context?.deletedSections) == IndexSet(arrayLiteral: 0, 2)
                    expect(context?.updatedSections) == IndexSet()
                    expect(context?.inserted) == [IndexPath]()
                    expect(context?.deleted) == [IndexPath]()
                    expect(context?.updated) == [IndexPath]()
                  }

                  it("when supplementary has been changed") {

                    let old = self.sectionablesWithParams([
                      SectionParams(
                        id: "0",
                        cellParams: [
                          CellParams(id: "?", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "??", type: .footer, data: 0)
                        ],
                        supplyParams: [
                          CellParams(id: "0", type: .header, data: 0),
                          CellParams(id: "1", type: .footer, data: 1)
                        ]
                      ),
                      SectionParams(
                        id: "1",
                        cellParams: [
                          CellParams(id: "?", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "??", type: .footer, data: 0)
                        ],
                        supplyParams: [
                          CellParams(id: "0", type: .header, data: 0),
                          CellParams(id: "1", type: .footer, data: 1)
                        ]
                      ),
                      SectionParams(
                        id: "3",
                        cellParams: [
                          CellParams(id: "?", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "??", type: .footer, data: 0)
                        ],
                        supplyParams: [
                          CellParams(id: "0", type: .header, data: 0),
                          CellParams(id: "1", type: .footer, data: 1)
                        ]
                      )
                      ]
                    )
                    let new = self.sectionablesWithParams([
                      SectionParams(
                        id: "0",
                        cellParams: [
                          CellParams(id: "?", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "??", type: .footer, data: 0)
                        ],
                        supplyParams: [
                          CellParams(id: "1", type: .footer, data: 1)
                        ]
                      ),
                      SectionParams(
                        id: "1",
                        cellParams: [
                          CellParams(id: "?", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "??", type: .footer, data: 0)
                        ],
                        supplyParams: [
                          CellParams(id: "3", type: .header, data: 0),
                          CellParams(id: "1", type: .footer, data: 1)
                        ]
                      ),
                      SectionParams(
                        id: "3",
                        cellParams: [
                          CellParams(id: "?", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "??", type: .footer, data: 0)
                        ],
                        supplyParams: [
                          CellParams(id: "0", type: .header, data: 0),
                          CellParams(id: "1", type: .footer, data: 5)
                        ]
                      )
                      ]
                    )

                    let context = DiffUtils.diff(new: new, old: old)
                    expect(context?.insertedSections) == IndexSet()
                    expect(context?.deletedSections) == IndexSet()
                    expect(context?.updatedSections) == IndexSet(arrayLiteral: 0, 1, 2)
                    expect(context?.inserted) == [IndexPath]()
                    expect(context?.deleted) == [IndexPath]()
                    expect(context?.updated) == [IndexPath]()
                  }
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
                        ],
                        supplyParams: [
                          CellParams(id: "0", type: .header, data: 0),
                          CellParams(id: "1", type: .footer, data: 1)
                        ]),
                      SectionParams(
                        id: "1",
                        cellParams: [
                          CellParams(id: "???", type: .header, data: 0),
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1)
                        ],
                        supplyParams: [
                          CellParams(id: "0", type: .header, data: 0),
                          CellParams(id: "1", type: .footer, data: 1)
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
                        ],
                        supplyParams: [
                          CellParams(id: "0", type: .header, data: 0),
                          CellParams(id: "1", type: .footer, data: 1)
                        ]),
                      SectionParams(
                        id: "1",
                        cellParams: [
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "", type: .header, data: 0), // inserted
                          CellParams(id: "2", type: .cell, data: 2) // inserted
                        ],
                        supplyParams: [
                          CellParams(id: "0", type: .header, data: 0),
                          CellParams(id: "1", type: .footer, data: 1)
                        ])
                    ]
                  )

                  let context = DiffUtils.diff(new: new, old: old)
                  expect(context?.insertedSections) == IndexSet()
                  expect(context?.deletedSections) == IndexSet()
                  expect(context?.updatedSections) == IndexSet()
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
                        ],
                        supplyParams: [
                          CellParams(id: "0", type: .header, data: 0),
                          CellParams(id: "1", type: .footer, data: 1)
                        ]),
                      SectionParams(
                        id: "1",
                        cellParams: [
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "", type: .header, data: 0), // deleted
                          CellParams(id: "2", type: .cell, data: 2)
                        ],
                        supplyParams: [
                          CellParams(id: "0", type: .header, data: 0),
                          CellParams(id: "1", type: .footer, data: 1)
                        ])
                    ]
                  )
                  let new = self.sectionablesWithParams(
                    [
                      SectionParams(
                        id: "0",
                        cellParams: [
                          CellParams(id: "0", type: .cell, data: 0),
                        ],
                        supplyParams: [
                          CellParams(id: "0", type: .header, data: 0),
                          CellParams(id: "1", type: .footer, data: 1)
                        ]),
                      SectionParams(
                        id: "1",
                        cellParams: [
                          CellParams(id: "0", type: .cell, data: 0),
                          CellParams(id: "1", type: .cell, data: 1),
                          CellParams(id: "2", type: .cell, data: 2)
                        ],
                        supplyParams: [
                          CellParams(id: "0", type: .header, data: 0),
                          CellParams(id: "1", type: .footer, data: 1)
                        ])
                    ]
                  )

                  let context = DiffUtils.diff(new: new, old: old)
                  expect(context?.insertedSections) == IndexSet()
                  expect(context?.deletedSections) == IndexSet()
                  expect(context?.updatedSections) == IndexSet()
                  expect(context?.inserted) == [IndexPath]()
                  expect(context?.deleted) == [IndexPath(row: 1, section: 0)]
                  expect(context?.updated) == [IndexPath]()
                }

                context("updating cell") {

                  it("when data changes") {

                    let old = self.sectionablesWithParams(
                      [
                        SectionParams(
                          id: "0",
                          cellParams: [
                            CellParams(id: "0", type: .cell, data: 1)
                          ],
                          supplyParams: [
                            CellParams(id: "0", type: .header, data: 0),
                            CellParams(id: "1", type: .footer, data: 1)
                          ]),
                        SectionParams(
                          id: "1",
                          cellParams: [
                            CellParams(id: "0", type: .cell, data: 1)
                          ],
                          supplyParams: [
                            CellParams(id: "0", type: .header, data: 0),
                            CellParams(id: "1", type: .footer, data: 1)
                          ])
                      ]
                    )
                    let new = self.sectionablesWithParams(
                      [
                        SectionParams(
                          id: "0",
                          cellParams: [
                            CellParams(id: "0", type: .cell, data: 2)
                          ],
                          supplyParams: [
                            CellParams(id: "0", type: .header, data: 0),
                            CellParams(id: "1", type: .footer, data: 1)
                          ]),
                        SectionParams(
                          id: "1",
                          cellParams: [
                            CellParams(id: "0", type: .cell, data: 1)
                          ],
                          supplyParams: [
                            CellParams(id: "0", type: .header, data: 0),
                            CellParams(id: "1", type: .footer, data: 1)
                          ])
                      ]
                    )

                    let context = DiffUtils.diff(new: new, old: old)
                    expect(context?.insertedSections) == IndexSet()
                    expect(context?.deletedSections) == IndexSet()
                    expect(context?.updatedSections) == IndexSet()
                    expect(context?.inserted) == [IndexPath]()
                    expect(context?.deleted) == [IndexPath]()
                    expect(context?.updated) == [IndexPath(row: 0, section: 0)]
                  }

                  it("when insert and delete same cell") {

                    let old = self.sectionablesWithParams(
                      [
                        SectionParams(
                          id: "0",
                          cellParams: [
                            CellParams(id: "0", type: .cell, data: 1)
                          ],
                          supplyParams: [
                            CellParams(id: "0", type: .header, data: 0),
                            CellParams(id: "1", type: .footer, data: 1)
                          ]),
                        SectionParams(
                          id: "1",
                          cellParams: [
                            CellParams(id: "0", type: .cell, data: 1)
                          ],
                          supplyParams: [
                            CellParams(id: "0", type: .header, data: 0),
                            CellParams(id: "1", type: .footer, data: 1)
                          ])
                      ]
                    )
                    let new = self.sectionablesWithParams(
                      [
                        SectionParams(
                          id: "0",
                          cellParams: [
                            CellParams(id: "1", type: .cell, data: 1)
                          ],
                          supplyParams: [
                            CellParams(id: "0", type: .header, data: 0),
                            CellParams(id: "1", type: .footer, data: 1)
                          ]),
                        SectionParams(
                          id: "1",
                          cellParams: [
                            CellParams(id: "0", type: .cell, data: 1)
                          ],
                          supplyParams: [
                            CellParams(id: "0", type: .header, data: 0),
                            CellParams(id: "1", type: .footer, data: 1)
                          ])
                      ]
                    )

                    let context = DiffUtils.diff(new: new, old: old)
                    expect(context?.insertedSections) == IndexSet()
                    expect(context?.deletedSections) == IndexSet()
                    expect(context?.updatedSections) == IndexSet()
                    expect(context?.inserted) == [IndexPath(row: 0, section: 0)]
                    expect(context?.deleted) == [IndexPath(row: 0, section: 0)]
                    expect(context?.updated) == [IndexPath]()
                  }

                  it("when swap cells") {

                    let old = self.sectionablesWithParams(
                      [
                        SectionParams(
                          id: "0",
                          cellParams: [
                            CellParams(id: "0", type: .cell, data: 0),
                            CellParams(id: "1", type: .cell, data: 1),
                            CellParams(id: "2", type: .cell, data: 2)
                          ],
                          supplyParams: []),
                      ]
                    )
                    let new = self.sectionablesWithParams(
                      [
                        SectionParams(
                          id: "0",
                          cellParams: [
                            CellParams(id: "2", type: .cell, data: 2),
                            CellParams(id: "1", type: .cell, data: 1),
                            CellParams(id: "0", type: .cell, data: 0)
                          ],
                          supplyParams: []),
                      ]
                    )

                    let context = DiffUtils.diff(new: new, old: old)
                    expect(context?.insertedSections) == IndexSet()
                    expect(context?.deletedSections) == IndexSet()
                    expect(context?.updatedSections) == IndexSet()
                    expect(context?.inserted) == [IndexPath]()
                    expect(context?.deleted) == [IndexPath]()
                    expect(context?.updated) == [IndexPath(row: 0, section: 0), IndexPath(row: 2, section: 0)]
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
