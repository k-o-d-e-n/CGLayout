//
//  CGLayoutExtended.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 04/09/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

import Foundation

// TODO: Create RectAxisBasedDistribution as subprotocol RectBasedDistribution. Probably will contain `axis` property
// TODO: Try to built RectBasedLayout, RectBasedConstraint, RectBasedDistribution on RectAxis.
// TODO: In MacOS origin in left-bottom corner by default. NSView.isFlipped moves origin to left-top corner.

/// Base protocol for any layout distribution
protocol RectBasedDistribution {
    func formDistribute(rectsBy pointer: UnsafeMutablePointer<CGRect>, count: Int, in sourceRect: CGRect)
}
extension RectBasedDistribution {
    func distribute(rects: [CGRect], in sourceRect: CGRect) -> [CGRect] {
        let pointer = UnsafeMutablePointer<CGRect>.allocate(capacity: rects.count)
        pointer.initialize(from: rects)
        formDistribute(rectsBy: pointer, count: rects.count, in: sourceRect)
        return (0..<rects.count).map { pointer[$0] }
    }
}

/// Implementation space for distributions
struct LayoutDistribution: RectBasedDistribution {
    private let base: RectBasedDistribution
    func formDistribute(rectsBy pointer: UnsafeMutablePointer<CGRect>, count: Int, in sourceRect: CGRect) {
        return base.formDistribute(rectsBy: pointer, count: count, in: sourceRect)
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

        func formDistribute(rectsBy pointer: UnsafeMutablePointer<CGRect>, count: Int, in sourceRect: CGRect) {
            let rects = LayoutDistribution.distributeFromLeading(rects: (0..<count).map { pointer[$0] }, in: sourceRect, by: axis, spacing: spacing)
            (0..<count).forEach { pointer[$0] = rects[$0] }
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

        func formDistribute(rectsBy pointer: UnsafeMutablePointer<CGRect>, count: Int, in sourceRect: CGRect) {
            let rects = LayoutDistribution.distributeFromTrailing(rects: (0..<count).map { pointer[$0] }, in: sourceRect, by: axis, spacing: spacing)
            (0..<count).forEach { pointer[$0] = rects[$0] }
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

        func formDistribute(rectsBy pointer: UnsafeMutablePointer<CGRect>, count: Int, in sourceRect: CGRect) {
            baseDistribution.formDistribute(rectsBy: pointer, count: count, in: sourceRect)
            let first = pointer[0]
            let last = pointer[count-1]
            let offset = axis.get(midOf: sourceRect) - (((axis.get(maxOf: last) - axis.get(minOf: first)) / 2) + axis.get(minOf: first))

            (0..<count).forEach {
                pointer[$0] = axis.offset(rect: pointer[$0], by: offset)
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

        func formDistribute(rectsBy pointer: UnsafeMutablePointer<CGRect>, count: Int, in sourceRect: CGRect) {
            var rects = (0..<count).map { pointer[$0] }
            let fullLength = rects.reduce(0.0) { $0 + axis.get(sizeAt: $1) }
            let spacing = (axis.get(sizeAt: sourceRect) - fullLength) / CGFloat(count - 1)

            rects = LayoutDistribution.distributeFromLeading(rects: rects, in: sourceRect, by: axis, spacing: spacing)
            (0..<count).forEach { pointer[$0] = rects[$0] }
        }
    }
    static func distributeFromLeading(rects: [CGRect], in sourceRect: CGRect, by axis: RectAxis, spacing: CGFloat) -> [CGRect] {
        var previous: CGRect?
        return rects.map { rect in
            var rect = rect
            axis.set(origin: (previous.map { _ in spacing } ?? 0) + (previous.map { axis.get(maxOf: $0) } ?? axis.get(minOf: sourceRect)), for: &rect)
            previous = rect
            return rect
        }
    }
    static func distributeFromTrailing(rects: [CGRect], in sourceRect: CGRect, by axis: RectAxis, spacing: CGFloat) -> [CGRect] {
        var previous: CGRect?
        return rects.map { rect in
            var rect = rect
            axis.set(origin: (previous.map { _ in -spacing } ?? 0) + (previous.map { axis.get(minOf: $0) } ?? (axis.get(maxOf: sourceRect))) - axis.get(sizeAt: rect), for: &rect)
            previous = rect
            return rect
        }
    }
}

/// Protocol defines method for filling items
public protocol StackLayoutFilling {
    /// Performs filling for item in defined source space
    ///
    /// - Parameters:
    ///   - item: Item for filling
    ///   - source: Source space
    /// - Returns: Modified rect
    func filling(for item: LayoutItem, in source: CGRect) -> CGRect
}
extension Layout.Filling: StackLayoutFilling {
    public func filling(for item: LayoutItem, in source: CGRect) -> CGRect {
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

        func formDistribute(rectsBy pointer: UnsafeMutablePointer<CGRect>, count: Int, in sourceRect: CGRect) {
            return base.formDistribute(rectsBy: pointer, count: count, in: sourceRect)
        }

        public static func fromLeft(spacing: CGFloat) -> Distribution { return Distribution(base: LayoutDistribution.FromLeading(axis: _RectAxis.horizontal, spacing: spacing)) }
        public static func fromRight(spacing: CGFloat) -> Distribution { return Distribution(base: LayoutDistribution.FromTrailing(axis: _RectAxis.horizontal, spacing: spacing)) }
        public static func fromTop(spacing: CGFloat) -> Distribution { return Distribution(base: LayoutDistribution.FromLeading(axis: _RectAxis.vertical, spacing: spacing)) }
        public static func fromBottom(spacing: CGFloat) -> Distribution { return Distribution(base: LayoutDistribution.FromTrailing(axis: _RectAxis.vertical, spacing: spacing)) }
        public static func fromVerticalCenter(spacing: CGFloat) -> Distribution { return Distribution(base: LayoutDistribution.FromCenter(baseDistribution: LayoutDistribution.FromLeading(axis: _RectAxis.vertical, spacing: spacing))) }
        public static func fromHorizontalCenter(spacing: CGFloat) -> Distribution { return Distribution(base: LayoutDistribution.FromCenter(baseDistribution: LayoutDistribution.FromLeading(axis: _RectAxis.horizontal, spacing: spacing))) }
        public static func equalSpacingHorizontal() -> Distribution { return Distribution(base: LayoutDistribution.EqualSpacing(axis: _RectAxis.horizontal)) }
        public static func equalSpacingVertical() -> Distribution { return Distribution(base: LayoutDistribution.EqualSpacing(axis: _RectAxis.vertical)) }
        // TODO: Add distribution with limited by size anchor (width, height)
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
    public struct Filling: StackLayoutFilling, Extended {
        private let layout: StackLayoutFilling

        public typealias Conformed = StackLayoutFilling
        public static func build(_ base: StackLayoutFilling) -> StackLayoutScheme.Filling {
            return Filling(layout: base)
        }

        struct AutoDimension: StackLayoutFilling {
            fileprivate let defaultFilling: Layout.Filling
            func filling(for item: LayoutItem, in source: CGRect) -> CGRect {
                guard let adjustItem = item as? AdjustableLayoutItem else { return defaultFilling.layout(rect: item.frame, in: source) }

                return adjustItem.contentConstraint.constrained(sourceRect: adjustItem.frame, by: source)
            }
        }

        // TODO: Create auto dimension for axis (only height, only width, together)
        public static func autoDimension(`default` filling: Layout.Filling) -> Filling { return Filling(layout: AutoDimension(defaultFilling: filling)) }
        public static func custom(_ value: Layout.Filling) -> Filling { return Filling(layout: value) }

        public func filling(for item: LayoutItem, in source: CGRect) -> CGRect {
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
    public var currentRect: CGRect {
        let items = self.items()
        guard items.count > 0 else { fatalError(StackLayoutScheme.message(forNotActive: self)) }
        return items.reduce(nil) { return $0?.union($1.frame) ?? $1.frame }!
    }

    public /// Calculate and apply frames layout items.
    /// Should be call when parent `LayoutItem` item has corrected bounds. Else result unexpected.
    func layout() {
        let subItems = items()
        guard let sourceRect = subItems.first?.superItem!.frame else { return }

        layout(in: sourceRect)
    }

    public /// Calculate and apply frames layout items in custom space.
    ///
    /// - Parameter sourceRect: Source space
    func layout(in sourceRect: CGRect) {
        let subItems = items()
        var frames: [CGRect] = subItems.map { subItem in
            return alignment.layout(rect: filling.filling(for: subItem, in: sourceRect), in: sourceRect)
        }
        frames = distribution.distribute(rects: frames, in: sourceRect)
        zip(subItems, frames).forEach { $0.frame = $1 }
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
        let frames = distribution.distribute(
            rects: subItems.map { alignment.layout(rect: filling.filling(for: $0, in: sourceRect), in: sourceRect) }, // TODO: Alignment center is fail, apply for source rect, that may have big size.
            in: sourceRect
        )
        var iterator = subItems.makeIterator()
        let snapshotFrame = frames.reduce(into: frames.first) { snapRect, current in
            completedRects.insert((iterator.next()!, current), at: 0)
            snapRect = snapRect?.union(current) ?? current
        }
        return LayoutSnapshot(childSnapshots: frames, snapshotFrame: snapshotFrame ?? CGRect(origin: sourceRect.origin, size: .zero))
    }
}

// TODO: After add need recalculate layout

/// StackLayoutGuide layout guide for arranging items in ordered list. It's analogue UIStackView.
/// For configure layout parameters use property `scheme`.
/// Attention: before addition items to stack, need add stack layout guide to super layout item using `func add(layoutGuide:)` method.
open class StackLayoutGuide<Parent: LayoutItemContainer>: LayoutGuide<Parent>, AdjustableLayoutItem, SelfSizedLayoutItem {
    private var insetAnchor: RectBasedConstraint?
    internal var items: [LayoutItem] = []
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

    internal func removeItem(_ item: LayoutItem) -> Bool {
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
// TODO: Add throw exception on insert arranged item when ownerItem is nil
// TODO: Remove methods not convinience, need add method with removing by index
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