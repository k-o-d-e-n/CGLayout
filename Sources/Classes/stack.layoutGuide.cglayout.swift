//
//  stack.layoutGuide.cglayout.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 04/09/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#elseif os(Linux)
import Foundation
#endif

/// Version - Alpha

/// Base protocol for any layout distribution
protocol RectBasedDistribution {
    func distribute(rects: [CGRect], in sourceRect: CGRect, along axis: RectAxis) -> [CGRect]
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
        guard rects.count > 0 else { return rects }
        let fill: CGFloat = {
            let count = CGFloat(rects.count)
            switch (self.filling, self.spacing) {
            case (.equal(let val), _):
                return val
            case (.equally, .equal(let space)):
                return (axis.get(sizeAt: sourceRect) - (count - 1) * space) / count
            case (.equally, .equally):
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
        guard direction != .fromCenter else {
            let leftDistributedRects = distributeFromLeading(rects: alignedRects, in: sourceRect, along: axis, spacing: spacing)
            return alignByCenter(rects: leftDistributedRects, in: sourceRect, along: axis)
        }
        let rtl = CGLConfiguration.default.isRTLMode && axis.isHorizontal
        if (direction == .fromLeading && !rtl) || (direction == .fromTrailing && rtl) {
            return distributeFromLeading(rects: alignedRects, in: sourceRect, along: axis, spacing: spacing)
        } else {
            return distributeFromTrailing(rects: alignedRects, in: sourceRect, along: axis, spacing: spacing)
        }
    }
}

/// Defines layout for arranged items
public struct StackLayoutScheme: LayoutBlockProtocol {
    private var items: () -> [LayoutElement]

    public /// Flag, defines that block will be used for layout
    var isActive: Bool { return true }

    /// Designed initializer
    ///
    /// - Parameter items: Closure provides items
    public init(items: @escaping () -> [LayoutElement]) {
        self.items = items
    }

    public var axis: RectAxis = CGRectAxis.horizontal {
        didSet { alignment = alignment.by(axis: axis.transverse()) }
    }

    private var distribution: StackDistribution = StackDistribution(
        spacing: .equally,
        alignment: .center(),
        direction: .fromLeading,
        filling: .equally
    )
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
        }, frame: snapshotFrame ?? .zero)
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
        guard let sourceRect = subItems.first?.superElement!.frame else { return }

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
            iterator.next()?.frame = child.frame
        }
    }

    public /// Returns snapshot for all `LayoutItem` items in block. Attention: in during calculating snapshot frames of layout items must not changed.
    ///
    /// - Parameter sourceRect: Source space for layout
    /// - Returns: Snapshot contained frames layout items
    func snapshot(for sourceRect: CGRect) -> LayoutSnapshotProtocol {
        var completedFrames: [ObjectIdentifier: CGRect] = [:]
        return snapshot(for: sourceRect, completedRects: &completedFrames)
    }

    public /// Method for perform layout calculation in child blocks. Does not call this method directly outside `LayoutBlockProtocol` object.
    /// Layout block should be insert contained `LayoutItem` items to completedRects
    ///
    /// - Parameters:
    ///   - sourceRect: Source space for layout. For not top level blocks rect should be define available bounds of block
    ///   - completedRects: `LayoutItem` items with corrected frame
    /// - Returns: Frame of this block
    func snapshot(for sourceRect: CGRect, completedRects: inout [ObjectIdentifier : CGRect]) -> LayoutSnapshotProtocol {
        let subItems = items()
        let frames = distribution.distribute(
            rects: subItems.map { $0.inLayoutTime.frame }, // TODO: Alignment center is fail, apply for source rect, that may have big size.
            in: sourceRect,
            along: axis
        )
        var iterator = subItems.makeIterator()
        let snapshotFrame = frames.reduce(into: frames.first) { snapRect, current in
            completedRects[ObjectIdentifier(iterator.next()!)] = current
            snapRect = snapRect?.union(current) ?? current
        }
        return LayoutSnapshot(childSnapshots: frames, frame: snapshotFrame ?? CGRect(origin: sourceRect.origin, size: .zero))
    }
}

/// StackLayoutGuide layout guide for arranging items in ordered list. It's analogue UIStackView.
/// For configure layout parameters use property `scheme`.
/// Attention: before addition items to stack, need add stack layout guide to super layout element using `func add(layoutGuide:)` method.
open class StackLayoutGuide<Parent: LayoutElement>: LayoutGuide<Parent>, AdjustableLayoutElement, AdaptiveLayoutElement {
    private var insetAnchor: RectBasedConstraint?
    internal var items: [Element] = []
    /// StackLayoutScheme entity for configuring axis, distribution and other parameters.
    open lazy var scheme: StackLayoutScheme = StackLayoutScheme { [unowned self] in self.arrangedItems }
    /// The list of items arranged by the stack layout guide
    open var arrangedItems: [LayoutElement] { return items.map { $0.child } }
    /// Insets for distribution space
    open var contentInsets: EdgeInsets = .zero {
        didSet { insetAnchor = Inset(contentInsets) }
    }
    /// Layout item where added this layout guide. For addition use `func add(layoutGuide:)`.
    open override var ownerElement: Parent? {
        willSet {
            if newValue == nil {
                items.forEach { $0.child.removeFromSuperElement() }
            }
        }
        /// while stack layout guide cannot add subitems
        didSet {
            if let owner = ownerElement {
                items.forEach({ $0.add(to: owner) })
            }
        }
    }

    public convenience init(items: [Element]) {
        self.init(frame: .zero)
        self.items = items
    }

    internal func removeItem(_ item: LayoutElement) -> LayoutElement? {
        guard let index = items.index(where: { $0.child === item }) else { return nil }

        return items.remove(at: index).child
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
        var result = scheme.snapshot(for: insetAnchor?.constrained(sourceRect: sourceRect, by: .zero) ?? sourceRect).frame.distanceFromOrigin
        result.width += contentInsets.right
        result.height += contentInsets.bottom
        return result
    }

    override open var debugContentOfDescription: String {
        return "  - items: \(items.debugDescription)"
    }
}
extension StackLayoutGuide {
    public struct Element {
        let base: _AnyEnterPoint<Parent>
        var child: LayoutElement { return base.child }

        init<Point: EnterPoint>(_ base: Point) where Point.Container == Parent {
            self.base = _Enter(base)
        }

        func add(to container: Parent) {
            base.add(to: container)
        }
    }
    /// Adds an element to the end of the `arrangedItems` list.
    ///
    /// - Parameter point: Enter point.
    public func addArranged(element: Element) {
        insertArranged(element: element, at: items.count)
    }
    /// Inserts an element to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - point: Enter point
    ///   - index: Index in list.
    public func insertArranged(element: Element, at index: Int) {
        items.insert(element, at: index)
        if let owner = ownerElement {
            element.add(to: owner)
        }
    }
    /// Removes element from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter element: Layout element for removing.
    public func removeArranged(element: LayoutElement) {
        removeItem(element)?.removeFromSuperElement()
    }
}

#if os(macOS) || os(iOS) || os(tvOS)
public extension StackLayoutGuide.Element where Parent: CALayer {
    static func caLayer<C: CALayer>(_ child: C) -> Self {
        return Self(Sublayer<Parent>(layer: child))
    }
    private struct Sublayer<L: CALayer>: EnterPoint {
        let layer: CALayer
        var child: LayoutElement { layer }
        func add(to container: L) {
            container.addSublayer(layer)
        }
    }
    static func layoutGuide<LG, C: CALayer>(_ child: LG) -> Self where LG: LayoutGuide<C> {
        return Self(LayoutGuideSublayer<C, Parent>(lg: child))
    }
    private struct LayoutGuideSublayer<Owner: CALayer, L: CALayer>: EnterPoint {
        let lg: LayoutGuide<Owner>
        var child: LayoutElement { lg }
        func add(to container: L) {
            container.add(layoutGuide: lg)
        }
    }
}
#endif
#if os(iOS) || os(tvOS)
public extension StackLayoutGuide.Element where Parent: UIView {
    static func caLayer<C: CALayer>(_ child: C) -> Self {
        return Self(Layer<Parent>(layer: child))
    }
    private struct Layer<V: UIView>: EnterPoint {
        let layer: CALayer
        var child: LayoutElement { layer }
        func add(to container: V) {
            container.layer.addSublayer(layer)
        }
    }
    static func uiView<C: UIView>(_ child: C) -> Self {
        return Self(View<Parent>(view: child))
    }
    private struct View<V: UIView>: EnterPoint {
        let view: UIView
        var child: LayoutElement { view }
        func add(to container: V) {
            container.addSubview(view)
        }
    }
    static func layoutGuide<LG, C: UIView>(_ child: LG) -> Self where LG: LayoutGuide<C> {
        return Self(LayoutGuideView<C, Parent>(lg: child))
    }
    private struct LayoutGuideView<Owner: UIView, V: UIView>: EnterPoint {
        let lg: LayoutGuide<Owner>
        var child: LayoutElement { lg }
        func add(to container: V) {
            container.add(layoutGuide: lg)
        }
    }
    static func layoutGuide<LG, C: CALayer>(_ child: LG) -> Self where LG: LayoutGuide<C> {
        return Self(LayoutGuideLayer<C, Parent>(lg: child))
    }
    private struct LayoutGuideLayer<Owner: CALayer, V: UIView>: EnterPoint {
        let lg: LayoutGuide<Owner>
        var child: LayoutElement { lg }
        func add(to container: V) {
            container.layer.add(layoutGuide: lg)
        }
    }
}
#endif
#if os(macOS)
public extension StackLayoutGuide.Element where Parent: NSView {
    static func caLayer<C: CALayer>(_ child: C) -> Self {
        return Self(Layer<Parent>(layer: child))
    }
    private struct Layer<V: NSView>: EnterPoint {
        let layer: CALayer
        var child: LayoutElement { layer }
        func add(to container: V) {
            container.layer?.addSublayer(layer)
        }
    }
    static func uiView<C: NSView>(_ child: C) -> Self {
        return Self(View<Parent>(view: child))
    }
    private struct View<V: NSView>: EnterPoint {
        let view: NSView
        var child: LayoutElement { view }
        func add(to container: V) {
            container.addSubview(view)
        }
    }
    static func layoutGuide<LG, C: NSView>(_ child: LG) -> Self where LG: LayoutGuide<C> {
        return Self(LayoutGuideView<C, Parent>(lg: child))
    }
    private struct LayoutGuideView<Owner: NSView, V: NSView>: EnterPoint {
        let lg: LayoutGuide<Owner>
        var child: LayoutElement { lg }
        func add(to container: V) {
            container.add(layoutGuide: lg)
        }
    }
    static func layoutGuide<LG, C: CALayer>(_ child: LG) -> Self where LG: LayoutGuide<C> {
        return Self(LayoutGuideLayer<C, Parent>(lg: child))
    }
    private struct LayoutGuideLayer<Owner: CALayer, V: NSView>: EnterPoint {
        let lg: LayoutGuide<Owner>
        var child: LayoutElement { lg }
        func add(to container: V) {
            container.layer?.add(layoutGuide: lg)
        }
    }
}
#endif
