//
//  stack.layoutGuide.cglayout.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 04/09/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

import Foundation

/// Version - Alpha

// TODO: Create RectAxisBasedDistribution as subprotocol RectBasedDistribution. Probably will contain `axis` property
// TODO: Try to built RectBasedLayout, RectBasedConstraint, RectBasedDistribution on RectAxis.
// TODO: In MacOS origin in left-bottom corner by default. NSView.isFlipped moves origin to left-top corner.

/// Base protocol for any layout distribution
protocol RectBasedDistribution {
    func distribute(rects: [CGRect], in sourceRect: CGRect, along axis: RectAxis) -> [CGRect] // TODO: Make lazy collection generic
}

func distributeFromLeading(rects: [CGRect], in sourceRect: CGRect, along axis: RectAxis, spacing: CGFloat) -> [CGRect] {
    var previous: CGRect?
    return rects.map { rect in
        var rect = rect
        axis.set(origin: (previous.map { _ in spacing } ?? 0) + (previous.map { axis.get(maxOf: $0) } ?? axis.get(minOf: sourceRect)), for: &rect)
        previous = rect
        return rect
    }
}
func distributeFromTrailing(rects: [CGRect], in sourceRect: CGRect, along axis: RectAxis, spacing: CGFloat) -> [CGRect] {
    var previous: CGRect?
    return rects.map { rect in
        var rect = rect
        axis.set(origin: (previous.map { _ in -spacing } ?? 0) + (previous.map { axis.get(minOf: $0) } ?? (axis.get(maxOf: sourceRect))) - axis.get(sizeAt: rect), for: &rect)
        previous = rect
        return rect
    }
}
func alignByCenter(rects: [CGRect], in sourceRect: CGRect, along axis: RectAxis) -> [CGRect] {
    let offset = axis.get(midOf: sourceRect) - (((axis.get(maxOf: rects.last!) - axis.get(minOf: rects.first!)) / 2) + axis.get(minOf: rects.first!))
    return rects.map { axis.offset(rect: $0, by: offset) }
}

func space(for rects: [CGRect], in sourceRect: CGRect, along axis: RectAxis) -> CGFloat {
    let fullLength = rects.reduce(0) { $0 + axis.get(sizeAt: $1) }
    return (axis.get(sizeAt: sourceRect) - fullLength) / CGFloat(rects.count - 1)
}

public struct StackDistribution: RectBasedDistribution {
    public enum Spacing {
        case equally
        case equal(CGFloat)
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

        public static func leading(_ offset: CGFloat = 0) -> Alignment { return Alignment(Layout.Alignment.leading(by: CGRectAxis.vertical, offset: offset)) } 
        public static func trailing(_ offset: CGFloat = 0) -> Alignment { return Alignment(Layout.Alignment.trailing(by: CGRectAxis.vertical, offset: offset)) } 
        public static func center(_ offset: CGFloat = 0) -> Alignment { return Alignment(Layout.Alignment.center(by: CGRectAxis.vertical, offset: offset)) } 

        public func formLayout(rect: inout CGRect, in source: CGRect) { 
            layout.formLayout(rect: &rect, in: source) 
        }

        func by(axis: RectAxis) -> Alignment { 
            let l = layout.by(axis: axis) 
            return .init(l) 
        } 
    }
    public enum Direction {
        case fromLeading
        case fromTrailing
        case fromCenter
    }
    public enum Filling {
        case equally
        case equal(CGFloat)
    }

    var spacing: Spacing
    var alignment: Alignment
    var direction: Direction
    var filling: Filling
    
    public func distribute(rects: [CGRect], in sourceRect: CGRect, along axis: RectAxis) -> [CGRect] {
        let fill: CGFloat = {
            let count = CGFloat(rects.count)
            switch self.filling {
            case .equal(let val):
                return val
            case .equally:
                return axis.get(sizeAt: sourceRect) / count 
            }
        }()

        let transverseAxis = axis.transverse()
        let filledRects = rects.map { rect -> CGRect in
            var rect = rect
            axis.set(size: fill, for: &rect)
            transverseAxis.set(size: transverseAxis.get(sizeAt: sourceRect), for: &rect)
            return rect
        }

        let spacing: CGFloat = {
            switch self.spacing {
            case .equally:
                return space(for: filledRects, in: sourceRect, along: axis)
            case .equal(let space):
                return space
            }
        }()

        let alignedRects = filledRects.map { alignment.layout(rect: $0, in: sourceRect) }
        switch direction {
        case .fromLeading:
            return distributeFromLeading(rects: alignedRects, in: sourceRect, along: axis, spacing: spacing)
        case .fromTrailing:
            return distributeFromTrailing(rects: alignedRects, in: sourceRect, along: axis, spacing: spacing)
        case .fromCenter:
            let leftDistributedRects = distributeFromLeading(rects: alignedRects, in: sourceRect, along: axis, spacing: spacing)
            return alignByCenter(rects: leftDistributedRects, in: sourceRect, along: axis)
        }
    }
}

// TODO: StackLayoutScheme lost multihierarchy layout. Research this. // Comment: Probably would be not available.
/// Defines layout for arranged items
public struct StackLayoutScheme: LayoutBlockProtocol {
    private var items: () -> [LayoutItem]

    public /// Flag, defines that block will be used for layout
    var isActive: Bool { return true }

    /// Designed initializer
    ///
    /// - Parameter items: Closure provides items
    public init(items: @escaping () -> [LayoutItem]) {
        self.items = items
    }

    public var axis: RectAxis = CGRectAxis.horizontal {
        didSet { alignment = alignment.by(axis: axis.transverse()) }
    }

    private var distribution: StackDistribution = StackDistribution(spacing: .equally, 
                                                                    alignment: .center(), 
                                                                    direction: .fromLeading,
                                                                    filling: .equally)
    public var spacing: StackDistribution.Spacing {
        set { distribution.spacing = newValue }
        get { return distribution.spacing }
    }
    public var alignment: StackDistribution.Alignment {
        set { distribution.alignment = newValue.by(axis: axis.transverse()) }
        get { return distribution.alignment }
    }
    public var filling: StackDistribution.Filling {
        set { distribution.filling = newValue }
        get { return distribution.filling }
    }
    public var direction: StackDistribution.Direction {
        set { distribution.direction = newValue }
        get { return distribution.direction }
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
        let frames = distribution.distribute(rects: subItems.map { $0.inLayoutTime.frame }, in: sourceRect, along: axis)
        zip(subItems, frames).forEach { $0.0.frame = $0.1 }
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
            rects: subItems.map { $0.inLayoutTime.frame }, // TODO: Alignment center is fail, apply for source rect, that may have big size.
            in: sourceRect,
            along: axis
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
