#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#elseif os(Linux)
import Foundation
#endif

#if os(Linux)

@testable import CGLayout

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
        guard let owner = item.superElement else {
            fatalError("Container \(type(of: item)) has not been added to hierarchy")
        }

        add(to: owner)
    }
    func add<C>(to item: C) where C: LayoutGuide<Layer> {
        guard let owner = item.superElement else {
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
        guard let owner = item.superElement else {
            fatalError("Container \(type(of: item)) has not been added to hierarchy")
        }

        add(to: owner)
    }
    func add<C>(to item: C) where C: LayoutGuide<Layer> {
        guard let owner = item.superElement else {
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

enum SubItem<Super: LayoutElement> {
    case view(View)
    case layer(Layer)
    case layoutGuide(LayoutGuideItem)
}
enum LayoutGuideItem {
    case inView(LayoutGuide<View>)
    case inLayer(LayoutGuide<Layer>)
    // case inLayoutGuide(LayoutGuide<Layo>)
}

protocol Container: LayoutElement {
    var subLayoutElements: [LayoutElement]? { get }
    // func addSubItem(_ subItem: SubItem<Self>)
    func addChild(_ child: ChildItem)
    func setNeedsLayout()
}

final class Layer: Container, ElementInLayoutTime {
    var frame: CGRect
    var bounds: CGRect
    var layoutBounds: CGRect { return bounds }
    /// Layout item that maintains this layout entity
    weak var superElement: LayoutElement?
    /// Entity that represents item in layout time
    var inLayoutTime: ElementInLayoutTime { return self }
    /// Internal layout space of super item
    var superLayoutBounds: CGRect { return superElement!.bounds }

    init(frame: CGRect) {
        self.frame = frame
        self.bounds = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
    }

    /// Removes layout item from hierarchy
    func removeFromSuperElement() {
        superElement = nil
    }

    var sublayers: [Layer] = []
    var subLayoutElements: [LayoutElement]? { return sublayers }

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
        layer.superElement = self
    }

    func addChild(_ child: ChildItem) {
        child.add(to: self)
    }
}
extension Layer: LayoutElementsContainer {
    func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : LayoutElement {}

    func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : LayoutGuide<Layer> {
        add(layoutGuide: subItem)
    }
    func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : Layer {
        addSublayer(subItem)
    }
    func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : View {
        addSublayer(subItem.layer)
        debugWarning("Adds 'View' element to 'Layer' element directly has ambiguous behavior")
    }
    /// Bind layout item to layout guide.
    ///
    /// - Parameter layoutGuide: Layout guide for binding
    func add<T: Layer>(layoutGuide: LayoutGuide<T>) {
        unsafeBitCast(layoutGuide, to: LayoutGuide<Layer>.self).ownerElement = self
    }
}

class View: Container, ElementInLayoutTime, LayoutElementsContainer {
    var layer: Layer
	var frame: CGRect
    var bounds: CGRect
    var layoutBounds: CGRect { return bounds }
    /// Layout item that maintains this layout entity
    weak var superElement: LayoutElement?
    /// Entity that represents item in layout time
    var inLayoutTime: ElementInLayoutTime { return self }
    /// Internal layout space of super item
    var superLayoutBounds: CGRect { return superElement!.bounds }

    init(layer: Layer) {
        self.layer = layer
        self.frame = layer.frame
        self.bounds = layer.bounds
    }

    convenience init(frame: CGRect = .zero) {
        self.init(layer: Layer(frame: frame))
    }

    /// Removes layout item from hierarchy
    func removeFromSuperElement() {
        superElement = nil
    }

    var subviews: [View] = []
    var subLayoutElements: [LayoutElement]?

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
        view.superElement = self
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
        unsafeBitCast(layoutGuide, to: LayoutGuide<View>.self).ownerElement = self
    }
    func add(layoutGuide: LayoutGuide<View>) {
        layoutGuide.ownerElement = self
    }

    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : LayoutElement {}

    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : LayoutGuide<Layer> {
        layer.add(layoutGuide: subItem)
    }
    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : LayoutGuide<View> {
        add(layoutGuide: subItem)
    }
    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : Layer {
        layer.addSublayer(subItem)
    }
    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : View {
        addSubview(subItem)
    }
}
extension StackLayoutGuide where Parent: View {
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter item: Layout guide for addition.
    func addArrangedElement<T: View>(_ item: LayoutGuide<T>) { insertArrangedElement(item, at: items.count) }
    /// Inserts a item to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - item: Layout guide for addition
    ///   - index: Index in list.
    func insertArrangedElement<T: View>(_ item: LayoutGuide<T>, at index: Int) {
        ownerElement?.addChildElement(unsafeBitCast(item, to: LayoutGuide<View>.self))
        items.insert(item, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter item: Layout guide for removing.
    func removeArrangedElement<T: View>(_ item: LayoutGuide<T>) {
        guard removeItem(item), ownerElement === item.superElement else { return }
        item.removeFromSuperElement()
    }
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter item: Layout guide for addition.
    func addArrangedElement<T: Layer>(_ item: LayoutGuide<T>) { insertArrangedElement(item, at: items.count) }
    /// Inserts a item to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - item: Layout guide for addition
    ///   - index: Index in list.
    func insertArrangedElement<T: Layer>(_ item: LayoutGuide<T>, at index: Int) {
        ownerElement?.addChildElement(unsafeBitCast(item, to: LayoutGuide<Layer>.self))
        items.insert(item, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter item: Layout guide for removing.
    func removeArrangedElement<T: Layer>(_ item: LayoutGuide<T>) {
        guard removeItem(item), ownerElement?.layer === item.superElement else { return }
        item.removeFromSuperElement()
    }
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter item: View for addition.
    func addArrangedElement(_ item: View) { insertArrangedElement(item, at: items.count) }
    /// Inserts a item to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - item: View for addition
    ///   - index: Index in list.
    func insertArrangedElement(_ item: View, at index: Int) {
        ownerElement?.addChildElement(item)
        items.insert(item, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter item: View for removing.
    func removeArrangedElement(_ item: View) {
        guard removeItem(item), ownerElement === item.superElement else { return }
        item.removeFromSuperElement()
    }
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter item: Layer for addition.
    func addArrangedElement(_ item: Layer) { insertArrangedElement(item, at: items.count) }
    /// Inserts a item to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - item: Layer for addition
    ///   - index: Index in list.
    func insertArrangedElement(_ item: Layer, at index: Int) {
        ownerElement?.addChildElement(item)
        items.insert(item, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter item: Layer for removing.
    func removeArrangedElement(_ item: Layer) {
        guard removeItem(item), ownerElement?.layer === item.superElement else { return }
        item.removeFromSuperElement()
    }
}
class Window: View {
    // override weak var superElement: LayoutElement? {
    //     set {}
    //     get { return self }
    // }
    override func addChild<P: EnterPoint>(from point: P) where P.Container == Window {
        point.add(to: self)
    }
}
class Label: View, AdjustableLayoutElement, TextPresentedElement {
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
extension LayoutElement where Self: Label {
    func baselineLayoutConstraint(for anchors: [LayoutAnchor]) -> BaselineLayoutConstraint {
        return BaselineLayoutConstraint(element: self, constraints: anchors.map { $0.constraint })
    }
}
extension LayoutElement where Self: Window {
    /// Convenience getter for constraint item related to this entity
    ///
    /// - Parameter anchors: Array of anchor constraints
    /// - Returns: Related constraint item
    func layoutConstraint(for anchors: [RectBasedConstraint]) -> WindowLayoutConstraint {
        return WindowLayoutConstraint(item: self, constraints: anchors)
    }
}

public class WindowLayoutConstraint: LayoutConstraintProtocol {
    fileprivate let constraints: [RectBasedConstraint]
    private(set) weak var item: LayoutElement?
    internal var inLayoutTimeItem: ElementInLayoutTime? {
        return item?.inLayoutTime
    }

    public init(item: LayoutElement, constraints: [RectBasedConstraint]) {
        self.item = item
        self.constraints = constraints
    }

    public var isActive: Bool { return inLayoutTimeItem != nil }

    public
    var isIndependent: Bool { return false }

    public
    func layoutElement(is object: AnyObject) -> Bool {
        return item === object
    }

    public
    func constrainRect(for currentSpace: CGRect, in coordinateSpace: LayoutElement) -> CGRect {
        guard let layoutItem = inLayoutTimeItem else { fatalError("Constraint has not access to layout item or him super item. /n\(self)") }

        return convert(rectIfNeeded: layoutItem.frame, to: coordinateSpace)
    }

    public
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        sourceRect = sourceRect.constrainedBy(rect: rect, use: constraints)
    }

    public
    func convert(rectIfNeeded rect: CGRect, to coordinateSpace: LayoutElement) -> CGRect {
        guard let layoutItem = item else { fatalError("Constraint has not access to layout item or him super item. /n\(self)") }
        return coordinateSpace === item ? rect : coordinateSpace.convert(rect: rect, from: layoutItem)
    }
}

/// anchors

extension View: AnchoredLayoutElement {   
}
extension LayoutElement where Self: View {
    func block(with layout: (inout LayoutAnchors<Self>) -> Void) -> LayoutBlock<Self> {
        var anchors = unsafeBitCast(self.layoutAnchors, to: LayoutAnchors<Self>.self)
        layout(&anchors)
        return LayoutBlock(element: self, layout: Layout.equal, constraints: anchors.constraints { v, constraints in
            return (v as? Window)?.layoutConstraint(for: constraints) ?? (LayoutConstraint(element: v, constraints: constraints) as LayoutConstraintProtocol)
        })
    }
}

#endif
