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
/// Add to a view with UIView.add(layoutGuide:) if will be used him as item in RectBasedLayout.apply(for item:, use constraints:)
open class LayoutGuide<Super: LayoutItem>: LayoutItem {
    open fileprivate(set) weak var ownerItem: Super? {
        didSet { superItem = ownerItem }
    }
    open var frame: CGRect
    open var bounds: CGRect
    open weak var superItem: LayoutItem?

    public init(frame: CGRect) {
        self.frame = frame
        self.bounds = CGRect(origin: .zero, size: frame.size)
    }
}
#if os(iOS) || os(tvOS)
public extension LayoutGuide where Super: UIView {
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
        guard let superItem = ownerItem else { return nil }

        let view = build(type)
        superItem.addSubview(view)
        return view
    }
}
#endif
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
        guard let superItem = ownerItem else { return nil }

        let layer = build(type)
        superItem.addSublayer(layer)
        return layer
    }
}
public extension LayoutItem {
    /// Bind layout item to layout guide. Should call if layout guide will be applied RectBasedLayout.apply(for item:, use constraints:) method.
    ///
    /// - Parameter layoutGuide: Layout guide for binding
    func add(layoutGuide: LayoutGuide<Self>) {
        layoutGuide.ownerItem = self
    }
}
extension LayoutGuide {
    func add(layoutGuide: LayoutGuide<Super>) {
        layoutGuide.ownerItem = self.ownerItem
    }
    func removeFromSuperItem() {
        ownerItem = nil
    }
}

#if os(iOS) || os(tvOS)
/// Base class for any view placeholder that need dynamic position and/or size.
/// Used UIViewController pattern for loading target view, therefore will be very simply use him.
open class ViewPlaceholder<View: UIView>: LayoutGuide<UIView> {
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
            viewDidLoad()
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
        guard let superItem = owningView else { return nil }

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
        return currentSpace
    }

    /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
        sourceRect = anchors.reduce(sourceRect) { $0.1.constrained(sourceRect: $0.0, by: rect) }
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

/// Size-based constraint for constrain source rect by size of string. The size to draw gets from restrictive rect.
@available(OSX 10.11, *)
public struct StringLayoutConstraint: RectBasedConstraint {
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
    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
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
    func layoutConstraint(with options: NSStringDrawingOptions = .usesLineFragmentOrigin, attributes: [String: Any]? = nil, context: NSStringDrawingContext? = nil) -> StringLayoutConstraint {
        return StringLayoutConstraint(string: self, options: options, attributes: attributes, context: context)
    }
}

// MARK: Additional layout scheme

// TODO: Implement stack layout scheme and others

public struct StackLayoutScheme: LayoutBlockProtocol {
    public enum Axis {
        case horizontal
        case vertical
    }
    public enum Direction {
        case toTrailing
        case toLeading
    }

    public var items: [LayoutItem] // TODO: May be using getter closure for receive items
    private var axisAnchor: RectBasedConstraint = LayoutAnchor.Right.align(by: .outer)

    public var itemLayout: RectBasedLayout = Layout(x: .left(), y: .top(), width: .scaled(1), height: .scaled(1))
    public var axis: Axis = .horizontal {
        didSet { setAxisAnchor(for: axis, direction: direction) }
    }
    public var direction: Direction = .toTrailing {
        didSet { setAxisAnchor(for: axis, direction: direction) }
    }

    private mutating func setAxisAnchor(for axis: Axis, direction: Direction) {
        switch axis {
        case .horizontal:
            axisAnchor = direction == .toTrailing ? LayoutAnchor.Right.align(by: .outer) : LayoutAnchor.Left.align(by: .outer)
        case .vertical:
            axisAnchor = direction == .toTrailing ? LayoutAnchor.Bottom.align(by: .outer) : LayoutAnchor.Top.align(by: .outer)
        }
    }

    public init<S: Sequence>(items: S) where S.Iterator.Element: LayoutItem {
        self.items = Array(items)
    }

    // MARK: LayoutBlockProtocol

    public /// Snapshot for current state without recalculating
    var currentSnapshot: LayoutSnapshotProtocol {
        var snapshotFrame: CGRect!
        return LayoutSnapshot(childSnapshots: items.map { block in
            let blockFrame = block.frame
            snapshotFrame = snapshotFrame?.union(blockFrame) ?? blockFrame
            return blockFrame
        }, snapshotFrame: snapshotFrame)
    }


    public /// Calculate and apply frames layout items.
    /// Should be call when parent `LayoutItem` item has corrected bounds. Else result unexpected.
    func layout() {
        var preview: LayoutItem?
        items.forEach { subItem in
            let constraints: [ConstrainRect] = preview.map { [($0.frame, axisAnchor)] } ?? []
            itemLayout.apply(for: subItem, use: constraints)
            preview = subItem
        }
    }

    public /// Applying frames from snapshot to `LayoutItem` items in this block.
    /// Snapshot array should be ordered such to match `LayoutItem` items sequence.
    ///
    /// - Parameter snapshot: Snapshot represented as array of frames.
    func apply(snapshot: LayoutSnapshotProtocol) {
        var iterator = items.makeIterator()
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
        var snapshotFrame: CGRect!
        var preview: LayoutItem?
        return LayoutSnapshot(childSnapshots: items.map { item in
            let constraints: [ConstrainRect] = preview.map { [($0.frame, axisAnchor)] } ?? []
            let itemFrame = itemLayout.layout(rect: item.frame, in: sourceRect, use: constraints)
            completedRects.insert((item, itemFrame), at: 0)
            preview = item

            snapshotFrame = snapshotFrame?.union(itemFrame) ?? itemFrame
            return itemFrame
        }, snapshotFrame: snapshotFrame)
    }
}

public class StackLayoutGuide<Parent: LayoutItem>: LayoutGuide<Parent>, AdjustableLayoutItem {
    var scheme: StackLayoutScheme = StackLayoutScheme(items: [Parent]())

    

    public /// Asks the layout item to calculate and return the size that best fits the specified size
    ///
    /// - Parameter size: The size for which the view should calculate its best-fitting size
    /// - Returns: A new size that fits the receiver’s content
    func sizeThatFits(_ size: CGSize) -> CGSize {
        return scheme.snapshot(for: bounds).snapshotFrame.size
    }
}
