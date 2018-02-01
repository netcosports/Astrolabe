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

Now your cell is able to be used in Astrolabe dataSource. Library has different types of sources for different purposes(explained below). So, your recycle container(UITableView or UICollectionView) can be configured with different types of sources. Foe example basic collection view source for static cells setup:

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
class Section: Sectionable
class HeaderSection<Container, CellView: ReusableView & Reusable>: Section
class CustomHeaderSection<CellView: ReusableView & Reusable>: Section
class FooterSection<Container, CellView: ReusableView & Reusable>: Section
```

Section can contain header, footer(or both of them) or custom supplementary view. All sections store array of cells represented items inside this section.

### 1.3 Data source setup

Configured cells should be pack cells into sections and provided inside data source:

```swift
let section: Sectionable = Section(cells: [cell])
containerView.source.sections = [section]
```

TODO: image result

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

Traditional selection management can not always be applied, because of, for example, async loading content.

## 2. Expandable data source
## 3. Pager
### 3.1 Static pager
### 3.2 Reused cells pager
## 4. Loader decorator
## 5. Loaders

## 6. Custom base UICollectionView cell usage
