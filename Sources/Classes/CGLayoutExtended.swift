//
//  CGLayoutExtended.swift
//  Pods
//
//  Created by Denis Koryttsev on 04/09/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

import Foundation

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
    open fileprivate(set) weak var ownerItem: Super? {
        didSet { superItem = ownerItem; didAddToOwner() }
    }
    open /// External representation of layout entity in coordinate space
    var frame: CGRect { didSet { if oldValue != frame { bounds = contentRect(forFrame: frame) } } }
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

    internal func layout() { layout(in: layoutBounds) }
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

/// Base class for any view placeholder that need dynamic position and/or size.
/// Used UIViewController pattern for loading target view, therefore will be very simply use him.
open class LayoutPlaceholder<Item: LayoutItem, Super: LayoutItem>: LayoutGuide<Super> {
    open private(set) lazy var itemLayout: LayoutBlock<Item> = self.item.layoutBlock(with: Layout.equal, constraints: [self.layoutConstraint(for: [LayoutAnchor.equal])])
    private weak var _item: Item?

    open weak var item: Item! {
        set { _item = newValue }
        get {
            loadItemIfNeeded()
            return itemIfLoaded
        }
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
        if isItemLoaded {
            itemLayout.layout(in: rect)
        }
    }
}

#if os(macOS) || os(iOS) || os(tvOS)
/// Base class for any layer placeholder that need dynamic position and/or size.
/// Used UIViewController pattern for loading target view, therefore will be very simply use him.
open class LayerPlaceholder<Layer: CALayer>: LayoutPlaceholder<Layer, CALayer> {
    open override func loadItem() {
        item = add(Layer.self) // TODO: can be add to hierarchy on didSet `item`
    }
}
#endif

#if os(iOS) || os(tvOS)
/// Base class for any view placeholder that need dynamic position and/or size.
/// Used UIViewController pattern for loading target view, therefore will be very simply use him.
open class ViewPlaceholder<View: UIView>: LayoutPlaceholder<View, UIView> {
    open override func loadItem() {
        item = add(View.self)
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
    private weak var _view: View?
    open weak var view: View! {
        loadViewIfNeeded()
        return viewIfLoaded
    }
    open var isViewLoaded: Bool { return _view != nil }
    open var viewIfLoaded: View? { return _view }

    open func loadView() {
        _view = add(View.self)
    }

    open func viewDidLoad() {
        // subclass override
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

// MARK: Additional constraints

/// Layout constraint for independent changing source space. Use him with anchors that not describes rect side (for example `LayoutAnchor.insets` or `LayoutAnchor.Size`).
public struct AnonymConstraint: LayoutConstraintProtocol {
    let anchors: [RectBasedConstraint]
    let constrainRect: ((CGRect) -> CGRect)?

    public init(anchors: [RectBasedConstraint], constrainRect: ((CGRect) -> CGRect)? = nil) {
        self.anchors = anchors
        self.constrainRect = constrainRect
    }

    public /// Flag, defines that constraint may be used for layout
    var isActive: Bool { return true }
    /// Flag that constraint not required other calculations. It`s true for size-based constraints.
    public var isIndependent: Bool { return true }

    /// `LayoutItem` object associated with this constraint
    public func layoutItem(is object: AnyObject) -> Bool {
        return false
    }

    /// Return rectangle for constrain source rect
    ///
    /// - Parameter currentSpace: Source rect in current state
    /// - Parameter coordinateSpace: Working coordinate space
    /// - Returns: Rect for constrain
    public func constrainRect(for currentSpace: CGRect, in coordinateSpace: LayoutItem) -> CGRect {
        return constrainRect?(currentSpace) ?? currentSpace
    }

    /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        sourceRect = anchors.reduce(sourceRect) { $1.constrained(sourceRect: $0, by: rect) }
    }

    /// Converts rect from constraint coordinate space to destination coordinate space if needed.
    ///
    /// - Parameters:
    ///   - rect: Initial rect
    ///   - coordinateSpace: Destination coordinate space
    /// - Returns: Converted rect
    public func convert(rectIfNeeded rect: CGRect, to coordinateSpace: LayoutItem) -> CGRect {
        return rect
    }
}

// TODO: Create constraint for attributed string and other data oriented constraints

#if os(macOS) || os(iOS) || os(tvOS)
@available(OSX 10.11, *) /// Size-based constraint for constrain source rect by size of string. The size to draw gets from restrictive rect.
public struct StringLayoutAnchor: RectBasedConstraint {
    let string: String?
    let attributes: [String: Any]?
    let options: NSStringDrawingOptions
    let context: NSStringDrawingContext?

    /// Designed initializer
    ///
    /// - Parameters:
    ///   - string: String for size calculation
    ///   - options: String drawing options.
    ///   - attributes: A dictionary of text attributes to be applied to the string. These are the same attributes that can be applied to an NSAttributedString object, but in the case of NSString objects, the attributes apply to the entire string, rather than ranges within the string.
    ///   - context: The string drawing context to use for the receiver, specifying minimum scale factor and tracking adjustments.
    public init(string: String?, options: NSStringDrawingOptions = .usesLineFragmentOrigin, attributes: [String: Any]? = nil, context: NSStringDrawingContext? = nil) {
        self.string = string
        self.attributes = attributes
        self.context = context
        self.options = options
    }

    public /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        sourceRect.size = string?.boundingRect(with: rect.size, options: options, attributes: attributes, context: context).size ?? .zero
    }
}
public extension String {
    /// Convenience getter for string layout constraint.
    ///
    /// - Parameters:
    ///   - attributes: String attributes
    ///   - context: Drawing context
    /// - Returns: String-based constraint
    @available(OSX 10.11, *)
    func layoutConstraint(with options: NSStringDrawingOptions = .usesLineFragmentOrigin, attributes: [String: Any]? = nil, context: NSStringDrawingContext? = nil) -> StringLayoutAnchor {
        return StringLayoutAnchor(string: self, options: options, attributes: attributes, context: context)
    }
}
#endif

// MARK: Additional layout scheme

// TODO: Create RectAxisBasedDistribution as subprotocol RectBasedDistribution. Probably will contain `axis` property
// TODO: Try to built RectBasedLayout, RectBasedConstraint, RectBasedDistribution on RectAxis.
// TODO: In MacOS origin in left-bottom corner by default. NSView.isFlipped moves origin to left-top corner.

/// Base protocol for any layout distribution
protocol RectBasedDistribution {
    func distribute(rects: [CGRect], in sourceRect: CGRect, iterator: (CGRect) -> Void) -> [CGRect]
}

/// Implementation space for distributions
struct LayoutDistribution: RectBasedDistribution {
    private let base: RectBasedDistribution
    func distribute(rects: [CGRect], in sourceRect: CGRect, iterator: (CGRect) -> Void) -> [CGRect] {
        return base.distribute(rects: rects, in: sourceRect, iterator: iterator)
    }

    /// Defines distribution arranged items from leading side (top, left) in specific axis.
    ///
    /// - Parameters:
    ///   - axis: Axis for distribution
    ///   - spacing: Value of space between arranged items
    /// - Returns: LayoutDistribution entity
    static func fromLeading(by axis: RectAxis, spacing: CGFloat) -> LayoutDistribution { return LayoutDistribution(base: FromLeading(axis: axis, spacing: spacing)) }
    fileprivate struct FromLeading: RectBasedDistribution, AxisEntity {
        func by(axis: RectAxis) -> LayoutDistribution.FromLeading { return .init(axis: axis, spacing: spacing) }

        let axis: RectAxis
        let spacing: CGFloat

        func distribute(rects: [CGRect], in sourceRect: CGRect, iterator: (CGRect) -> Void) -> [CGRect] {
            return LayoutDistribution.distributeFromLeading(rects: rects, in: sourceRect, by: axis, spacing: spacing, iterator: iterator)
        }
    }
    /// Defines distribution arranged items from trailing side (bottom, right) in specific axis.
    ///
    /// - Parameters:
    ///   - axis: Axis for distribution
    ///   - spacing: Value of space between arranged items
    /// - Returns: LayoutDistribution entity
    static func fromTrailing(by axis: RectAxis, spacing: CGFloat) -> LayoutDistribution { return LayoutDistribution(base: FromTrailing(axis: axis, spacing: spacing)) }
    fileprivate struct FromTrailing: RectBasedDistribution, AxisEntity {
        func by(axis: RectAxis) -> LayoutDistribution.FromTrailing { return .init(axis: axis, spacing: spacing) }

        let axis: RectAxis
        let spacing: CGFloat

        func distribute(rects: [CGRect], in sourceRect: CGRect, iterator: (CGRect) -> Void) -> [CGRect] {
            return LayoutDistribution.distributeFromTrailing(rects: rects, in: sourceRect, by: axis, spacing: spacing, iterator: iterator)
        }
    }

    /// Defines distribution arranged items from center anchor point in specific axis.
    ///
    /// - Parameter baseDistribution: Distribution that will be used for defining dependency between arranged items. In common cases it is left and top distribution.
    /// - Returns: LayoutDistribution entity
    static func fromCenter(baseDistribution: RectBasedDistribution & AxisEntity) -> LayoutDistribution {
        return LayoutDistribution(base: FromCenter(baseDistribution: baseDistribution))
    }
    fileprivate struct FromCenter: RectBasedDistribution, AxisEntity {
        func by(axis: RectAxis) -> LayoutDistribution.FromCenter { return .init(baseDistribution: baseDistribution) }
        let baseDistribution: RectBasedDistribution & AxisEntity
        var axis: RectAxis { return baseDistribution.axis }

        func distribute(rects: [CGRect], in sourceRect: CGRect, iterator: (CGRect) -> Void) -> [CGRect] {
            let frames = baseDistribution.distribute(rects: rects, in: sourceRect, iterator: {_ in})
            let offset = axis.get(midOf: sourceRect) - (((axis.get(maxOf: frames.last!) - axis.get(minOf: frames.first!)) / 2) + axis.get(minOf: frames.first!))

            return frames.map {
                let offsetRect = axis.offset(rect: $0, by: offset)
                iterator(offsetRect)
                return offsetRect
            }
        }

    }
    /// Defines distribution with equally spaces between arranged items.
    ///
    /// - Parameter axis: Axis for distribution
    /// - Returns: LayoutDistribution entity
    static func equalSpacing(axis: RectAxis) -> LayoutDistribution { return LayoutDistribution(base: EqualSpacing(axis: axis)) }
    fileprivate struct EqualSpacing: RectBasedDistribution, AxisEntity {
        func by(axis: RectAxis) -> LayoutDistribution.EqualSpacing { return .init(axis: axis) }
        let axis: RectAxis

        func distribute(rects: [CGRect], in sourceRect: CGRect, iterator: (CGRect) -> Void) -> [CGRect] {
            let fullLength = rects.reduce(0) { $0 + axis.get(sizeAt: $1) }
            let spacing = (axis.get(sizeAt: sourceRect) - fullLength) / CGFloat(rects.count - 1)

            return LayoutDistribution.distributeFromLeading(rects: rects, in: sourceRect, by: axis, spacing: spacing, iterator: iterator)
        }
    }
    static func distributeFromLeading(rects: [CGRect], in sourceRect: CGRect, by axis: RectAxis, spacing: CGFloat, iterator: (CGRect) -> Void) -> [CGRect] {
        var previous: CGRect?
        return rects.map { rect in
            var rect = rect
            axis.set(origin: (previous.map { _ in spacing } ?? 0) + (previous.map { axis.get(maxOf: $0) } ?? axis.get(minOf: sourceRect)), for: &rect)
            iterator(rect)
            previous = rect
            return rect
        }
    }
    static func distributeFromTrailing(rects: [CGRect], in sourceRect: CGRect, by axis: RectAxis, spacing: CGFloat, iterator: (CGRect) -> Void) -> [CGRect] {
        var previous: CGRect?
        return rects.map { rect in
            var rect = rect
            axis.set(origin: (previous.map { _ in -spacing } ?? 0) + (previous.map { axis.get(minOf: $0) } ?? (axis.get(maxOf: sourceRect))) - axis.get(sizeAt: rect), for: &rect)
            iterator(rect)
            previous = rect
            return rect
        }
    }
}

/// Protocol defines method for filling items
protocol StackLayoutFilling {
    /// Performs filling for item in defined source space
    ///
    /// - Parameters:
    ///   - item: Item for filling
    ///   - source: Source space
    /// - Returns: Modified rect
    func filling(for item: LayoutItem, in source: CGRect) -> CGRect
}
extension Layout.Filling: StackLayoutFilling {
    func filling(for item: LayoutItem, in source: CGRect) -> CGRect {
        return layout(rect: item.frame, in: source)
    }
}

// TODO: Implement stack layout scheme, collection and others
// TODO: Add to stack layout scheme circle type

// TODO: StackLayoutScheme lost multihierarchy layout. Research this. // Comment: Probably would be not available.
/// Defines layout for arranged items
public struct StackLayoutScheme: LayoutBlockProtocol {
    private var items: () -> [LayoutItem]

    public struct Distribution: RectBasedDistribution, AxisEntity {
        func by(axis: RectAxis) -> StackLayoutScheme.Distribution { return .init(base: base.by(axis: axis)) }

        private let base: RectBasedDistribution & AxisEntity
        internal var axis: RectAxis { return base.axis }

        @discardableResult
        func distribute(rects: [CGRect], in sourceRect: CGRect, iterator: (CGRect) -> Void = {_ in}) -> [CGRect] {
            return base.distribute(rects: rects, in: sourceRect, iterator: iterator)
        }

        public static func fromLeft(spacing: CGFloat) -> Distribution { return Distribution(base: LayoutDistribution.FromLeading(axis: _RectAxis.horizontal, spacing: spacing)) }
        public static func fromRight(spacing: CGFloat) -> Distribution { return Distribution(base: LayoutDistribution.FromTrailing(axis: _RectAxis.horizontal, spacing: spacing)) }
        public static func fromTop(spacing: CGFloat) -> Distribution { return Distribution(base: LayoutDistribution.FromLeading(axis: _RectAxis.vertical, spacing: spacing)) }
        public static func fromBottom(spacing: CGFloat) -> Distribution { return Distribution(base: LayoutDistribution.FromTrailing(axis: _RectAxis.vertical, spacing: spacing)) }
        public static func fromVerticalCenter(spacing: CGFloat) -> Distribution { return Distribution(base: LayoutDistribution.FromCenter(baseDistribution: LayoutDistribution.FromLeading(axis: _RectAxis.vertical, spacing: spacing))) }
        public static func fromHorizontalCenter(spacing: CGFloat) -> Distribution { return Distribution(base: LayoutDistribution.FromCenter(baseDistribution: LayoutDistribution.FromLeading(axis: _RectAxis.horizontal, spacing: spacing))) }
        public static func equalSpacingHorizontal() -> Distribution { return Distribution(base: LayoutDistribution.EqualSpacing(axis: _RectAxis.horizontal)) }
        public static func equalSpacingVertical() -> Distribution { return Distribution(base: LayoutDistribution.EqualSpacing(axis: _RectAxis.vertical)) }
    }
    public struct Alignment: RectAxisLayout {
        let layout: RectAxisLayout
        var axis: RectAxis { return layout.axis }

        init<T: RectAxisLayout>(_ layout: T) {
            self.layout = layout
        }
        init(_ layout: RectAxisLayout) {
            self.layout = layout
        }

        public static func leading(_ offset: CGFloat = 0) -> Alignment { return Alignment(Layout.Alignment.leading(by: _RectAxis.vertical, offset: offset)) }
        public static func trailing(_ offset: CGFloat = 0) -> Alignment { return Alignment(Layout.Alignment.trailing(by: _RectAxis.vertical, offset: offset)) }
        public static func center(_ offset: CGFloat = 0) -> Alignment { return Alignment(Layout.Alignment.center(by: _RectAxis.vertical, offset: offset)) }

        public func formLayout(rect: inout CGRect, in source: CGRect) {
            layout.formLayout(rect: &rect, in: source)
        }

        func by(axis: RectAxis) -> StackLayoutScheme.Alignment {
            let l = layout.by(axis: axis)
            return .init(l)
        }
    }
    public struct Filling: StackLayoutFilling {
        private let layout: StackLayoutFilling

        struct AutoDimension: StackLayoutFilling {
            fileprivate let defaultFilling: Layout.Filling
            func filling(for item: LayoutItem, in source: CGRect) -> CGRect {
                guard let adjustItem = item as? AdjustableLayoutItem else { return defaultFilling.layout(rect: item.frame, in: source) }

                return adjustItem.contentConstraint.constrained(sourceRect: adjustItem.frame, by: source)
            }
        }

        public static func autoDimension(`default` filling: Layout.Filling) -> Filling { return Filling(layout: AutoDimension(defaultFilling: filling)) }
        public static func custom(_ value: Layout.Filling) -> Filling { return Filling(layout: value) }

        func filling(for item: LayoutItem, in source: CGRect) -> CGRect {
            return layout.filling(for: item, in: source)
        }
    }

    public /// Flag, defines that block will be used for layout
    var isActive: Bool { return true }

    /// Current layout axis
    public var axis: RectAxis { return distribution.axis }
    /// Current distribution for arranged items
    public var distribution: Distribution = .fromLeft(spacing: 0) {
        didSet { _alignment = alignment.by(axis: axis.transverse()) }
    }
    private var _alignment: Alignment = .leading()
    /// Alignment for arranged items in transverse axis
    public var alignment: Alignment {
        set { _alignment = newValue.by(axis: axis.transverse()) }
        get { return _alignment }
    }
    /// Filling in source space
    public var filling: Filling = .autoDimension(default: Layout.Filling(horizontal: .scaled(1), vertical: .scaled(1)))

    /// Designed initializer
    ///
    /// - Parameter items: Closure provides items
    public init(items: @escaping () -> [LayoutItem]) {
        self.items = items
    }

    // MARK: LayoutBlockProtocol

    public /// Snapshot for current state without recalculating
    var currentSnapshot: LayoutSnapshotProtocol {
        var snapshotFrame: CGRect?
        return LayoutSnapshot(childSnapshots: items().map { block in
            let blockFrame = block.frame
            snapshotFrame = snapshotFrame?.union(blockFrame) ?? blockFrame
            return blockFrame
        }, snapshotFrame: snapshotFrame ?? .zero)
    }

    public /// Calculate and apply frames layout items.
    /// Should be call when parent `LayoutItem` item has corrected bounds. Else result unexpected.
    func layout() {
        let subItems = items()
        guard let sourceRect = subItems.first?.superItem!.frame else { return }

        let frames: [CGRect] = subItems.map { subItem in
            return alignment.layout(rect: filling.filling(for: subItem, in: sourceRect), in: sourceRect)
        }
        var itemsIterator = subItems.makeIterator()
        distribution.distribute(rects: frames, in: sourceRect, iterator: { itemsIterator.next()?.frame = $0 })
    }

    public /// Calculate and apply frames layout items in custom space.
    ///
    /// - Parameter sourceRect: Source space
    func layout(in sourceRect: CGRect) {
        let subItems = items()
        let frames: [CGRect] = subItems.map { subItem in
            return alignment.layout(rect: filling.filling(for: subItem, in: sourceRect), in: sourceRect)
        }
        var itemsIterator = subItems.makeIterator()
        distribution.distribute(rects: frames, in: sourceRect, iterator: { itemsIterator.next()?.frame = $0 })
    }

    public /// Applying frames from snapshot to `LayoutItem` items in this block.
    /// Snapshot array should be ordered such to match `LayoutItem` items sequence.
    ///
    /// - Parameter snapshot: Snapshot represented as array of frames.
    func apply(snapshot: LayoutSnapshotProtocol) {
        var iterator = items().makeIterator()
        for child in snapshot.childSnapshots {
            iterator.next()?.frame = child.snapshotFrame
        }
    }

    public /// Returns snapshot for all `LayoutItem` items in block. Attention: in during calculating snapshot frames of layout items must not changed.
    ///
    /// - Parameter sourceRect: Source space for layout
    /// - Returns: Snapshot contained frames layout items
    func snapshot(for sourceRect: CGRect) -> LayoutSnapshotProtocol {
        var completedFrames: [(AnyObject, CGRect)] = []
        return snapshot(for: sourceRect, completedRects: &completedFrames)
    }

    public /// Method for perform layout calculation in child blocks. Does not call this method directly outside `LayoutBlockProtocol` object.
    /// Layout block should be insert contained `LayoutItem` items to completedRects
    ///
    /// - Parameters:
    ///   - sourceRect: Source space for layout. For not top level blocks rect should be define available bounds of block
    ///   - completedRects: `LayoutItem` items with corrected frame
    /// - Returns: Frame of this block
    func snapshot(for sourceRect: CGRect, completedRects: inout [(AnyObject, CGRect)]) -> LayoutSnapshotProtocol {
        let subItems = items()
        var snapshotFrame: CGRect?
        var iterator = subItems.makeIterator()
        let frames = distribution.distribute(rects: subItems.map { alignment.layout(rect: filling.filling(for: $0, in: sourceRect), in: sourceRect) },
                                             in: sourceRect,
                                             iterator: {
                                                completedRects.insert((iterator.next()!, $0), at: 0)
                                                snapshotFrame = snapshotFrame?.union($0) ?? $0

        })
        return LayoutSnapshot(childSnapshots: frames, snapshotFrame: snapshotFrame ?? CGRect(origin: sourceRect.origin, size: .zero))
    }
}

// TODO: After add need recalculate layout

/// StackLayoutGuide layout guide for arranging items in ordered list. It's analogue UIStackView.
/// For configure layout parameters use property `scheme`.
/// Attention: before addition items to stack, need add stack layout guide to super layout item using `func add(layoutGuide:)` method.
open class StackLayoutGuide<Parent: LayoutItemContainer>: LayoutGuide<Parent>, AdjustableLayoutItem, SelfSizedLayoutItem {
    private var insetAnchor: RectBasedConstraint?
    fileprivate var items: [LayoutItem] = []
    /// StackLayoutScheme entity for configuring axis, distribution and other parameters.
    open lazy var scheme: StackLayoutScheme = StackLayoutScheme { [unowned self] in self.items }
    /// The list of items arranged by the stack layout guide
    open var arrangedItems: [LayoutItem] { return items }
    /// Insets for distribution space
    open var contentInsets: EdgeInsets = .zero {
        didSet { insetAnchor = LayoutAnchor.insets(contentInsets) }
    }
    /// Layout item where added this layout guide. For addition use `func add(layoutGuide:)`.
    open override var ownerItem: Parent? {
        willSet {
            if newValue == nil {
                items.forEach { $0.removeFromSuperItem() }
            }
        }
        /// while stack layout guide cannot add subitems
//        didSet {
//            if let owner = ownerItem {
//                items.forEach { item in owner.addSublayoutItem(item) }
//            }
//        }
    }

    fileprivate func removeItem(_ item: LayoutItem) -> Bool {
        guard let index = items.index(where: { $0 === item }) else { return false }
        
        items.remove(at: index)
        return true
    }

    /// Performs layout for subitems, which this layout guide manages, in layout space rect
    ///
    /// - Parameter rect: Space for layout
    override open func layout(in rect: CGRect) {
        super.layout(in: rect)
        scheme.layout(in: rect)
    }

    /// Defines rect for `bounds` property. Calls on change `frame`.
    ///
    /// - Parameter frame: New frame value.
    /// - Returns: Content rect
    open override func contentRect(forFrame frame: CGRect) -> CGRect {
        let lFrame = super.contentRect(forFrame: frame)
        return insetAnchor?.constrained(sourceRect: lFrame, by: .zero) ?? lFrame
    }

    open /// Asks the layout item to calculate and return the size that best fits the specified size
    ///
    /// - Parameter size: The size for which the view should calculate its best-fitting size
    /// - Returns: A new size that fits the receiver’s content
    func sizeThatFits(_ size: CGSize) -> CGSize {
        let sourceRect = CGRect(origin: .zero, size: size)
        var result = scheme.snapshot(for: insetAnchor?.constrained(sourceRect: sourceRect, by: .zero) ?? sourceRect).snapshotFrame.distanceFromOrigin
        result.width += contentInsets.right
        result.height += contentInsets.bottom
        return result
    }
}
extension StackLayoutGuide: CustomDebugStringConvertible, CustomStringConvertible {
    public var debugDescription: String { return items.debugDescription }
    public var description: String { return items.description }
}
#if os(iOS) || os(tvOS)
extension StackLayoutGuide where Parent: UIView {
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter item: Layout guide for addition.
    public func addArrangedItem<T: UIView>(_ item: LayoutGuide<T>) { insertArrangedItem(item, at: items.count) }
    /// Inserts a item to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - item: Layout guide for addition
    ///   - index: Index in list.
    public func insertArrangedItem<T: UIView>(_ item: LayoutGuide<T>, at index: Int) {
        ownerItem?.addSublayoutItem(unsafeBitCast(item, to: LayoutGuide<UIView>.self))
        items.insert(item, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter item: Layout guide for removing.
    public func removeArrangedItem<T: UIView>(_ item: LayoutGuide<T>) {
        guard removeItem(item), ownerItem === item.superItem else { return }
        item.removeFromSuperItem()
    }
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter item: Layout guide for addition.
    public func addArrangedItem<T: CALayer>(_ item: LayoutGuide<T>) { insertArrangedItem(item, at: items.count) }
    /// Inserts a item to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - item: Layout guide for addition
    ///   - index: Index in list.
    public func insertArrangedItem<T: CALayer>(_ item: LayoutGuide<T>, at index: Int) {
        ownerItem?.addSublayoutItem(unsafeBitCast(item, to: LayoutGuide<CALayer>.self))
        items.insert(item, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter item: Layout guide for removing.
    public func removeArrangedItem<T: CALayer>(_ item: LayoutGuide<T>) {
        guard removeItem(item), ownerItem?.layer === item.superItem else { return }
        item.removeFromSuperItem()
    }
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter item: View for addition.
    public func addArrangedItem(_ item: UIView) { insertArrangedItem(item, at: items.count) }
    /// Inserts a item to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - item: View for addition
    ///   - index: Index in list.
    public func insertArrangedItem(_ item: UIView, at index: Int) {
        ownerItem?.addSublayoutItem(item)
        items.insert(item, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter item: View for removing.
    public func removeArrangedItem(_ item: UIView) {
        guard removeItem(item), ownerItem === item.superItem else { return }
        item.removeFromSuperItem()
    }
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter item: Layer for addition.
    public func addArrangedItem(_ item: CALayer) { insertArrangedItem(item, at: items.count) }
    /// Inserts a item to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - item: Layer for addition
    ///   - index: Index in list.
    public func insertArrangedItem(_ item: CALayer, at index: Int) {
        ownerItem?.addSublayoutItem(item)
        items.insert(item, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter item: Layer for removing.
    public func removeArrangedItem(_ item: CALayer) {
        guard removeItem(item), ownerItem?.layer === item.superItem else { return }
        item.removeFromSuperItem()
    }
}
#endif
#if os(macOS) || os(iOS) || os(tvOS)
extension StackLayoutGuide where Parent: CALayer {
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter item: Layout guide for addition.
    public func addArrangedItem<T: CALayer>(_ item: LayoutGuide<T>) { insertArrangedItem(item, at: items.count) }
    /// Inserts a item to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - item: Layout guide for addition
    ///   - index: Index in list.
    public func insertArrangedItem<T: CALayer>(_ item: LayoutGuide<T>, at index: Int) {
        ownerItem?.addSublayoutItem(unsafeBitCast(item, to: LayoutGuide<CALayer>.self))
        items.insert(item, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter item: Layout guide for removing.
    public func removeArrangedItem(_ item: LayoutItem) {
        guard removeItem(item), ownerItem === item.superItem else { return }
        item.removeFromSuperItem()
    }
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter item: CALayer for addition.
    public func addArrangedItem(_ item: CALayer) { insertArrangedItem(item, at: items.count) }
    /// Inserts a item to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - item: Layer for addition
    ///   - index: Index in list.
    public func insertArrangedItem(_ item: CALayer, at index: Int) {
        ownerItem?.addSublayoutItem(item)
        items.insert(item, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter item: Layer for removing.
    public func removeArrangedItem(_ item: CALayer) {
        guard removeItem(item), ownerItem === item.superItem else { return }
        item.removeFromSuperItem()
    }
}
#endif

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
    open var contentOffset: CGPoint { set { bounds.origin = newValue.negated() } get { return bounds.origin.negated() } }
    /// Size of content
    open var contentSize: CGSize { set { bounds.size = contentSize } get { return bounds.size } } // TODO: Size of bounds should be equal frame size.

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
        var contentRect = bounds
        let lFrame = layoutBounds
        let snapshotFrame = CGRect(x: lFrame.origin.x, y: lFrame.origin.y, width: max(contentRect.width, frame.width), height: max(contentRect.height, frame.height))
        contentRect.size = layout.snapshot(for: snapshotFrame).snapshotFrame.distance(from: frame.origin)
        return contentRect
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
