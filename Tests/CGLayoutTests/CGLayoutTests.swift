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
    func add<C>(to item: C) where C: LayoutGuide<View> {
        guard let owner = item.superItem else {
            fatalError("Container \(type(of: item)) has not been added to hierarchy")
        }

        add(to: owner)
    }
    func add<C>(to item: C) where C: LayoutGuide<Layer> {
        guard let owner = item.superItem else {
            fatalError("Container \(type(of: item)) has not been added to hierarchy")
        }

        add(to: owner)
    }
    func add<C>(to item: C) {
        fatalError("Not supported container \(type(of: item)) for child \(type(of: self)). Implement func add<C>(to:) where C: \(type(of: item))")
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
    func add<C>(to item: C) where C: LayoutGuide<View> {
        guard let owner = item.superItem else {
            fatalError("Container \(type(of: item)) has not been added to hierarchy")
        }

        add(to: owner)
    }
    func add<C>(to item: C) where C: LayoutGuide<Layer> {
        guard let owner = item.superItem else {
            fatalError("Container \(type(of: item)) has not been added to hierarchy")
        }

        add(to: owner)
    }
    func add<C>(to item: C) {
        fatalError("Not supported container \(type(of: item)) for child \(type(of: self)). Implement func add<C>(to:) where C: \(type(of: item))")
    }
}

extension LayoutGuide: ChildItem {
    func add<C>(to item: C) where C: Layer, Super: Layer {
        item.add(layoutGuide: self)
    }
    func add<C>(to item: C) where C: View, Super: View {
        item.add(layoutGuide: self)
    }
    func add<C>(to item: C) where C: View, Super: Layer {
        item.layer.add(layoutGuide: self)
    }
    func add<C: Container>(to item: C) where C: LayoutGuide {
        item.add(layoutGuide: self)
    }
    func add<C>(to item: C) {
        fatalError("Not supported container \(type(of: item)) for child \(type(of: self)). Implement func add<C>(to:) where C: \(type(of: item))")
    }
}

enum SubItem<Super: LayoutItem> {
    case view(View)
    case layer(Layer)
    case layoutGuide(LayoutGuide<Super>)
}

protocol Container: LayoutItem {
    var sublayoutItems: [LayoutItem]? { get }
    // func addSubItem(_ subItem: SubItem<Self>)
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

class View: Container, InLayoutTimeItem {
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
        view.superItem = self
    }

    func addChild(_ child: ChildItem) {
        child.add(to: self)
    }

    // TODO: Temporary
    lazy var layoutAnchors: LayoutAnchors<View> = LayoutAnchors(self)
}
extension View {
    func addChild(_ child: View) {
        child.add(to: self)
    }
    func addChild(_ child: LayoutGuide<View>) {
        child.add(to: self)
    }
    func addChild(_ child: LayoutGuide<Layer>) {
        child.add(to: self)
    }
    /// Bind layout item to layout guide.
    ///
    /// - Parameter layoutGuide: Layout guide for binding
    func add<T: View>(layoutGuide: LayoutGuide<T>) {
        unsafeBitCast(layoutGuide, to: LayoutGuide<View>.self).ownerItem = self
    }
}
class Window: View {
    // override weak var superItem: LayoutItem? {
    //     set {}
    //     get { return self }
    // }
}
class Label: View, AdjustableLayoutItem, TextPresentedItem {
    var text: String?
    var contentConstraint: RectBasedConstraint {
        struct Constraint: RectBasedConstraint {
            weak var this: Label!
            func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
                let widthSymbol: CGFloat = 5.0
                let heightSymbol: CGFloat = 15.0
                sourceRect.size = CGSize(width: rect.size.width, 
                                         height: this.text.map { heightSymbol * floor(rect.size.width / (CGFloat($0.count) * widthSymbol)) } ?? 0)
            }
        }
        return Constraint(this: self)
    }

    var baselinePosition: CGFloat = 14.0
}
extension LayoutItem where Self: Label {
    func baselineLayoutConstraint(for anchors: [RectBasedConstraint]) -> BaselineLayoutConstraint {
        var constraint = BaselineLayoutConstraint(item: self, constraints: anchors)
        constraint.inLayoutTime = inLayoutTime
        return constraint
    }
}
extension LayoutItem where Self: Window {
    /// Convenience getter for constraint item related to this entity
    ///
    /// - Parameter anchors: Array of anchor constraints
    /// - Returns: Related constraint item
    func layoutConstraint(for anchors: [RectBasedConstraint]) -> WindowLayoutConstraint {
        return WindowLayoutConstraint(item: self, constraints: anchors)
    }
}
extension LayoutItem where Self: View {
    func layout(with relating: (inout RectAnchorDefining) -> Void) -> LayoutBlock<Self> {
        var anchors = self.anchors
        relating(&anchors)
        return LayoutBlock(item: self, layout: Layout.equal, constraints: anchors.constraints.map { item, constraints -> LayoutConstraintProtocol in
            let constraint = item.map({ v -> LayoutConstraintProtocol in
                return (v as? Window)?.layoutConstraint(for: constraints) ?? v.layoutConstraint(for: constraints) 
            }) 
            return constraint ?? AnonymConstraint(anchors: constraints)
        })
    }
}

public class WindowLayoutConstraint: LayoutConstraintProtocol {
    fileprivate let constraints: [RectBasedConstraint]
    private(set) weak var item: LayoutItem?
    internal var inLayoutTimeItem: InLayoutTimeItem? {
        return item?.inLayoutTime
    }

    public init(item: LayoutItem, constraints: [RectBasedConstraint]) {
        self.item = item
        self.constraints = constraints
    }

    public var isActive: Bool { return inLayoutTimeItem != nil }

    public
    var isIndependent: Bool { return false }

    public
    func layoutItem(is object: AnyObject) -> Bool {
        return item === object
    }

    public
    func constrainRect(for currentSpace: CGRect, in coordinateSpace: LayoutItem) -> CGRect {
        guard let layoutItem = inLayoutTimeItem else { fatalError("Constraint has not access to layout item or him super item. /n\(self)") }

        return convert(rectIfNeeded: layoutItem.frame, to: coordinateSpace)
    }

    public
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        sourceRect = sourceRect.constrainedBy(rect: rect, use: constraints)
    }

    public
    func convert(rectIfNeeded rect: CGRect, to coordinateSpace: LayoutItem) -> CGRect {
        guard let layoutItem = item else { fatalError("Constraint has not access to layout item or him super item. /n\(self)") }
        return coordinateSpace === item ? rect : coordinateSpace.convert(rect: rect, from: layoutItem)
    }
}

/// anchors

extension View: AnchoredItem {
    private static var anchors: RectAnchors = RectAnchors(nil)
    public var anchors: RectAnchorDefining { return View.anchors.with(self) }
    public struct RectAnchors: RectAnchorDefining {
        var view: View? {
            didSet {
                if let view = view {
                    bind(view)
                }
            }
        }
        init(_ view: View?) {
            self.view = view
            if let view = view {
                self.bind(view)
            }
        }
        public var left: AssociatedAnchor<LeftAnchor> = .init(item: nil, anchor: .init())
        public var right: AssociatedAnchor<RightAnchor> = .init(item: nil, anchor: .init())
        public var bottom: AssociatedAnchor<VerticalAnchor> = .init(item: nil, anchor: .init(BottomAnchor()))
        public var top: AssociatedAnchor<VerticalAnchor> = .init(item: nil, anchor: .init(TopAnchor()))
        public var leading: AssociatedAnchor<HorizontalAnchor> = .init(item: nil, anchor: .init(LeftAnchor()))
        public var trailing: AssociatedAnchor<HorizontalAnchor> = .init(item: nil, anchor: .init(RightAnchor()))
        public var center: AssociatedAnchor<CenterAnchor> = .init(item: nil, anchor: .init())
        public var width: AssociatedAnchor<WidthAnchor> = .init(item: nil, anchor: .width)
        public var height: AssociatedAnchor<HeightAnchor> = .init(item: nil, anchor: .height)
        public var size: AssociatedAnchor<SizeAnchor> = .init(item: nil, anchor: .init())
        public var origin: AssociatedAnchor<OriginAnchor> = .init(item: nil, anchor: .init(horizontalAnchor: .init(LeftAnchor()), verticalAnchor: .init(TopAnchor())))

        mutating func loadTrailingLeading() {
            guard let view = view else { return }
            let left: AssociatedAnchor<HorizontalAnchor> = .init(item: nil, anchor: .init(LeftAnchor()))
            let right: AssociatedAnchor<HorizontalAnchor> = .init(item: nil, anchor: .init(RightAnchor()))
            // leading = View.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft ? right : left
            // trailing = View.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft ? left : right
            leading = left
            trailing = right
        }

        func with(_ view: View) -> RectAnchors {
            var anchors = self
            anchors.view = view
            return anchors
        }
        private mutating func bind(_ view: View) {
            left.item = view
            right.item = view
            bottom.item = view
            top.item = view
            loadTrailingLeading()
            center.item = view
            width.item = view
            height.item = view
            size.item = view
            origin.item = view
        }
    }
}

extension View: AnchoredLayoutItem {   
}
extension LayoutItem where Self: View {
    func block(with layout: (inout LayoutAnchors<Self>) -> Void) -> LayoutBlock<Self> {
        var anchors = unsafeBitCast(self.layoutAnchors, to: LayoutAnchors<Self>.self)
        layout(&anchors)
        return LayoutBlock(item: self, layout: Layout.equal, constraints: anchors.constraints { v, constraints in
            return (v as? Window)?.layoutConstraint(for: constraints) ?? v.layoutConstraint(for: constraints)
        })
    }
}

class CGLayoutTests: XCTestCase {
    let bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
	func testTopAlignment() {
        let view1 = Layer(frame: CGRect(x: 230, y: 305, width: 200, height: 100))
        let view2 = Layer(frame: bounds)
        let alignment = Layout.Alignment.Vertical.top()

        alignment.formLayout(rect: &view1.frame, in: view2.frame)

        XCTAssertTrue(view1.frame.origin.y == view2.frame.origin.y)
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
        // lg.add(to: view)
        // subview.add(to: view)

        XCTAssertTrue(lg.ownerItem! === view)
        XCTAssertTrue(view.subviews.contains(where: { $0 === subview }))
        XCTAssertTrue(view.layer.sublayers.contains(where: { $0 === subview.layer }))
    }

    func testTextPresented() {
        let window = Window(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let view = View(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        let label = Label(frame: CGRect(x: 0, y: 100, width: 200, height: 50))
        window.addSubview(view)
        window.addSubview(label)

        let viewLayout = view.layoutBlock(constraints: [label.baselineLayoutConstraint(for: [LayoutAnchor.Bottom.align(by: .inner)])])

        viewLayout.layout()

        // print(view.frame)
        XCTAssertTrue(view.frame.maxY == 100 + label.baselinePosition)
    }

    func testTextPresented2() {
        let window = Window(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let label1 = Label(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        let label2 = Label(frame: CGRect(x: 0, y: 100, width: 200, height: 50))
        label1.baselinePosition = 35.0
        window.addSubview(label1)
        window.addSubview(label2)

        let label1Layout = label1.layoutBlock(constraints: [label2.baselineLayoutConstraint(for: [LayoutAnchor.Baseline.align(of: label1)])])

        label1Layout.layout()

        print(label1.frame)
        XCTAssertTrue(label1.frame.minY == 100 + label2.baselinePosition - label1.baselinePosition)
    }

    func testNewAnchors() {
        let window = Window(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let sourceView = View(frame: CGRect(x: 100, y: 100, width: 300, height: 300))
        let targetView = View(frame: .zero)
        window.addSubview(sourceView)
        sourceView.addSubview(targetView)
        let layout = targetView.layout { (anchors) in
            anchors.size.equal(to: CGSize(width: 200, height: 40))
            anchors.center.align(by: sourceView.anchors.center)
            // anchors.top.align(by: sourceView.anchors.bottom)
            // anchors.origin.align(by: associatedView.anchors.origin)
            // anchors.top.align(by: window.anchors.top)
            // anchors.bottom.pull(to: sourceView.anchors.bottom)
        }

        // print("Before: ", targetView.frame)
        layout.layout()
        // print("After: ", targetView.frame)

        XCTAssertTrue(targetView.frame.origin.x == ((500 - 200) - 200) / 2)
        XCTAssertTrue(targetView.frame.origin.y == ((500 - 200) - 40) / 2)
        XCTAssertTrue(targetView.frame.size.width == 200)
        XCTAssertTrue(targetView.frame.size.height == 40)
    }

    func testNewAnchors2() {
        let window = Window(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let sourceView = View(frame: CGRect(x: 100, y: 100, width: 300, height: 300))
        let targetView = View(frame: .zero)
        window.addSubview(sourceView)
        sourceView.addSubview(targetView)
        let layout = targetView.block { (anchors) in
            anchors.width.equal(to: 200)
            anchors.height.equal(to: 40)
            anchors.centerX.align(by: sourceView.layoutAnchors.centerX)
            anchors.centerY.align(by: sourceView.layoutAnchors.centerY)
        }

        // print("Before: ", targetView.frame)
        layout.layout()
        // print("After: ", targetView.frame)

        XCTAssertTrue(targetView.frame.origin.x == ((500 - 200) - 200) / 2)
        XCTAssertTrue(targetView.frame.origin.y == ((500 - 200) - 40) / 2)
        XCTAssertTrue(targetView.frame.size.width == 200)
        XCTAssertTrue(targetView.frame.size.height == 40)
    }

    func testNewAnchors3() {
        let window = Window(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let sourceView = View(frame: CGRect(x: 100, y: 100, width: 300, height: 300))
        let targetView = View(frame: .zero) 
        window.addSubview(sourceView)
        sourceView.addSubview(targetView)
        let layout = targetView.block { (anchors) in
            // anchors.centerY.align(by: sourceView.layoutAnchors.centerY) // 4
            anchors.height.scaled(by: sourceView.layoutAnchors.height, scale: 0.5) // 3
            anchors.left.pull(to: sourceView.layoutAnchors.centerX) // 1
            anchors.right.pull(to: sourceView.layoutAnchors.right) // 5, conflicted and broken down #2
            // anchors.width.equal(to: 300) // 2
            // anchors.top.limit(by: sourceView.layoutAnchors.centerY) // 6, conflicted and broken down #3, #4
            // anchors.top.align(by: sourceView.layoutAnchors.centerY)
            anchors.top.fartherThanOrEqual(to: sourceView.layoutAnchors.centerY)

            // print(anchors.constraints.reduce(CGRect.zero, { current, constraints in
            //     print(current)
            //     return current.constrainedBy(rect: sourceView.bounds, use: constraints)
            // }))
        }

        // print("Before: ", targetView.frame)
        layout.layout()
        // print("After: ", targetView.frame)

        XCTAssertTrue(targetView.frame.origin.x == 150)
        XCTAssertTrue(targetView.frame.origin.y == 150)
        XCTAssertTrue(targetView.frame.size.width == 150)
        XCTAssertTrue(targetView.frame.size.height == 150)
    }

    func testNewAnchors4() {
        let window = Window(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let sourceView = View(frame: CGRect(x: 100, y: 100, width: 300, height: 300))
        let targetView = Label(frame: .zero)
        targetView.text = "Test label intrinsic size"
        window.addSubview(sourceView)
        sourceView.addSubview(targetView)

        let layout = targetView.block { (anchors) in
            // anchors.centerY.align(by: sourceView.layoutAnchors.centerY) // 4
            anchors.height.equalIntrinsicSize() // 3
            anchors.left.pull(to: sourceView.layoutAnchors.centerX) // 1
            anchors.right.pull(to: sourceView.layoutAnchors.right) // 5, conflicted and broken down #2
            // anchors.width.equalIntrinsicSize() // 2
            // anchors.top.limit(by: sourceView.layoutAnchors.centerY) // 6, conflicted and broken down #3, #4
            anchors.top.align(by: sourceView.layoutAnchors.centerY)

            // print(anchors.constraints.reduce(CGRect.zero, { current, constraints in
            //     print(current)
            //     return current.constrainedBy(rect: sourceView.bounds, use: constraints)
            // }))
        }

        // print("Before: ", targetView.frame)
        layout.layout()
        // print("After: ", targetView.frame)

        XCTAssertTrue(targetView.frame.origin.x == 150)
        XCTAssertTrue(targetView.frame.origin.y == 150)
        XCTAssertTrue(targetView.frame.size.width == 150)
        let height = targetView.contentConstraint.constrained(sourceRect: .zero, by: CGRect(x: 0, y: 0, width: 150, height: 0)).size.height
        XCTAssertTrue(targetView.frame.size.height == height)
    }

    static var allTests = [
        ("testTopAlignment", testTopAlignment),
        ("testContainer", testContainer),
        ("testContainer2", testContainer2),
        ("testTextPresented", testTextPresented),
        ("testTextPresented2", testTextPresented2),
        ("testNewAnchors", testNewAnchors),
        ("testNewAnchors2", testNewAnchors2),
        ("testNewAnchors3", testNewAnchors3),
        ("testNewAnchors4", testNewAnchors4)
    ]
}
