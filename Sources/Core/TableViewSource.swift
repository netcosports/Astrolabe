//
//  TableViewSource.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 1/5/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit

open class TableViewSource: NSObject, ReusableSource {

  public typealias Container = UITableView

  public required override init() {
    super.init()
  }

  open var containerView: Container? {
    didSet {
      internalInit()
    }
  }

  public weak var hostViewController: UIViewController?
  public var sections: [Sectionable] = [] {
    didSet {
      registerCellsForSections()
    }
  }
  public var lastCellDisplayed: VoidClosure?
  public var selectedCellIds: Set<String> = []
  public var selectionBehavior: SelectionBehavior = .single
  public var selectionManagement: SelectionManagement = .none
  public var displaySectionIndex = false
  fileprivate var sectionIndexTitles: [String]?

  fileprivate func internalInit() {
    containerView?.delegate = self
    containerView?.dataSource = self
    containerView?.backgroundColor = .clear
    #if !os(tvOS)
      containerView?.separatorColor = .clear
      containerView?.separatorStyle = .none
    #endif
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

  internal func setupCell(cellView: TableViewCell, cell: Cellable, indexPath: IndexPath) {
    cellView.containerViewController = hostViewController
    cellView.containerView = containerView
    cellView.indexPath = indexPath
    cellView.selectedState = selectedCellIds.contains(cell.id)
    cellView.cell = cell
  }

  internal func setupCell(headerView: TableViewHeaderFooter, cell: Cellable) {
    headerView.containerViewController = hostViewController
    headerView.containerView = containerView
    headerView.indexPath = nil
    headerView.selectedState = selectedCellIds.contains(cell.id)
    headerView.cell = cell
  }
}

extension TableViewSource: UITableViewDataSource, UITableViewDelegate {

  open func numberOfSections(in tableView: UITableView) -> Int {
    return sections.count
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let section = sections[section]
    return section.cells.count
  }

  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let section = sections[indexPath.section]
    let cell = section.cells[indexPath.item]
    let cellView: TableViewCell = cell.instance(for: tableView, index: indexPath)
    setupCell(cellView: cellView, cell: cell, indexPath: indexPath)
    cell.setup(with: cellView)
    return cellView
  }

  open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return supplementary(tableView, header: true, at: section)
  }

  open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return supplementary(tableView, header: false, at: section)
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let section = sections[indexPath.section]
    let cell = section.cells[indexPath.item]
    cell.click?()
    if selectionManagement == .automatic {
      processSelection(for: cell.id)
      containerView?.reloadData()
    }
  }

  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let section = sections[indexPath.section]
    let cell = section.cells[indexPath.item]
    return cell.size(with: tableView).height
  }

  open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    let section = sections[section]
    guard let header = section.supplementary(for: .header) else {
      return 0.0
    }
    return header.size(with: tableView).height
  }

  open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    let section = sections[section]
    guard let header = section.supplementary(for: .footer) else {
      return 0.0
    }
    return header.size(with: tableView).height
  }

  open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if indexPath.section == tableView.numberOfSections - 1
      && indexPath.item == tableView.numberOfRows(inSection: indexPath.section) - 1 {
      lastCellDisplayed?()
    }
    (cell as? TableViewCell)?.willDisplay()
  }

  open func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell,
                        forRowAt indexPath: IndexPath) {
    (cell as? TableViewCell)?.endDisplay()
  }

  open func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    (view as? TableViewHeaderFooter)?.willDisplay()
  }

  open func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {
    (view as? TableViewHeaderFooter)?.endDisplay()
  }

  open func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
    (view as? TableViewHeaderFooter)?.willDisplay()
  }

  open func tableView(_ tableView: UITableView, didEndDisplayingFooterView view: UIView, forSection section: Int) {
    (view as? TableViewHeaderFooter)?.endDisplay()
  }

  open func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    let section = sections[indexPath.section]
    let cell = section.cells[indexPath.item]
    return cell.size(with: tableView).height
  }

  open func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
    let section = sections[section]
    guard let header = section.supplementary(for: .header) else {
      return 0.0
    }
    return header.size(with: tableView).height
  }

  open func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
    let section = sections[section]
    guard let header = section.supplementary(for: .footer) else {
      return 0.0
    }
    return header.size(with: tableView).height
  }

  private func supplementary(_ tableView: UITableView, header: Bool, at section: Int) -> TableViewHeaderFooter? {
    let section = sections[section]
    var type = CellType.header
    if !header {
      type = .footer
    }
    guard let supplementary = section.supplementary(for: type) else { return nil }
    let supplementaryView: TableViewHeaderFooter = supplementary.instance(for: tableView, index: IndexPath())
    setupCell(headerView: supplementaryView, cell: supplementary)
    supplementary.setup(with: supplementaryView)
    if supplementary.click != nil {
      supplementaryView.gestureRecognizers?.forEach { supplementaryView.removeGestureRecognizer($0) }
      let recognizer = UITapGestureRecognizer(target: self, action: #selector(actionHeaderClick))
      supplementaryView.addGestureRecognizer(recognizer)
    }
    return supplementaryView
  }

  @objc fileprivate func actionHeaderClick(recognizer: UITapGestureRecognizer) {
    if let cellView = recognizer.view as? TableViewHeaderFooter {
      if let click = cellView.cell?.click {
        click()
      }
    }
  }

  open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    return sectionIndexTitles
  }

  open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String,
                        at index: Int) -> Int {
    return sections.index(where: { $0.supplementary(for: .header)?.id == title }) ?? 0
  }
}
