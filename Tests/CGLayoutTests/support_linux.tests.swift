import Foundation
@testable import CGLayout

extension CGRect {
    static func random(in source: CGRect) -> CGRect {
        let randomValue: (CGFloat) -> CGFloat = { pattern -> CGFloat in
            #if os(Linux)
                return CGFloat(SwiftGlibc.random() % Int(pattern))
            #else
                return CGFloat(arc4random_uniform(UInt32(pattern)))
            #endif
        }
        let o = CGPoint(x: randomValue(source.width), y: randomValue(source.height))
        let s = CGSize(width: randomValue(source.width - o.x), height: randomValue(source.height - o.y))

        return CGRect(origin: o, size: s)
    }
}

/// The container does not know which child is being added,
/// but the child knows exactly where it is being added
#if os(Linux)

class ContainerEnterPoint {
    func add(to view: View) {
        fatalError("Not implemented")
    }
}
class AnyEnterPoint<C: LayoutItem>: ContainerEnterPoint {    
    let child: C

    init(_ child: C) {
        self.child = child
    }
}
class ViewEnterPoint: AnyEnterPoint<View> {
    override func add(to view: View) {
        view.addSubview(child)
    }
}
class LayoutGuideEnterPoint: AnyEnterPoint<LayoutGuide<View>> {
    override func add(to view: View) {
        view.add(layoutGuide: child)
    }
}

protocol EnterPoint {
    associatedtype Container
    func add(to container: Container)
}

struct AnyEnter<Child, Container> {
    let child: Child
}
extension AnyEnter: EnterPoint where Child: View, Container: View {
    func add(to container: Container) {
        container.addSubview(child)
    }
}
extension LayoutGuide: EnterPoint where Super: View {
    typealias Container = View
    func add(to container: View) {
        container.add(layoutGuide: self)
    }
}
// extension LayoutGuide: EnterPoint where Super: Layer {
//     // typealias Container = Layer
//     func add(to container: Layer) {
//         container.add(layoutGuide: self)
//     }
// }
extension AnyEnter where Child: LayoutGuide<View>, Container: View { // TODO: EnterPoint redundant conformane resolved in swift 4.2
    func add(to container: Container) {
        container.add(layoutGuide: child)
    }
}
extension AnyEnter where Child: View, Container == Window {
    func add(to container: Container) {
        container.addSubview(child)
        print("Added \(child) to window \(container)")
    }
}

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

    func add<C>(to item: C) where C: Window {
        print("Added to window: \(item)")
        item.addSubview(self)
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
    func add<C>(to item: C) {
        fatalError("Not supported container \(type(of: item)) for child \(type(of: self)). Implement func add<C>(to:) where C: \(type(of: item))")
    }
}

enum SubItem<Super: LayoutItem> {
    case view(View)
    case layer(Layer)
    case layoutGuide(LayoutGuideItem)
}
enum LayoutGuideItem {
    case inView(LayoutGuide<View>)
    case inLayer(LayoutGuide<Layer>)
    // case inLayoutGuide(LayoutGuide<Layo>)
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
        case .layoutGuide(let lg):
            switch lg {
            case .inView(let lg):
                fatalError("Layer cannot add layout guide with 'View' type")
                // add(layoutGuide: lg)
            case .inLayer(let lg):
                add(layoutGuide: lg)
            }
        }
    }
    func setNeedsLayout() {
        /// layout
    }

    func addSublayer(_ layer: Layer) {
        sublayers.append(layer)
        layer.superItem = self
    }

    func addChild(_ child: ChildItem) {
        child.add(to: self)
    }
}
extension Layer: LayoutItemContainer {
    func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutItem {}

    func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutGuide<Layer> {
        add(layoutGuide: subItem)
    }
    func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : Layer {
        addSublayer(subItem)
    }
    func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : View {
        addSublayer(subItem.layer)
        debugWarning("Adds 'View' element to 'Layer' element directly has ambiguous behavior")
    }
    /// Bind layout item to layout guide.
    ///
    /// - Parameter layoutGuide: Layout guide for binding
    func add<T: Layer>(layoutGuide: LayoutGuide<T>) {
        unsafeBitCast(layoutGuide, to: LayoutGuide<Layer>.self).ownerItem = self
    }
}

class View: Container, InLayoutTimeItem, LayoutItemContainer {
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

    convenience init(frame: CGRect = .zero) {
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
        case .layoutGuide(let lg):
            switch lg {
            case .inView(let lg):
                add(layoutGuide: lg)
            case .inLayer(let lg):
                layer.add(layoutGuide: lg)
            }
        }
    }
    func setNeedsLayout() {
        layer.setNeedsLayout()
        /// layout
    }

    func addSubview(_ view: View) {
        layer.addSublayer(view.layer)
        subviews.append(view)
        view.superItem = self
    }

    func addChild(_ child: ChildItem) {
        child.add(to: self)
    }

    func addChild(from enterPoint: ContainerEnterPoint) {
        enterPoint.add(to: self)
    }

    func addChild<P: EnterPoint>(from point: P) where P.Container == View {
        point.add(to: self)
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
    func add(layoutGuide: LayoutGuide<View>) {
        layoutGuide.ownerItem = self
    }

    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutItem {}

    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutGuide<Layer> {
        layer.add(layoutGuide: subItem)
    }
    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutGuide<View> {
        add(layoutGuide: subItem)
    }
    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : Layer {
        layer.addSublayer(subItem)
    }
    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : View {
        addSubview(subItem)
    }
}
extension StackLayoutGuide where Parent: View {
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter item: Layout guide for addition.
    func addArrangedItem<T: View>(_ item: LayoutGuide<T>) { insertArrangedItem(item, at: items.count) }
    /// Inserts a item to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - item: Layout guide for addition
    ///   - index: Index in list.
    func insertArrangedItem<T: View>(_ item: LayoutGuide<T>, at index: Int) {
        ownerItem?.addSublayoutItem(unsafeBitCast(item, to: LayoutGuide<View>.self))
        items.insert(item, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter item: Layout guide for removing.
    func removeArrangedItem<T: View>(_ item: LayoutGuide<T>) {
        guard removeItem(item), ownerItem === item.superItem else { return }
        item.removeFromSuperItem()
    }
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter item: Layout guide for addition.
    func addArrangedItem<T: Layer>(_ item: LayoutGuide<T>) { insertArrangedItem(item, at: items.count) }
    /// Inserts a item to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - item: Layout guide for addition
    ///   - index: Index in list.
    func insertArrangedItem<T: Layer>(_ item: LayoutGuide<T>, at index: Int) {
        ownerItem?.addSublayoutItem(unsafeBitCast(item, to: LayoutGuide<Layer>.self))
        items.insert(item, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter item: Layout guide for removing.
    func removeArrangedItem<T: Layer>(_ item: LayoutGuide<T>) {
        guard removeItem(item), ownerItem?.layer === item.superItem else { return }
        item.removeFromSuperItem()
    }
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter item: View for addition.
    func addArrangedItem(_ item: View) { insertArrangedItem(item, at: items.count) }
    /// Inserts a item to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - item: View for addition
    ///   - index: Index in list.
    func insertArrangedItem(_ item: View, at index: Int) {
        ownerItem?.addSublayoutItem(item)
        items.insert(item, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter item: View for removing.
    func removeArrangedItem(_ item: View) {
        guard removeItem(item), ownerItem === item.superItem else { return }
        item.removeFromSuperItem()
    }
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter item: Layer for addition.
    func addArrangedItem(_ item: Layer) { insertArrangedItem(item, at: items.count) }
    /// Inserts a item to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - item: Layer for addition
    ///   - index: Index in list.
    func insertArrangedItem(_ item: Layer, at index: Int) {
        ownerItem?.addSublayoutItem(item)
        items.insert(item, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter item: Layer for removing.
    func removeArrangedItem(_ item: Layer) {
        guard removeItem(item), ownerItem?.layer === item.superItem else { return }
        item.removeFromSuperItem()
    }
}
class Window: View {
    // override weak var superItem: LayoutItem? {
    //     set {}
    //     get { return self }
    // }
    override func addChild<P: EnterPoint>(from point: P) where P.Container == Window {
        point.add(to: self)
    }
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

#endif
