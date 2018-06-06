//
//  CGLayoutExtended.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 04/09/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

import Foundation

// TODO: !!! LayoutGuide does not have link to super layout guide. For manage z-index subitems.

// MARK: LayoutGuide and placeholders

/// LayoutGuides will not show up in the view hierarchy, but may be used as layout item in
/// an `RectBasedConstraint` and represent a rectangle in the layout engine.
/// Create a LayoutGuide with -init
/// Add to a view with UIView.add(layoutGuide:)
/// If you use subclass LayoutGuide, that manages `LayoutItem` items, than you should use 
/// `layout(in: frame)` method for apply layout, otherwise items will be have wrong position.
open class LayoutGuide<Super: LayoutItem>: LayoutItem, InLayoutTimeItem {
    public /// Internal layout space of super item
    var superLayoutBounds: CGRect { return superItem!.layoutBounds }
    public /// Entity that represents item in layout time
    var inLayoutTime: InLayoutTimeItem { return self }
    public /// Internal space for layout subitems
    var layoutBounds: CGRect { return CGRect(origin: CGPoint(x: frame.origin.x + bounds.origin.x, y: frame.origin.y + bounds.origin.y), size: bounds.size) }

    /// Layout item where added this layout guide. For addition use `func add(layoutGuide:)`.
    open internal(set) weak var ownerItem: Super? {
        didSet { superItem = ownerItem; didAddToOwner() }
    }
    open /// External representation of layout entity in coordinate space
    var frame: CGRect { didSet { if oldValue != frame { bounds = contentRect(forFrame: frame) } } } // TODO: if calculated frame does not changed subviews don`t update (UILabel)
    open /// Internal coordinate space of layout entity
    var bounds: CGRect { didSet { layout() } }
    open /// Layout item that maintained this layout entity
    weak var superItem: LayoutItem?
    open /// Removes layout item from hierarchy
    func removeFromSuperItem() { ownerItem = nil }

    public init(frame: CGRect) {
        self.frame = frame
        self.bounds = CGRect(origin: .zero, size: frame.size)
    }

    /// Tells that a this layout guide was added to owner
    open func didAddToOwner() {
        // subclass override
    }

    /// Performs layout for subitems, which this layout guide manages, in layout space rect
    ///
    /// - Parameter rect: Space for layout
    open func layout(in rect: CGRect) {
        // subclass override
    }

    /// Defines rect for `bounds` property. Calls on change `frame`.
    ///
    /// - Parameter frame: New frame value.
    /// - Returns: Content rect
    open func contentRect(forFrame frame: CGRect) -> CGRect {
        return CGRect(origin: .zero, size: frame.size)
    }

    internal func layout() {
        layout(in: layoutBounds)
    }
}

#if os(iOS) || os(tvOS)
public extension LayoutGuide where Super: UIView {
    /// Fabric method for generation layer with any type
    ///
    /// - Parameter type: Type of layer
    /// - Returns: Generated layer
    func build<L: CALayer>(_ type: L.Type) -> L {
        let layer = L()
        layer.frame = frame
        return layer
    }
    /// Generates layer and adds to `superItem` hierarchy
    ///
    /// - Parameter type: Type of layer
    /// - Returns: Added layer
    @discardableResult
    func add<L: CALayer>(_ type: L.Type) -> L? {
        guard let superItem = ownerItem else { fatalError("You must add layout guide to container using `func add(layoutGuide:)` method") }

        let layer = build(type)
        superItem.layer.addSublayer(layer)
        return layer
    }
    /// Fabric method for generation view with any type
    ///
    /// - Parameter type: Type of view
    /// - Returns: Generated view
    func build<V: UIView>(_ type: V.Type) -> V { return V(frame: frame) }
    /// Generates view and adds to `superItem` hierarchy
    ///
    /// - Parameter type: Type of view
    /// - Returns: Added view
    @discardableResult
    func add<V: UIView>(_ type: V.Type) -> V? {
        guard let superItem = ownerItem else { fatalError("You must add layout guide to container using `func add(layoutGuide:)` method") }

        let view = build(type)
        superItem.addSubview(view)
        return view
    }
}
#endif
#if os(macOS) || os(iOS) || os(tvOS)
public extension LayoutGuide where Super: CALayer {
    /// Fabric method for generation layer with any type
    ///
    /// - Parameter type: Type of layer
    /// - Returns: Generated layer
    func build<L: CALayer>(_ type: L.Type) -> L {
        let layer = L()
        layer.frame = frame
        return layer
    }
    /// Generates layer and adds to `superItem` hierarchy
    ///
    /// - Parameter type: Type of layer
    /// - Returns: Added layer
    @discardableResult
    func add<L: CALayer>(_ type: L.Type) -> L? {
        guard let superItem = ownerItem else { fatalError("You must add layout guide to container using `func add(layoutGuide:)` method") }

        let layer = build(type)
        superItem.addSublayer(layer)
        return layer
    }
}
public extension CALayer {
    /// Bind layout item to layout guide.
    ///
    /// - Parameter layoutGuide: Layout guide for binding
    func add<T: CALayer>(layoutGuide: LayoutGuide<T>) {
        unsafeBitCast(layoutGuide, to: LayoutGuide<CALayer>.self).ownerItem = self
    }
}
#endif
#if os(iOS) || os(tvOS)
public extension UIView {
    /// Bind layout item to layout guide.
    ///
    /// - Parameter layoutGuide: Layout guide for binding
    func add<T: UIView>(layoutGuide: LayoutGuide<T>) {
        unsafeBitCast(layoutGuide, to: LayoutGuide<UIView>.self).ownerItem = self
    }
}
#endif
#if os(macOS)
    public extension NSView {
        /// Bind layout item to layout guide.
        ///
        /// - Parameter layoutGuide: Layout guide for binding
        func add<T: NSView>(layoutGuide: LayoutGuide<T>) {
            unsafeBitCast(layoutGuide, to: LayoutGuide<NSView>.self).ownerItem = self
        }
    }
#endif
public extension LayoutGuide {
    /// Creates dependency between two layout guides.
    ///
    /// - Parameter layoutGuide: Child layout guide.
    func add(layoutGuide: LayoutGuide<Super>) {
        layoutGuide.ownerItem = self.ownerItem
    }
}

// MARK: Placeholders

// TODO: Add possible to make lazy configuration

/// Base class for any view placeholder that need dynamic position and/or size.
/// Used UIViewController pattern for loading target view, therefore will be very simply use him.
open class LayoutPlaceholder<Item: LayoutItem, Super: LayoutItem>: LayoutGuide<Super> {
    open private(set) lazy var itemLayout: LayoutBlock<Item> = self.item.layoutBlock()
    fileprivate var _item: Item?

    open var item: Item! {
        loadItemIfNeeded()
        return itemIfLoaded
    }
    open var isItemLoaded: Bool { return _item != nil }
    open var itemIfLoaded: Item? { return _item }

    open func loadItem() {
        // subclass override
    }

    open func itemDidLoad() {
        // subclass override
    }

    open func loadItemIfNeeded() {
        if !isItemLoaded {
            loadItem()
            itemDidLoad()
        }
    }

    open override func layout(in rect: CGRect) {
        itemLayout.layout(in: rect)
    }

    override func layout() {
        if isItemLoaded, ownerItem != nil {
            layout(in: layoutBounds)
        }
    }

    open override func didAddToOwner() {
        super.didAddToOwner()
        if ownerItem == nil { item.removeFromSuperItem() }
    }
}
//extension LayoutPlaceholder: AdjustableLayoutItem where Item: AdjustableLayoutItem {
//    public var contentConstraint: RectBasedConstraint { return item.contentConstraint }
//}

#if os(macOS) || os(iOS) || os(tvOS)
/// Base class for any layer placeholder that need dynamic position and/or size.
/// Used UIViewController pattern for loading target view, therefore will be very simply use him.
open class LayerPlaceholder<Layer: CALayer>: LayoutPlaceholder<Layer, CALayer> {
    open override func loadItem() {
        _item = add(Layer.self) // TODO: can be add to hierarchy on didSet `item`
    }
}
#endif

#if os(iOS) || os(tvOS)
/// Base class for any view placeholder that need dynamic position and/or size.
/// Used UIViewController pattern for loading target view, therefore will be very simply use him.
open class ViewPlaceholder<View: UIView>: LayoutPlaceholder<View, UIView>, AdjustableLayoutItem {
    open var contentConstraint: RectBasedConstraint { return isItemLoaded ? item.contentConstraint : LayoutAnchor.equal(.zero) }
    var load: (() -> View)?
    var didLoad: ((View) -> Void)?

    public convenience init(_ load: @autoclosure @escaping () -> View,
                            _ didLoad: ((View) -> Void)?) {
        self.init(frame: .zero)
        self.load = load
        self.didLoad = didLoad
    }

    public convenience init(_ load: (() -> View)?,
                            _ didLoad: ((View) -> Void)?) {
        self.init(frame: .zero)
        self.load = load
        self.didLoad = didLoad
    }

    open override func loadItem() {
        _item = load?() ?? add(View.self)
    }

    open override func itemDidLoad() {
        super.itemDidLoad()
        if let owner = self.ownerItem {
            owner.addSubview(item)
        }
        didLoad?(item)
    }

    open override func didAddToOwner() {
        super.didAddToOwner()
        if isItemLoaded, let owner = self.ownerItem {
            owner.addSubview(item)
        }
    }
}

// MARK: UILayoutGuide -> UIViewPlaceholder

@available(iOS 9.0, *)
public extension UILayoutGuide {
    /// Fabric method for generation view with any type
    ///
    /// - Parameter type: Type of view
    /// - Returns: Generated view
    func build<V: UIView>(_ type: V.Type) -> V { return V(frame: frame) }
    /// Generates view and adds to `superItem` hierarchy
    ///
    /// - Parameter type: Type of view
    /// - Returns: Added view
    @discardableResult
    func add<V: UIView>(_ type: V.Type) -> V? {
        guard let superItem = owningView else { fatalError("You must add layout guide to container using `func addLayoutGuide(_:)` method") }

        let view = build(type)
        superItem.addSubview(view)
        return view
    }
}

@available(iOS 9.0, *)
open class UIViewPlaceholder<View: UIView>: UILayoutGuide {
    var load: (() -> View)?
    var didLoad: ((View) -> Void)?
    private weak var _view: View?
    open weak var view: View! {
        loadViewIfNeeded()
        return viewIfLoaded
    }
    open var isViewLoaded: Bool { return _view != nil }
    open var viewIfLoaded: View? { return _view }

    public convenience init(_ load: @autoclosure @escaping () -> View,
                            _ didLoad: ((View) -> Void)?) {
        self.init()
        self.load = load
        self.didLoad = didLoad
    }

    public convenience init(_ load: (() -> View)? = nil,
                            _ didLoad: ((View) -> Void)?) {
        self.init()
        self.load = load
        self.didLoad = didLoad
    }

    open func loadView() {
        if let l = load {
            let v = l()
            _view = v
            owningView?.addSubview(v)
        } else {
            _view = add(View.self)
        }
    }

    open func viewDidLoad() {
        didLoad?(view)
    }

    open func loadViewIfNeeded() {
        if !isViewLoaded {
            loadView()
            viewIfLoaded?.translatesAutoresizingMaskIntoConstraints = false
            viewDidLoad()
        }
    }
}
#endif

// MARK: Additional layout scheme

// MARK: ScrollLayoutGuide

/// Layout guide that provides interface for scrolling content
open class ScrollLayoutGuide<Super: LayoutItem>: LayoutGuide<Super> {
    private var layout: LayoutBlockProtocol

    /// Designed initializer
    ///
    /// - Parameter layout: Layout defined scrollable content
    public required init(layout: LayoutBlockProtocol) {
        self.layout = layout
        super.init(frame: .zero)
    }

    /// Point that defines offset for content origin
    open var contentOffset: CGPoint { set { bounds.origin = newValue } get { return bounds.origin } }
    /// Size of content
    open var contentSize: CGSize = .zero//{ set { bounds.size = contentSize } get { return bounds.size } } // TODO: Size of bounds should be equal frame size.
    open var contentInset: EdgeInsets = .zero {
        didSet {
            if oldValue != contentInset {
                let x = contentInset.left - oldValue.left
                let y = contentInset.top - oldValue.top

                contentOffset = CGPoint(x: contentOffset.x - x, y: contentOffset.y - y)
            }
        }
    }

    override public var layoutBounds: CGRect { return CGRect(origin: CGPoint(x: frame.origin.x - contentOffset.x, y: frame.origin.y - contentOffset.y), size: contentSize) }
    /// Performs layout for subitems, which this layout guide manages, in layout space rect
    ///
    /// - Parameter rect: Space for layout
    override open func layout(in rect: CGRect) {
        super.layout(in: rect)
        layout.layout(in: rect)
    }

    /// Defines rect for content that will be visible in this guide space.
    ///
    /// - Parameter frame: New frame value.
    /// - Returns: Content rect
    override open func contentRect(forFrame frame: CGRect) -> CGRect {
//        var contentRect = bounds
//        let lFrame = layoutBounds
//        let snapshotFrame = CGRect(x: lFrame.origin.x, y: lFrame.origin.y, width: max(contentRect.width, frame.width), height: max(contentRect.height, frame.height))
//        contentRect.size = layout.snapshot(for: snapshotFrame).snapshotFrame.distance(from: frame.origin)
//        return contentRect
        var bounds = frame; bounds.origin = contentOffset
        return bounds
    }
}
public extension ScrollLayoutGuide {
    /// Convinience initializer for adjustable layout items. 
    /// Initializes layout guide with layout block constrained to calculated size of item.
    ///
    /// - Parameters:
    ///   - contentItem: Item that defines content
    ///   - direction: Scroll direction
    public convenience init<Item: AdjustableLayoutItem>(contentItem: Item, direction: ScrollDirection) {
        self.init(layout: contentItem.layoutBlock(with: Layout.equal, constraints: [contentItem.adjustLayoutConstraint(for: direction.constraints)]))
    }
}
/// Defines limiters for content of scroll layout guide.
public struct ScrollDirection: OptionSet {
    public
    var rawValue: Int
    public
    init(rawValue: Int) {
        switch rawValue {
        case 1: self = .horizontal
        case 2: self = .vertical
        default:
            self = .both
        }
    }
    
    let constraints: [LayoutAnchor.Size]

    init(constraints: [LayoutAnchor.Size], rawValue: Int) {
        self.constraints = constraints
        self.rawValue = rawValue
    }

    public static var horizontal: ScrollDirection = ScrollDirection(constraints: [.width()], rawValue: 1)
    public static var vertical: ScrollDirection = ScrollDirection(constraints: [.height()], rawValue: 2)
    public static var both: ScrollDirection = ScrollDirection(constraints: [.height(), .width()], rawValue: 0)
}

func LinearInterpolation(t: CGFloat, start: CGFloat, end: CGFloat) -> CGFloat {
    if t <= 0 {
        return start
    }
    else if t >= 1 {
        return end
    }
    else {
        return t * end + (1 - t) * start
    }
}

func QuadraticEaseOut(t: CGFloat, start: CGFloat, end: CGFloat) -> CGFloat {
    if t <= 0 {
        return start
    }
    else if t >= 1 {
        return end
    }
    else {
        return LinearInterpolation(t: 2 * t - t * t, start: start, end: end)
    }
}

protocol ScrollAnimation {
    var beginTime: TimeInterval { get set }
    func animateX()
    func animateY()
}

struct ScrollAnimationDecelerationComponent {
    var decelerateTime: TimeInterval
    var position: CGFloat
    var velocity: CGFloat
    var returnTime: TimeInterval
    var returnFrom: CGFloat
    var bounced: Bool
    var bouncing: Bool
}

private let minimumBounceVelocityBeforeReturning: CGFloat = 100
private let returnAnimationDuration: TimeInterval = 0.33
private let physicsTimeStep: TimeInterval = 1 / 120.0
private let springTightness: CGFloat = 7
private let springDampening: CGFloat = 15

private func Clamp(v: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
    return (v < min) ? min : (v > max) ? max : v
}

private func ClampedVelocty(v: CGFloat) -> CGFloat {
    let V: CGFloat = 500
    return Clamp(v: v, min: -V, max: V)
}

private func Spring(velocity: CGFloat, position: CGFloat, restPosition: CGFloat, tightness: CGFloat, dampening: CGFloat) -> CGFloat {
    let d: CGFloat = position - restPosition
    return (-tightness * d) - (dampening * velocity)
}

private func BounceComponent(t: TimeInterval, c: inout ScrollAnimationDecelerationComponent, to: CGFloat) -> Bool {
    if c.bounced && c.returnTime != 0 {
        let returnBounceTime: TimeInterval = min(1, ((t - c.returnTime) / returnAnimationDuration))
        c.position = QuadraticEaseOut(t: CGFloat(returnBounceTime), start: c.returnFrom, end: to)
        return returnBounceTime == 1
    }
    else if abs(to - c.position) > 0 {
        let F: CGFloat = Spring(velocity: c.velocity, position: c.position, restPosition: to, tightness: springTightness, dampening: springDampening)
        c.velocity += F * CGFloat(physicsTimeStep)
        c.position += -c.velocity * CGFloat(physicsTimeStep)
        c.bounced = true
        if abs(c.velocity) < minimumBounceVelocityBeforeReturning {
            c.returnFrom = c.position
            c.returnTime = t
        }
        return false
    }
    else {
        return true
    }
}

extension ScrollLayoutGuide {
    func _confinedContentOffset(_ contentOffset: CGPoint) -> CGPoint {
        let scrollerBounds: CGRect = EdgeInsetsInsetRect(bounds, contentInset)
        var contentOffset = contentOffset
        if (contentSize.width - contentOffset.x) < scrollerBounds.size.width {
            contentOffset.x = contentSize.width - scrollerBounds.size.width
        }
        if (contentSize.height - contentOffset.y) < scrollerBounds.size.height {
            contentOffset.y = contentSize.height - scrollerBounds.size.height
        }
        contentOffset.x = max(contentOffset.x, 0)
        contentOffset.y = max(contentOffset.y, 0)
        if contentSize.width <= scrollerBounds.size.width {
            contentOffset.x = 0
        }
        if contentSize.height <= scrollerBounds.size.height {
            contentOffset.y = 0
        }
        return contentOffset
    }
    func _setRestrainedContentOffset(_ offset: CGPoint) {
        var offset = offset
        let confinedOffset: CGPoint = _confinedContentOffset(offset)
        let scrollerBounds: CGRect = EdgeInsetsInsetRect(bounds, contentInset)
        if !(/*alwaysBounceHorizontal && */contentSize.width <= scrollerBounds.size.width) {
            offset.x = confinedOffset.x
        }
        if !(/*alwaysBounceVertical && */contentSize.height <= scrollerBounds.size.height) {
            offset.y = confinedOffset.y
        }
        contentOffset = offset
    }
}

public class ScrollAnimationDeceleration<Item: LayoutItem>: ScrollAnimation {
    private var x: ScrollAnimationDecelerationComponent
    private var y: ScrollAnimationDecelerationComponent
    private var lastMomentumTime: TimeInterval
    private(set) weak var scrollGuide: ScrollLayoutGuide<Item>!
    var beginTime: TimeInterval = Date.timeIntervalSinceReferenceDate

    public init(scrollGuide sg: ScrollLayoutGuide<Item>, velocity v: CGPoint) {
        self.scrollGuide = sg

        startVelocity = v
        lastMomentumTime = beginTime
        x = ScrollAnimationDecelerationComponent(decelerateTime: beginTime,
                                                 position: scrollGuide.contentOffset.x,
                                                 velocity: startVelocity.x,
                                                 returnTime: 0,
                                                 returnFrom: 0,
                                                 bounced: false,
                                                 bouncing: false)
        y = ScrollAnimationDecelerationComponent(decelerateTime: beginTime,
                                                 position: scrollGuide.contentOffset.y,
                                                 velocity: startVelocity.y,
                                                 returnTime: 0,
                                                 returnFrom: 0,
                                                 bounced: false,
                                                 bouncing: false)
        if x.velocity == 0 {
            x.bounced = true
            x.returnTime = beginTime
            x.returnFrom = x.position
        }
        if y.velocity == 0 {
            y.bounced = true
            y.returnTime = beginTime
            y.returnFrom = y.position
        }
    }

    func animateY() {
        let currentTime: TimeInterval = Date.timeIntervalSinceReferenceDate
        y.bouncing = true
        while y.bouncing && currentTime >= beginTime {
            let confinedOffset = scrollGuide._confinedContentOffset(CGPoint(x: x.position, y: y.position))
            y.bouncing = !BounceComponent(t: beginTime, c: &y, to: confinedOffset.y)
            beginTime += physicsTimeStep
            scrollGuide.contentOffset.y = y.position//min(max(-scrollGuide.bounds.height, y.position), scrollGuide.layoutBounds.maxY - scrollGuide.bounds.height)
        }
    }

    func animateX() {
        let currentTime: TimeInterval = Date.timeIntervalSinceReferenceDate
        x.bouncing = true
        while x.bouncing && currentTime >= beginTime {
            let confinedOffset = scrollGuide._confinedContentOffset(CGPoint(x: x.position, y: y.position))
            x.bouncing = !BounceComponent(t: beginTime, c: &x, to: confinedOffset.x)
            beginTime += physicsTimeStep
            scrollGuide.contentOffset.x = min(max(-scrollGuide.bounds.width/2, x.position), scrollGuide.layoutBounds.maxX - scrollGuide.bounds.width/2)
        }
    }

    let timeInterval: CGFloat = 1/60
    let startVelocity: CGPoint
    var needBouncing = true

    public func step(_ timer: Timer) {
        func stopIfNeeded() {
            if abs(x.velocity) <= 0.001 && abs(y.velocity) <= 0.001 {
                timer.invalidate()
            }
        }

        guard let guide = scrollGuide, (abs(x.velocity) >= 0.001 && abs(y.velocity) >= 0.001) else {
            timer.invalidate()
            return
        }

        var offset = guide.contentOffset
        if needBouncing {
            if !x.bouncing {
                offset.x += -x.velocity * timeInterval
            }
            if !y.bouncing {
                offset.y += -y.velocity * timeInterval
            }

            guide.contentOffset = offset
            if (offset.x < 0 || offset.x > scrollGuide.contentSize.width - scrollGuide.frame.width) {
                x.position = offset.x
                animateX()
                stopIfNeeded()
            }
            if (offset.y < 0 || offset.y > scrollGuide.contentSize.height - scrollGuide.frame.height) {
                y.position = offset.y
                animateY()
                stopIfNeeded()
            }
        } else {
            offset.x += -x.velocity * timeInterval
            offset.y += -y.velocity * timeInterval
            guide._setRestrainedContentOffset(offset)
        }

        lastMomentumTime = Date.timeIntervalSinceReferenceDate
        let friction: CGFloat = 0.96
        let drag: CGFloat = pow(pow(friction, 60), CGFloat(lastMomentumTime - beginTime))
        if !x.bouncing {
            x.velocity = startVelocity.x * drag
        }
        if !y.bouncing {
            y.velocity = startVelocity.y * drag
        }
    }
}
