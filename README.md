# Astrolabe

Type-safe approach to manage UITableView and UICollectionView cells. Supports expandable, pager and async loaded sources.

[![Build Status](https://travis-ci.org/netcosports/Astrolabe.svg?branch=master)](https://travis-ci.org/netcosports/Astrolabe)

# Installation

## Swift 3.2
```ruby
pod 'Astrolabe', '~> 2.1'
```

## Swift 4.0
```ruby
pod 'Astrolabe', '~> 3.0'
```

# Usage

## 1. Getting started

Each cell in Astrolabe should be configured with viewModel. For example:

```swift
struct TestViewModel {
  let title: String
  let color: UIColor
}
```

To use cell in Astrolabe dataSource your cell should be inherited from base Astrolabe cell. To make initial cell configuration you could use setup() method:

```swift
class TestCollectionCell: CollectionViewCell {

  let label: UILabel = {
    let label = UILabel()
    label.textColor = .black
    return label
  }()

  override func setup() {
    super.setup()

    contentView.addSubview(label)
    label.snp.remakeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
}
```

To let library reuse your cell, it should be conform to Reusable protocol:

```swift
extension TestCollectionCell: Reusable {

  func setup(with data: TestViewModel) {
    label.text = data.title
  }

  static func size(for data: TestViewModel, containerSize: CGSize) -> CGSize {
    return CGSize(width: 64.0, height: 64.0)
  }
}
```

Also, Reusable protocol has method to provide reuse id which used for cell class registration id. But by default class name is used for this:

```swift
public extension Reusable {
  static func identifier(for data: Data) -> String {
    return "\(self)"
  }
}
```

Now your cell is able to be used in Astrolabe dataSource. Library has different types of sources for different purposes(explained below). So, your recycle container(UITableView or UICollectionView) can be configured with different types of sources. For example basic collection view source for static cells setup:

```swift
let containerView = CollectionView<CollectionViewSource>()
```

## 1. Static usage

To connect viewmodel with reusable cells you should define container which conforms to ```Cellable ``` protocol:

```swift
typealias Cell = CollectionCell<TestCollectionCell>
```

### 1.1 Cellable

```CollectionCell``` is implementation of ```Cellable ``` protocol for usage in UICollectionView. Now you can create first cell:

```swift
let cell: Cellable = Cell(data: TestViewModel("Test1"))
```

### 1.2 Sectionable

All UI sections represents to Sectionable protocol here. Here is few examples of Sectionable implementations:

```swift
class Section: Sectionable {}
class HeaderSection<Container, CellView: ReusableView & Reusable>: Section {}
class CustomHeaderSection<CellView: ReusableView & Reusable>: Section {}
class FooterSection<Container, CellView: ReusableView & Reusable>: Section {}
```

Section can contain header, footer(or both of them) or custom supplementary view. All sections store array of cells represented items inside this section.

### 1.3 Data source setup

Configured cells should be packed into sections and provided inside data source:

```swift
let section: Sectionable = Section(cells: [cell])
containerView.source.sections = [section]
```

**TODO: image result**

### 1.4 Selection

All cells has string id. This id can be used to identify id of selected item. We have the following types of selection management types and selection types:

```swift
public enum SelectionManagement {
  case none
  case automatic
  case manual
}

public enum SelectionBehavior {
  case single, multiple
}
```

**TODO: image result**

Traditional selection management(using IndexPath) can not always be applied, in case of async loading content for example.

### 1.5 Custom base UICollectionView cell usage

Sometimes you need to use your custom UICollectionViewCell(from some libraries for example). And it's also possible with Astrolabe. You only need to define GenericCollectionViewSource with you custom cell:

```swift
typealias CustomSource = GenericCollectionViewSource<MyCustomCollectionViewCell>
let containerView = CollectionView<CustomSource>()
```

## 2. Expandable data source

Since each cell has unique identifier we could build expandable source on top of it. Behavior we build is actually tree-view with infinite expanding levels. Here is the source:

```swift
let containerView = TableView<TableViewExpandableSource>()
```

To configure set of child cells you should use special expandable cells which, for sure, conforms to cellable protocol and can be used as child cell:

```swift
typealias Expandable = ExpandableCollectionViewCell<TestCollectionCell>
```

And configure child cells:

```swift
let cells: [Cellable] = [subCell1, subCell2, subCell3]
let expandable = Expandable(data: TestViewModel("root cell"), expandableCells: cells)
```

**TODO: image result. gif???**

## 3. Pager

Another two source types can be used for navigation between pages. Astrolabe provide two types of them:

### 3.1 Static pager

Fixed count of statically created view controllers. It's very easy to use actually:

```swift
let containerView = CollectionView<CollectionViewPagerSource>()
```

Just provide pager protocol implementation:

```swift
class PagerViewController: UIViewController, CollectionViewPager {

  override func loadView() {
    super.loadView()
    source.pager = self
    source.reloadData()
  }
  
  var pages: [Page] {
  return [
    Page(controller: TableSourceViewController(), id: "source"),
    Page(controller: TableLoaderSourceViewController(), id: "loader"),
    Page(controller: TableStyledSourceViewController(), id: "styled")
  ]
}
```

All cells will be created automatically by dataSource and all lifecycle methods of child view controllers will be called in correct order.

### 3.2 Reused cells pager

Dynamic count of cells with embeded view controllers which can be reused. It's also very easy to use actually:

```swift
let containerView = CollectionView<CollectionViewReusedPagerSource>()
```

Item ViewController should be conforms to ```ReusedPageData``` protocol:

```swift
class ExampleReusePagerItemViewController: UIViewController, ReusedPageData {

  var data: Int? {
    didSet {
    // TODO:
    }
  }
}
```

Just provide set of cells over section variable in source:

```swift
typealias CellView = ReusedPagerCollectionViewCell<ExampleReusePagerItemViewController>
typealias Cell = CollectionCell<CellView>

let cells: [Cellable] = data.map { Cell(data: $0) }
source.sections = [Section(cells: cells)]
```

## 4. Loader decorator

Astrolabe provides great way to load async content into recycle container. Since your content can be used with different dataSources, we provided ```LoaderDecoratorSource``` which wraps target dataSource and provide same interface. For example:

```swift
let containerView = CollectionView<LoaderDecoratorSource<CollectionViewSource>>()
```

To integrate loader into your code you only need:
1. implement Loader protocol:

```swift
extension BasicDataExampleCollectionViewController: Loader {

  func performLoading(intent: LoaderIntent) -> SectionObservable? {
	// ....
    return SectionObservable.just([Section(cells: cells, page: 0)])
    .delay(1.0, scheduler: MainScheduler.instance)
  }
}
```

Where based on LoaderIntent you can return necessary observable. Here is the list of supported intents:

```swift
public enum LoaderIntent {
  case initial
  case appearance
  case force(keepData: Bool)
  case pullToRefresh
  case autoupdate
  case page(page: Int)
}
```

2. Configure behavior:

```swift
containerView.source.loadingBehavior = [.initial, .paging, .autoupdate]
```

Currently Astrolabe provides the following list of loading behaviors:

```swift
public struct LoadingBehavior: OptionSet {
  public static let initial = LoadingBehavior(rawValue: 1 << 0)
  public static let appearance = LoadingBehavior(rawValue: 1 << 1)
  public static let autoupdate = LoadingBehavior(rawValue: 1 << 2)
  public static let autoupdateBackground = LoadingBehavior(rawValue: 3 << 2)
  public static let paging = LoadingBehavior(rawValue: 1 << 5)
}
```

3. Configure callbacks for start/stop loading progress and empty view updating:

```swift
containerView.source.startProgress = { 
  // ..
}
containerView.source.stopProgress = { 
  // ..
}
containerView.source.updateEmptyView = {
  // ..
}
```

**TODO: image result. gif???**

## 5. Loaders

Astrolabe is the best friend of Gnomon - https://github.com/netcosports/Gnomon :)

To make loading content easier over REST API using Gnomon we provide special classes called ```Loader``` which connect Astrolabe decorator and Gnomon request. Let's check for example simple plain loader protocol: 

```swift
public protocol PLoader: class {
  // Result type
  associatedtype PLResult: OptionalResult

  // Return configured request
  func request(for loadingIntent: LoaderIntent) throws -> Request<PLResult>
  // Map response model into array of sections(called in background thread)
  func sections(from result: PLResult, loadingIntent: LoaderIntent) -> [Sectionable]?
  // Additional after setup(called in main thread)
  func didReceive(result: PLResult, loadingIntent: LoaderIntent)
}
```

And then in LoaderProtocol implementation just return:

```swift
  func performLoading(intent: LoaderIntent) -> SectionObservable? {
	// ....
    return Astrolabe.load(pLoader: loader, intent: intent)
  }
```

## 0. Missing points 

1. Automatic diff calculation
2. Timeline loader source(two way paging source)
