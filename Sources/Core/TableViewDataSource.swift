//
//  TableViewDataSource.swift
//  Astrolabe
//
//  Created by Sergey Dikovitsky on 5/18/19.
//  Copyright © 2019 Netcosports. All rights reserved.
//

import UIKit

open class TableViewDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {

  public required override init() {
    super.init()
  }

  var sections: [Sectionable] = []

  var lastCellDisplayed: VoidClosure?
  var setupCell: ((TableViewCell, Cellable) -> ())?
  var setupHeader: ((TableViewHeaderFooter, Cellable) -> ())?
  var cellSelected: ((Cellable, IndexPath) -> ())?
  var lastCellСondition: LastCellConditionClosure?
  var sectionIndexTitles: [String]?

  func setupCell(cellView: TableViewCell, containerView: UITableView, cell: Cellable, indexPath: IndexPath) {
    cellView.hostContainerView = containerView
    cellView.indexPath = indexPath
    cellView.cell = cell

    setupCell?(cellView, cell)
  }

  func setupCell(headerView: TableViewHeaderFooter, cell: Cellable) {
    headerView.indexPath = nil
    headerView.cell = cell

    setupHeader?(headerView, cell)
  }

  func instance(cell: Cellable, containerView: UITableView, indexPath: IndexPath) -> TableViewCell {
    let cellView: TableViewCell = cell.instance(for: containerView, index: indexPath)
    setupCell(cellView: cellView, containerView: containerView, cell: cell, indexPath: indexPath)
    cell.setup(with: cellView)
    return cellView
  }

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
    setupCell(cellView: cellView, containerView: tableView, cell: cell, indexPath: indexPath)
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
    cellSelected?(cell, indexPath)
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
    if lastCellСondition?(indexPath,
                           tableView.numberOfSections - 1,
                           tableView.numberOfRows(inSection: indexPath.section) - 1) ?? false {
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
    return sections.firstIndex(where: { $0.supplementary(for: .header)?.id == title }) ?? 0
  }
}
