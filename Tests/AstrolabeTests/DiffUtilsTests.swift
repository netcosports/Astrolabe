//
//  DiffUtilsTests.swift
//  iOSTests
//
//  Created by Alexander Zhigulich on 4/22/19.
//  Copyright © 2019 NetcoSports. All rights reserved.
//

import Quick
import Nimble
@testable import Astrolabe

import RxSwift
import RxCocoa

import UIKit

class DiffUtilsTests: QuickSpec {

  class TestCell: CollectionViewCell, Reusable, Eventable {

    func setup(with data: Data) {

    }

    let eventSubject = PublishSubject<Event>()

    var data: DiffUtilsTests.CellParams?

    typealias Data = CellParams
    typealias Event = String
  }

  struct SectionParams: Hashable {
    static func == (lhs: DiffUtilsTests.SectionParams, rhs: DiffUtilsTests.SectionParams) -> Bool {
      return lhs.state == rhs.state
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(state)
    }

    var state: String = ""
    var cellParams = [CellParams]()
    var supplyParams = [CellParams]()
  }

  struct CellParams: Hashable {
    func hash(into hasher: inout Hasher) {
      hasher.combine(type)
      hasher.combine(state)
    }

    static func == (lhs: DiffUtilsTests.CellParams, rhs: DiffUtilsTests.CellParams) -> Bool {
      return lhs.type == rhs.type &&
             lhs.state == rhs.state
    }
    var state: String
    var type: CellType = .cell
  }

  fileprivate var emptySectionables = [Section<SectionParams, CellParams>]()

  fileprivate func sectionablesWithParams(
    _ params: [SectionParams]
  ) -> [Section<SectionParams, CellParams>] {

    return params.map { sectionParam in
      return Section<SectionParams, CellParams>(
        cells: sectionParam.cellParams.map { Cell<CellParams>.init(cell: TestCell.self, state: $0) },
        state: sectionParam,
        supplementaries: sectionParam.supplyParams.map { Cell<CellParams>.init(cell: TestCell.self, state: $0) }.map { $0.cell }

      )
    }
  }

  override func spec() {

    describe("difference") {

      context("when sections") {

//        it("with empty ids") {
//
//          let old = self.sectionablesWithParams(
//            [
//              SectionParams(state: "", cellParams: [], supplyParams: []),
//              SectionParams(state: "1", cellParams: [], supplyParams: [])
//            ]
//          )
//          let new = self.sectionablesWithParams(
//            [
//              SectionParams(state: "", cellParams: [], supplyParams: []),
//              SectionParams(state: "3", cellParams: [], supplyParams: [])
//            ]
//          )
//
//          expect { try DiffUtils.diffOrThrow(new: new, old: old) }.to(throwError())
//        }

        it("with id collisions") {

          let old = self.sectionablesWithParams(
            [
              SectionParams(state: "1", cellParams: [], supplyParams: []),
              SectionParams(state: "1", cellParams: [], supplyParams: [])
            ]
          )
          let new = self.sectionablesWithParams(
            [
              SectionParams(state: "3", cellParams: [], supplyParams: []),
              SectionParams(state: "3", cellParams: [], supplyParams: [])
            ]
          )

          expect { try DiffUtils.diffOrThrow(new: new, old: old) }.to(throwError())
        }

        context("with supplementary cells") {

//          it("with empty ids") {
//
//            let old = self.sectionablesWithParams(
//              [
//                SectionParams(
//                  state: "1",
//                  cellParams: [],
//                  supplyParams: [
//                    CellParams(state: "", type: .footer),
//                  ]),
//                SectionParams(state: "2", cellParams: [], supplyParams: [])
//              ]
//            )
//            let new = self.sectionablesWithParams(
//              [
//                SectionParams(state: "1", cellParams: [], supplyParams: []),
//                SectionParams(
//                  state: "2",
//                  cellParams: [],
//                  supplyParams: [
//                    CellParams(state: "", type: .header),
//                  ])
//              ]
//            )
//
//            expect { try DiffUtils.diffOrThrow(new: new, old: old) }.to(throwError())
//          }

//          it("with id collisions") {
//
//            let old = self.sectionablesWithParams(
//              [
//                SectionParams(
//                  state: "1",
//                  cellParams: [],
//                  supplyParams: [
//                    CellParams(state: "1", type: .footer),
//                    CellParams(state: "1", type: .header),
//                  ]),
//                SectionParams(state: "2", cellParams: [], supplyParams: [])
//              ]
//            )
//            let new = self.sectionablesWithParams(
//              [
//                SectionParams(state: "1", cellParams: [], supplyParams: []),
//                SectionParams(
//                  state: "2",
//                  cellParams: [],
//                  supplyParams: [
//                    CellParams(state: "1", type: .header),
//                  ])
//              ]
//            )
//
//            expect { try DiffUtils.diffOrThrow(new: new, old: old) }.to(throwError())
//          }
        }

        context("are valid") {

          context("when cells") {

//            it("with empty ids") {
//
//              let old = self.emptySectionables
//              let new = self.sectionablesWithParams(
//                [
//                  SectionParams(
//                    state: "0",
//                    cellParams: [
//                      CellParams(state: "", type: .cell),
//                      CellParams(state: "1", type: .cell)
//                    ], supplyParams: []),
//                  SectionParams(
//                    state: "1",
//                    cellParams: [
//                      CellParams(state: "1", type: .cell),
//                      CellParams(state: "", type: .cell)
//                    ], supplyParams: [])
//                ]
//              )
//
//              expect { try DiffUtils.diffOrThrow(new: new, old: old) }.to(throwError())
//            }

            it("with id collisions") {

              let old = self.sectionablesWithParams(
                [
                  SectionParams(
                    state: "0",
                    cellParams: [
                      CellParams(state: "0", type: .cell),
                      CellParams(state: "0", type: .cell)
                    ], supplyParams: [])
                ]
              )
              let new = self.sectionablesWithParams(
                [
                  SectionParams(
                    state: "0",
                    cellParams: [
                      CellParams(state: "1", type: .cell),
                      CellParams(state: "1", type: .cell)
                    ], supplyParams: [])
                ]
              )

              expect { try DiffUtils.diffOrThrow(new: new, old: old) }.to(throwError())
            }

//            it("without data equals closures") {
//
//              let old = self.sectionablesWithParams(
//                [
//                  SectionParams(
//                    state: "0",
//                    cellParams: [
//                      CellParams(state: "", type: .cell),
//                      CellParams(state: "1", type: .cell)
//                    ], supplyParams: [])
//                ]
//              )
//              let new = self.sectionablesWithParams(
//                [
//                  SectionParams(
//                    state: "0",
//                    cellParams: [
//                      CellParams(state: "0", type: .cell),
//                      CellParams(state: "1", type: .cell)
//                    ], supplyParams: []),
//                  SectionParams(
//                    state: "1",
//                    cellParams: [
//                      CellParams(state: "1", type: .cell),
//                      CellParams(state: "2", type: .cell)
//                    ], supplyParams: [])
//                ]
//              )
//
//              expect { try DiffUtils.diffOrThrow(new: new, old: old) }.to(throwError())
//            }

            context("are valid") {

              context("with several valid supplementary cells") {

                it("no changes") {

                  let sections = [
                    SectionParams(
                      state: "0",
                      cellParams: [
                        CellParams(state: "?", type: .header),
                        CellParams(state: "0", type: .cell),
                        CellParams(state: "1", type: .cell),
                        CellParams(state: "??", type: .footer)
                      ],
                      supplyParams: [
                        CellParams(state: "0", type: .header),
                        CellParams(state: "1", type: .footer)
                      ]
                    ),
                    SectionParams(
                      state: "1",
                      cellParams: [
                        CellParams(state: "?", type: .header),
                        CellParams(state: "0", type: .cell),
                        CellParams(state: "1", type: .cell),
                        CellParams(state: "??", type: .footer)
                      ],
                      supplyParams: [
                        CellParams(state: "0", type: .header),
                        CellParams(state: "1", type: .footer)
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
                        state: "0",
                        cellParams: [
                          CellParams(state: "???", type: .header),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "???", type: .footer)
                        ],
                        supplyParams: [
                          CellParams(state: "0", type: .header),
                          CellParams(state: "1", type: .footer)
                        ])
                    ]
                  )
                  let new = self.sectionablesWithParams(
                    [
                      SectionParams(
                        state: "0",
                        cellParams: [
                          CellParams(state: "???", type: .header),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "???", type: .footer)
                        ],
                        supplyParams: [
                          CellParams(state: "0", type: .header),
                          CellParams(state: "1", type: .footer)
                        ]),
                      SectionParams(
                        state: "1",
                        cellParams: [
                          CellParams(state: "???", type: .header),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "???", type: .footer)
                        ],
                        supplyParams: [
                          CellParams(state: "0", type: .header),
                          CellParams(state: "1", type: .footer)
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
                        state: "0",
                        cellParams: [
                          CellParams(state: "???", type: .header),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "???", type: .footer)
                        ],
                        supplyParams: [
                          CellParams(state: "0", type: .header),
                          CellParams(state: "1", type: .footer)
                        ]),
                      SectionParams(
                        state: "1",
                        cellParams: [
                          CellParams(state: "???", type: .header),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "???", type: .footer)
                        ],
                        supplyParams: [
                          CellParams(state: "0", type: .header),
                          CellParams(state: "1", type: .footer)
                        ])
                    ]
                  )
                  let new = self.sectionablesWithParams(
                    [
                      SectionParams(
                        state: "1",
                        cellParams: [
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "???", type: .footer)
                        ],
                        supplyParams: [
                          CellParams(state: "0", type: .header),
                          CellParams(state: "1", type: .footer)
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
                        state: "0",
                        cellParams: [
                          CellParams(state: "?", type: .header),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "??", type: .footer)
                        ],
                        supplyParams: []
                      ),
                      SectionParams(
                        state: "1",
                        cellParams: [
                          CellParams(state: "?", type: .header),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "??", type: .footer)
                        ],
                        supplyParams: []
                      ),
                      SectionParams(
                        state: "3",
                        cellParams: [
                          CellParams(state: "?", type: .header),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "??", type: .footer)
                        ],
                        supplyParams: []
                      )
                      ]
                    )
                    let new = self.sectionablesWithParams([
                      SectionParams(
                        state: "3",
                        cellParams: [
                          CellParams(state: "?", type: .header),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "??", type: .footer)
                        ],
                        supplyParams: []
                      ),
                      SectionParams(
                        state: "1",
                        cellParams: [
                          CellParams(state: "?", type: .header),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "??", type: .footer)
                        ],
                        supplyParams: []
                      ),
                      SectionParams(
                        state: "0",
                        cellParams: [
                          CellParams(state: "?", type: .header),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "??", type: .footer)
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
                        state: "0",
                        cellParams: [
                          CellParams(state: "?", type: .header),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "??", type: .footer)
                        ],
                        supplyParams: [
                          CellParams(state: "0", type: .header),
                          CellParams(state: "1", type: .footer)
                        ]
                      ),
                      SectionParams(
                        state: "1",
                        cellParams: [
                          CellParams(state: "?", type: .header),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "??", type: .footer)
                        ],
                        supplyParams: [
                          CellParams(state: "0", type: .header),
                          CellParams(state: "1", type: .footer)
                        ]
                      ),
                      SectionParams(
                        state: "3",
                        cellParams: [
                          CellParams(state: "?", type: .header),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "??", type: .footer)
                        ],
                        supplyParams: [
                          CellParams(state: "0", type: .header),
                          CellParams(state: "1", type: .footer)
                        ]
                      )
                      ]
                    )
                    let new = self.sectionablesWithParams([
                      SectionParams(
                        state: "0",
                        cellParams: [
                          CellParams(state: "?", type: .header),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "??", type: .footer)
                        ],
                        supplyParams: [
                          CellParams(state: "3", type: .header)
                        ]
                      ),
                      SectionParams(
                        state: "1",
                        cellParams: [
                          CellParams(state: "?", type: .header),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "??", type: .footer)
                        ],
                        supplyParams: [
                          CellParams(state: "3", type: .header)
                        ]
                      ),
                      SectionParams(
                        state: "3",
                        cellParams: [
                          CellParams(state: "?", type: .header),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "??", type: .footer)
                        ],
                        supplyParams: [
                          CellParams(state: "1", type: .footer)
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
                        state: "0",
                        cellParams: [
                          CellParams(state: "???", type: .cell),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "", type: .cell)
                        ],
                        supplyParams: [
                          CellParams(state: "0", type: .header),
                          CellParams(state: "1", type: .footer)
                        ]),
                      SectionParams(
                        state: "1",
                        cellParams: [
                          CellParams(state: "???", type: .cell),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell)
                        ],
                        supplyParams: [
                          CellParams(state: "0", type: .header),
                          CellParams(state: "1", type: .footer)
                        ])
                    ]
                  )
                  let new = self.sectionablesWithParams(
                    [
                      SectionParams(
                        state: "0",
                        cellParams: [
                          CellParams(state: "???", type: .cell),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "", type: .cell)
                        ],
                        supplyParams: [
                          CellParams(state: "0", type: .header),
                          CellParams(state: "1", type: .footer)
                        ]),
                      SectionParams(
                        state: "1",
                        cellParams: [
                          CellParams(state: "???", type: .cell),
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "2", type: .cell), // inserted
                        ],
                        supplyParams: [
                          CellParams(state: "0", type: .header),
                          CellParams(state: "1", type: .footer)
                        ])
                    ]
                  )

                  let context = DiffUtils.diff(new: new, old: old)
                  expect(context?.insertedSections) == IndexSet()
                  expect(context?.deletedSections) == IndexSet()
                  expect(context?.updatedSections) == IndexSet()
                  expect(context?.inserted) == [IndexPath(row: 3, section: 1)]
                  expect(context?.deleted) == [IndexPath]()
                  expect(context?.updated) == [IndexPath]()
                }

                it("deleting cell") {

                  let old = self.sectionablesWithParams(
                    [
                      SectionParams(
                        state: "0",
                        cellParams: [
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell), // deleted
                        ],
                        supplyParams: [
                          CellParams(state: "0", type: .header),
                          CellParams(state: "1", type: .footer)
                        ]),
                      SectionParams(
                        state: "1",
                        cellParams: [
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "2", type: .cell)
                        ],
                        supplyParams: [
                          CellParams(state: "0", type: .header),
                          CellParams(state: "1", type: .footer)
                        ])
                    ]
                  )
                  let new = self.sectionablesWithParams(
                    [
                      SectionParams(
                        state: "0",
                        cellParams: [
                          CellParams(state: "0", type: .cell),
                        ],
                        supplyParams: [
                          CellParams(state: "0", type: .header),
                          CellParams(state: "1", type: .footer)
                        ]),
                      SectionParams(
                        state: "1",
                        cellParams: [
                          CellParams(state: "0", type: .cell),
                          CellParams(state: "1", type: .cell),
                          CellParams(state: "2", type: .cell)
                        ],
                        supplyParams: [
                          CellParams(state: "0", type: .header),
                          CellParams(state: "1", type: .footer)
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

                  it("when data not changed") {

                    let old = self.sectionablesWithParams(
                      [
                        SectionParams(
                          state: "0",
                          cellParams: [
                            CellParams(state: "0", type: .cell)
                          ],
                          supplyParams: [
                            CellParams(state: "0", type: .header),
                            CellParams(state: "1", type: .footer)
                          ]),
                        SectionParams(
                          state: "1",
                          cellParams: [
                            CellParams(state: "0", type: .cell)
                          ],
                          supplyParams: [
                            CellParams(state: "0", type: .header),
                            CellParams(state: "1", type: .footer)
                          ])
                      ]
                    )
                    let new = self.sectionablesWithParams(
                      [
                        SectionParams(
                          state: "0",
                          cellParams: [
                            CellParams(state: "0", type: .cell)
                          ],
                          supplyParams: [
                            CellParams(state: "0", type: .header),
                            CellParams(state: "1", type: .footer)
                          ]),
                        SectionParams(
                          state: "1",
                          cellParams: [
                            CellParams(state: "0", type: .cell)
                          ],
                          supplyParams: [
                            CellParams(state: "0", type: .header),
                            CellParams(state: "1", type: .footer)
                          ])
                      ]
                    )

                    let context = DiffUtils.diff(new: new, old: old)
                    expect(context).to(beNil())
                  }

                  it("when insert and delete same cell") {

                    let old = self.sectionablesWithParams(
                      [
                        SectionParams(
                          state: "0",
                          cellParams: [
                            CellParams(state: "0", type: .cell)
                          ],
                          supplyParams: [
                            CellParams(state: "0", type: .header),
                            CellParams(state: "1", type: .footer)
                          ]),
                        SectionParams(
                          state: "1",
                          cellParams: [
                            CellParams(state: "0", type: .cell)
                          ],
                          supplyParams: [
                            CellParams(state: "0", type: .header),
                            CellParams(state: "1", type: .footer)
                          ])
                      ]
                    )
                    let new = self.sectionablesWithParams(
                      [
                        SectionParams(
                          state: "0",
                          cellParams: [
                            CellParams(state: "1", type: .cell)
                          ],
                          supplyParams: [
                            CellParams(state: "0", type: .header),
                            CellParams(state: "1", type: .footer)
                          ]),
                        SectionParams(
                          state: "1",
                          cellParams: [
                            CellParams(state: "0", type: .cell)
                          ],
                          supplyParams: [
                            CellParams(state: "0", type: .header),
                            CellParams(state: "1", type: .footer)
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
                          state: "0",
                          cellParams: [
                            CellParams(state: "0", type: .cell),
                            CellParams(state: "1", type: .cell),
                            CellParams(state: "2", type: .cell)
                          ],
                          supplyParams: []),
                      ]
                    )
                    let new = self.sectionablesWithParams(
                      [
                        SectionParams(
                          state: "0",
                          cellParams: [
                            CellParams(state: "2", type: .cell),
                            CellParams(state: "1", type: .cell),
                            CellParams(state: "0", type: .cell)
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
