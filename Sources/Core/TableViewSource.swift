//
//  TableViewSource.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/5/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit

public typealias TableViewSource = GenericTableViewSource<TableViewDataSource>

open class GenericTableViewSource<DataSource: TableViewDataSource>: ReusableSource {

  public typealias Container = UITableView

  let dataSource = DataSource()

  public required init() {
  }

  open var containerView: Container? {
    didSet {
      internalInit()
    }
  }

  public weak var hostViewController: UIViewController?
  public var sections: [Sectionable] = [] {
    didSet {
      dataSource.sections = sections
      registerCellsForSections()
    }
  }
  public var lastCellDisplayed: VoidClosure? {
    didSet {
      dataSource.lastCellDisplayed = lastCellDisplayed
    }
  }
  public var lastCellСondition: LastCellConditionClosure? {
    didSet {
      dataSource.lastCellСondition = lastCellСondition
    }
  }
  public var selectedCellIds: Set<String> = []
  public var selectionBehavior: SelectionBehavior = .single
  public var selectionManagement: SelectionManagement = .none
  public var displaySectionIndex = false
  fileprivate var sectionIndexTitles: [String]? {
    didSet {
      dataSource.sectionIndexTitles = sectionIndexTitles
    }
  }

  fileprivate func internalInit() {
    containerView?.delegate = dataSource
    containerView?.dataSource = dataSource
    containerView?.backgroundColor = .clear
    #if !os(tvOS)
      containerView?.separatorColor = .clear
      containerView?.separatorStyle = .none
    #endif

    dataSource.cellSelected = { [weak self] cell, indexPath in
      self?.click(cell: cell, indexPath: indexPath)
    }

    dataSource.setupCell = { [weak self] cellView, cell in
      self?.setup(cellView: cellView, with: cell)
    }

    dataSource.setupHeader = { [weak self] headerView, cell in
      self?.setup(headerView: headerView, with: cell)
    }

    dataSource.lastCellСondition = {
      if $0.section == $1
        && $0.item == $2 {
        return true
      }
      return false
    }
  }

  func setup(cellView: TableViewCell, with cell: Cellable) {
    cellView.containerViewController = hostViewController
    cellView.selectedState = selectedCellIds.contains(cell.id)
  }

  func setup(headerView: TableViewHeaderFooter, with cell: Cellable) {
    headerView.containerViewController = hostViewController
    headerView.selectedState = selectedCellIds.contains(cell.id)
  }

  func click(cell: Cellable, indexPath: IndexPath) {
    if selectionManagement == .automatic {
      processSelection(for: cell.id)
      containerView?.reloadData()
    }
  }

  public func registerCellsForSections() {
    guard let containerView = containerView else { return }
    var indexTitles = [String]()
    sections.forEach { section in
      if let header = section.supplementary(for: .header) {
        header.register(in: containerView)
        if header.id.count == 1 && displaySectionIndex {
          indexTitles.append(header.id)
        }
      }
      if let footer = section.supplementary(for: .footer) {
        footer.register(in: containerView)
      }
      section.cells.forEach { cell in
        cell.register(in: containerView)
      }
    }
    sectionIndexTitles = displaySectionIndex ? indexTitles : nil
  }
}
