//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport

import Astrolabe

import RxSwift
import RxCocoa

class TestCell: CollectionViewCell, Reusable, Eventable {

  let title: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.textColor = .black
    return label
  }()

  func setup(with data: Data) {
    title.text = data
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    title.frame = bounds
  }

  override func setup() {
    super.setup()
    title.backgroundColor = Bool.random() ? .blue : .gray
    contentView.addSubview(title)
  }

  static func size(for data: Data, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: 150)
  }

  let eventSubject = PublishSubject<Event>()

  var data: Data?

  typealias Data = String
  typealias Event = String
}


class MyViewController : UIViewController {

  let button: UIButton = {
    let button = UIButton()
    button.setTitle("SUFFLE", for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.titleLabel?.textAlignment = .center
    button.backgroundColor = .red
    return button
  }()

  let collectionView = CollectionView<CollectionViewSource<String, String>>()

  let disposeBag = DisposeBag()
  let eventSubject = PublishSubject<String>()
  var data: [String] = (1...30).map { "\($0)" }
  override func viewDidLoad() {
    super.viewDidLoad()

    button.rx.tap.subscribe(onNext: { [weak self] in
      guard let self = self else {
        return
      }
      self.data.shuffle()
      self.applySet()
    }).disposed(by: disposeBag)

    eventSubject.subscribe(onNext: { [weak self] event in
      self?.data.removeAll(where: { $0 == event })
      self?.applySet()
    }).disposed(by: disposeBag)

    collectionView.backgroundColor = .yellow

    view.addSubview(button)
    view.addSubview(collectionView)

    applySet()
  }

  private func applySet() {
    let cells = data.map {
      Cell(
        cell: TestCell.self,
        state: $0,
        eventsEmmiter: self.eventSubject.asObserver(),
        clickEvent: $0
      )
    }
    collectionView.source.apply(
      sections: [Section<String, String>(cells: cells, state: "some", supplementaries: [])]
    )
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    button.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: 200)
    collectionView.frame = CGRect(x: 0.0, y: 200.0, width: view.frame.width, height: view.frame.height - 200)
  }
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()
