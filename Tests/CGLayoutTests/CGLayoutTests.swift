import XCTest
@testable import CGLayout

/// The container does not know which child is being added,
/// but the child knows exactly where it is being added

protocol ChildItem {
    func add<C>(to item: C)
}

extension Layer: ChildItem {
    func add<C>(to item: C) where C: Layer {
        item.addSublayer(self)
    }
    func add<C>(to item: C) where C: View {
        item.layer.addSublayer(self)
    }
    func add<C>(to item: C) {
        fatalError("Not supported container \(item)")
    }
}

extension View: ChildItem {
    func add<C>(to item: C) where C: Layer {
        item.addSublayer(layer)
    }
    func add<C>(to item: C) where C: View {
        item.layer.addSublayer(layer)
        item.addSubview(self)
    }
    func add<C>(to item: C) {
        print("VIEW: \(item)")
        fatalError("Not supported container \(item)")
    }
}

extension LayoutGuide: ChildItem {
    func add<C>(to item: C) where C: Layer, Super: Layer {
        item.add(layoutGuide: self)
    }
    func add<C>(to item: C) where C: View, Super: View {
        item.add(layoutGuide: self)
    }
    // func add<C>(to item: C) where C: View, Super: Layer {
    //     item.layer.add(layoutGuide: self)
    // }
    // func add<C: Container>(to item: C) where C: LayoutGuide, C.Super == Super {
    //     item.add(layoutGuide: self)
    // }
    func add<C>(to item: C) {
        // fatalError("Not supported container \(item)")
    }
}

enum SubItem<Super: LayoutItem> {
    case view(View)
    case layer(Layer)
    case layoutGuide(LayoutGuide<Super>)
}

protocol Container: LayoutItem {
    var sublayoutItems: [LayoutItem]? { get }
    func addSubItem(_ subItem: SubItem<Self>)
    func addChild(_ child: ChildItem)
    func setNeedsLayout()
}

final class Layer: Container, InLayoutTimeItem {
    var frame: CGRect
    var bounds: CGRect
    var layoutBounds: CGRect { return bounds }
    /// Layout item that maintains this layout entity
    weak var superItem: LayoutItem?
    /// Entity that represents item in layout time
    var inLayoutTime: InLayoutTimeItem { return self }
    /// Internal layout space of super item
    var superLayoutBounds: CGRect { return superItem!.bounds }

    init(frame: CGRect) {
        self.frame = frame
        self.bounds = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
    }

    /// Removes layout item from hierarchy
    func removeFromSuperItem() {
        superItem = nil
    }

    var sublayers: [Layer] = []
    var sublayoutItems: [LayoutItem]? { return sublayers }

    func addSubItem(_ subItem: SubItem<Layer>) {
        switch subItem {
        case .view(let view): sublayers.append(view.layer)
        case .layer(let layer): sublayers.append(layer)
        case .layoutGuide(let lg): add(layoutGuide: lg)
        }
    }
    func setNeedsLayout() {
        /// layout
    }

    func addSublayer(_ layer: Layer) {
        sublayers.append(layer)
    }

    func addChild(_ child: ChildItem) {
        child.add(to: self)
    }
}
extension Layer {
    /// Bind layout item to layout guide.
    ///
    /// - Parameter layoutGuide: Layout guide for binding
    func add<T: Layer>(layoutGuide: LayoutGuide<T>) {
        unsafeBitCast(layoutGuide, to: LayoutGuide<Layer>.self).ownerItem = self
    }
}

final class View: Container, InLayoutTimeItem {
    var layer: Layer
	var frame: CGRect
    var bounds: CGRect
    var layoutBounds: CGRect { return bounds }
    /// Layout item that maintains this layout entity
    weak var superItem: LayoutItem?
    /// Entity that represents item in layout time
    var inLayoutTime: InLayoutTimeItem { return self }

    /// Internal layout space of super item
    var superLayoutBounds: CGRect { return superItem!.bounds }

    init(layer: Layer) {
        self.layer = layer
        self.frame = layer.frame
        self.bounds = layer.bounds
    }

    convenience init(frame: CGRect) {
        self.init(layer: Layer(frame: frame))
    }

    /// Removes layout item from hierarchy
    func removeFromSuperItem() {
        superItem = nil
    }

    var subviews: [View] = []
    var sublayoutItems: [LayoutItem]?

    func addSubItem(_ subItem: SubItem<View>) {
        switch subItem {
        case .view(let view): 
            subviews.append(view)
            layer.addSubItem(.layer(view.layer))
        case .layer(let lr): layer.addSubItem(.layer(lr))
        case .layoutGuide(let lg): add(layoutGuide: lg)
        }
    }
    func setNeedsLayout() {
        layer.setNeedsLayout()
        /// layout
    }

    func addSubview(_ view: View) {
        subviews.append(view)
    }

    func addChild(_ child: ChildItem) {
        child.add(to: self)
    }
}
extension View {
    /// Bind layout item to layout guide.
    ///
    /// - Parameter layoutGuide: Layout guide for binding
    func add<T: View>(layoutGuide: LayoutGuide<T>) {
        unsafeBitCast(layoutGuide, to: LayoutGuide<View>.self).ownerItem = self
    }
}

class CGLayoutTests: XCTestCase {
    let bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
	func testTopAlignment() {
        let view1 = Layer(frame: CGRect(x: 230, y: 305, width: 200, height: 100))
        let view2 = Layer(frame: bounds)
        let alignment = Layout.Alignment.Vertical.top()

        alignment.formLayout(rect: &view1.frame, in: view2.frame)

        XCTAssertTrue(view1.frame.minY == view2.frame.minY)
    }

    func testContainer() {
        let layer = Layer(frame: CGRect(x: 230, y: 305, width: 200, height: 100))
        let view = View(layer: layer)
        let lg = LayoutGuide<View>(frame: .zero)
        let subview = View(frame: CGRect(x: 230, y: 305, width: 200, height: 100))

        view.addSubItem(.layoutGuide(lg))
        view.addSubItem(.view(subview))

        XCTAssertTrue(lg.ownerItem! === view)
        XCTAssertTrue(view.subviews.contains(where: { $0 === subview }))
        XCTAssertTrue(view.layer.sublayers.contains(where: { $0 === subview.layer }))
    }

    func testContainer2() {
        let layer = Layer(frame: CGRect(x: 230, y: 305, width: 200, height: 100))
        let view = View(layer: layer)
        let lg = LayoutGuide<View>(frame: .zero)
        let subview = View(frame: CGRect(x: 230, y: 305, width: 200, height: 100))

        view.addChild(lg)
        view.addChild(subview)

        XCTAssertTrue(lg.ownerItem! === view)
        XCTAssertTrue(view.subviews.contains(where: { $0 === subview }))
        XCTAssertTrue(view.layer.sublayers.contains(where: { $0 === subview.layer }))
    }

    static var allTests = [
        ("testTopAlignment", testTopAlignment),
        ("testContainer", testContainer),
        ("testContainer2", testContainer2)
    ]
}
