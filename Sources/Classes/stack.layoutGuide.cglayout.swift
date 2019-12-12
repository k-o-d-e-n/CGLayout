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
        return LayoutSnapshot(childSnapshots: frames, frame: snapshotFrame ?? CGRect(origin: sourceRect.origin, size: .zero))
    }
}

/// StackLayoutGuide layout guide for arranging items in ordered list. It's analogue UIStackView.
/// For configure layout parameters use property `scheme`.
/// Attention: before addition items to stack, need add stack layout guide to super layout element using `func add(layoutGuide:)` method.
open class StackLayoutGuide<Parent: LayoutElementsContainer>: LayoutGuide<Parent>, AdjustableLayoutElement, AdaptiveLayoutElement {
    private var insetAnchor: RectBasedConstraint?
    internal var items: [LayoutElement] = []
    /// StackLayoutScheme entity for configuring axis, distribution and other parameters.
    open lazy var scheme: StackLayoutScheme = StackLayoutScheme { [unowned self] in self.items }
    /// The list of items arranged by the stack layout guide
    open var arrangedItems: [LayoutElement] { return items }
    /// Insets for distribution space
    open var contentInsets: EdgeInsets = .zero {
        didSet { insetAnchor = Inset(contentInsets) }
    }
    /// Layout item where added this layout guide. For addition use `func add(layoutGuide:)`.
    open override var ownerElement: Parent? {
        willSet {
            if newValue == nil {
                items.forEach { $0.removeFromSuperElement() }
            }
        }
        /// while stack layout guide cannot add subitems
//        didSet {
//            if let owner = ownerElement {
//                items.forEach { element in owner.addSublayoutItem(element) }
//            }
//        }
    }

    internal func removeItem(_ item: LayoutElement) -> Bool {
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
        var result = scheme.snapshot(for: insetAnchor?.constrained(sourceRect: sourceRect, by: .zero) ?? sourceRect).frame.distanceFromOrigin
        result.width += contentInsets.right
        result.height += contentInsets.bottom
        return result
    }

    override open var debugContentOfDescription: String {
        return "  - items: \(items.debugDescription)"
    }
}

#if os(iOS) || os(tvOS)
extension StackLayoutGuide where Parent: UIView {
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter element: Layout guide for addition.
    public func addArrangedElement<T: UIView>(_ element: LayoutGuide<T>) { insertArrangedElement(element, at: items.count) }
    /// Inserts a element to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - element: Layout guide for addition
    ///   - index: Index in list.
    public func insertArrangedElement<T: UIView>(_ element: LayoutGuide<T>, at index: Int) {
        ownerElement?.addChildElement(unsafeBitCast(element, to: LayoutGuide<UIView>.self))
        items.insert(element, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter element: Layout guide for removing.
    public func removeArrangedElement<T: UIView>(_ element: LayoutGuide<T>) {
        guard removeItem(element), ownerElement === element.superElement else { return }
        element.removeFromSuperElement()
    }
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter element: Layout guide for addition.
    public func addArrangedElement<T: CALayer>(_ element: LayoutGuide<T>) { insertArrangedElement(element, at: items.count) }
    /// Inserts a element to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - element: Layout guide for addition
    ///   - index: Index in list.
    public func insertArrangedElement<T: CALayer>(_ element: LayoutGuide<T>, at index: Int) {
        ownerElement?.addChildElement(unsafeBitCast(element, to: LayoutGuide<CALayer>.self))
        items.insert(element, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter element: Layout guide for removing.
    public func removeArrangedElement<T: CALayer>(_ element: LayoutGuide<T>) {
        guard removeItem(element), ownerElement?.layer === element.superElement else { return }
        element.removeFromSuperElement()
    }
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter element: View for addition.
    public func addArrangedElement(_ element: UIView) { insertArrangedElement(element, at: items.count) }
    /// Inserts a element to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - element: View for addition
    ///   - index: Index in list.
    public func insertArrangedElement(_ element: UIView, at index: Int) {
        ownerElement?.addChildElement(element)
        items.insert(element, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter element: View for removing.
    public func removeArrangedElement(_ element: UIView) {
        guard removeItem(element), ownerElement === element.superElement else { return }
        element.removeFromSuperElement()
    }
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter element: Layer for addition.
    public func addArrangedElement(_ element: CALayer) { insertArrangedElement(element, at: items.count) }
    /// Inserts a element to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - element: Layer for addition
    ///   - index: Index in list.
    public func insertArrangedElement(_ element: CALayer, at index: Int) {
        ownerElement?.addChildElement(element)
        items.insert(element, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter element: Layer for removing.
    public func removeArrangedElement(_ element: CALayer) {
        guard removeItem(element), ownerElement?.layer === element.superElement else { return }
        element.removeFromSuperElement()
    }
}
#endif
#if os(macOS) || os(iOS) || os(tvOS)
extension StackLayoutGuide where Parent: CALayer {
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter element: Layout guide for addition.
    public func addArrangedElement<T: CALayer>(_ item: LayoutGuide<T>) { insertArrangedElement(item, at: items.count) }
    /// Inserts a element to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - element: Layout guide for addition
    ///   - index: Index in list.
    public func insertArrangedElement<T: CALayer>(_ item: LayoutGuide<T>, at index: Int) {
        ownerElement?.addChildElement(unsafeBitCast(item, to: LayoutGuide<CALayer>.self))
        items.insert(item, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter element: Layout guide for removing.
    public func removeArrangedElement(_ item: LayoutElement) {
        guard removeItem(item), ownerElement === item.superElement else { return }
        item.removeFromSuperElement()
    }
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter element: CALayer for addition.
    public func addArrangedElement(_ item: CALayer) { insertArrangedElement(item, at: items.count) }
    /// Inserts a element to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - element: Layer for addition
    ///   - index: Index in list.
    public func insertArrangedElement(_ item: CALayer, at index: Int) {
        ownerElement?.addChildElement(item)
        items.insert(item, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter element: Layer for removing.
    public func removeArrangedElement(_ item: CALayer) {
        guard removeItem(item), ownerElement === item.superElement else { return }
        item.removeFromSuperElement()
    }
}
#endif
#if os(macOS)
extension StackLayoutGuide where Parent: NSView {
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter element: Layout guide for addition.
    public func addArrangedElement<T: NSView>(_ element: LayoutGuide<T>) { insertArrangedElement(element, at: items.count) }
    /// Inserts a element to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - element: Layout guide for addition
    ///   - index: Index in list.
    public func insertArrangedElement<T: NSView>(_ element: LayoutGuide<T>, at index: Int) {
        ownerElement?.addChildElement(unsafeBitCast(element, to: LayoutGuide<NSView>.self))
        items.insert(element, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter element: Layout guide for removing.
    public func removeArrangedElement<T: NSView>(_ element: LayoutGuide<T>) {
        guard removeItem(element), ownerElement === element.superElement else { return }
        element.removeFromSuperElement()
    }
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter element: Layout guide for addition.
    public func addArrangedElement<T: CALayer>(_ element: LayoutGuide<T>) { insertArrangedElement(element, at: items.count) }
    /// Inserts a element to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - element: Layout guide for addition
    ///   - index: Index in list.
    public func insertArrangedElement<T: CALayer>(_ element: LayoutGuide<T>, at index: Int) {
        ownerElement?.addChildElement(unsafeBitCast(element, to: LayoutGuide<CALayer>.self))
        items.insert(element, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter element: Layout guide for removing.
    public func removeArrangedElement<T: CALayer>(_ element: LayoutGuide<T>) {
        guard removeItem(element), ownerElement?.layer === element.superElement else { return }
        element.removeFromSuperElement()
    }
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter element: View for addition.
    public func addArrangedElement(_ element: NSView) { insertArrangedElement(element, at: items.count) }
    /// Inserts a element to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - element: View for addition
    ///   - index: Index in list.
    public func insertArrangedElement(_ element: NSView, at index: Int) {
        ownerElement?.addChildElement(element)
        items.insert(element, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter element: View for removing.
    public func removeArrangedElement(_ element: NSView) {
        guard removeItem(element), ownerElement === element.superElement else { return }
        element.removeFromSuperElement()
    }
    /// Adds a layout guide to the end of the `arrangedItems` list.
    ///
    /// - Parameter element: Layer for addition.
    public func addArrangedElement(_ element: CALayer) { insertArrangedElement(element, at: items.count) }
    /// Inserts a element to arrangedItems list at specific index.
    ///
    /// - Parameters:
    ///   - element: Layer for addition
    ///   - index: Index in list.
    public func insertArrangedElement(_ element: CALayer, at index: Int) {
        ownerElement?.addChildElement(element)
        items.insert(element, at: index)
    }
    /// Removes from `arrangedItems` list and from hierarchy.
    ///
    /// - Parameter element: Layer for removing.
    public func removeArrangedElement(_ element: CALayer) {
        guard removeItem(element), ownerElement?.layer === element.superElement else { return }
        element.removeFromSuperElement()
    }
}
#endif
