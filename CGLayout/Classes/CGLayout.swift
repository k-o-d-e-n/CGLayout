//
//  Layout.swift
//  FirstAppObjC
//
//  Created by Denis Koryttsev on 29/08/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

import UIKit

// TODO: !! Comment all code
// TODO: ! Add RTL (right to left language)
// TODO: !! Implement behavior on remove view from hierarchy (Unwrapped LayoutItem, break result in ConstraintsItem). Probably need add `isActive` property.
// TODO: ! Add support UITraitCollection
// TODO: !!! Add MacOS, tvOS support
// TODO: !!! Resolve problem with create offset for adjusted views.
// TODO: ! Add CGRect.integral

// TODO: !!! Tests for new code

/// Defines method for wrapping entity with base behavior to this type.
public protocol Extended {
    associatedtype Conformed
    /// Common method for create entity of this type with base behavior.
    ///
    /// - Parameter base: Entity implements required behavior
    /// - Returns: Initialized entity
    static func build(_ base: Conformed) -> Self
}

// MARK: RectBasedLayout

public protocol RectBasedLayout {
    /// Performing layout of given rect inside available rect.
    /// Attention: Apply layout for view frame using code as layout(rect: &view.frame,...) has side effect and called setFrame method on view.
    ///
    /// - Parameters:
    ///   - rect: Rect for layout
    ///   - source: Available space for layout
    func layout(rect: inout CGRect, in source: CGRect)
}

/// Tuple of rect and constraint for constrain other rect
public typealias ConstrainRect = (rect: CGRect, constraint: RectBasedConstraint)

public extension RectBasedLayout {
    /// Wrapper for main layout function. This is used for working with immutable values.
    ///
    /// - Parameters:
    ///   - rect: Rect for layout
    ///   - source: Available space for layout
    /// - Returns: Corrected rect
    public func layout(rect: CGRect, in source: CGRect) -> CGRect {
        var rect = rect
        layout(rect: &rect, in: source)
        return rect
    }

    /// Used for layout `LayoutItem` entity in constrained bounds of parent item using constraints.
    ///
    /// - Parameters:
    ///   - item: Item for layout
    ///   - constraints: Array of tuples with rect and constraint
    public func apply(for item: LayoutItem, use constraints: [ConstrainRect] = []) {
        item.frame = layout(rect: item.frame, in: item.superItem!.bounds, use: constraints)
    }
    /// Used for layout `LayoutItem` entity in constrained source space using constraints.
    ///
    /// - Parameters:
    ///   - item: Item for layout
    ///   - source: Source space
    ///   - constraints: Array of tuples with rect and constraint
    public func apply(for item: LayoutItem, in source: CGRect, use constraints: [ConstrainRect] = []) {
        item.frame = layout(rect: item.frame, in: source, use: constraints)
    }

    /// Calculates frame of `LayoutItem` entity in constrained source space using constraints.
    ///
    /// - Parameters:
    ///   - item: Item for layout
    ///   - constraints: Array of constraint items
    /// - Returns: Array of tuples with rect and constraint
    public func layout(rect: CGRect, in sourceRect: CGRect, use constraints: [ConstrainRect] = []) -> CGRect {
        let source = constraints.reduce(sourceRect) { (result, constrained) -> CGRect in
            return result.constrainedBy(rect: constrained.rect, use: constrained.constraint)
        }
        return layout(rect: rect, in: source)
    }

    /// Use for layout `LayoutItem` entity in constrained bounds of parent item using constraints.
    ///
    /// - Parameters:
    ///   - item: Item for layout
    ///   - constraints: Array of constraint items
    public func apply(for item: LayoutItem, use constraints: [LayoutConstraintProtocol]) {
        // TODO: ! Add flag for using layout margins. IMPL: Apply 'inset' constraint from LayotAnchor to super bounds.
        apply(for: item, in: item.superItem!.bounds, use: constraints)
    }
    /// Use for layout `LayoutItem` entity in constrained source space using constraints.
    ///
    /// - Parameters:
    ///   - item: Item for layout
    ///   - sourceRect: Source space
    ///   - constraints: Array of constraint items
    public func apply(for item: LayoutItem, in sourceRect: CGRect, use constraints: [LayoutConstraintProtocol]) {
        item.frame = layout(rect: item.frame, from: item.superItem!, in: sourceRect, use: constraints)
    }

    /// Calculates frame of `LayoutItem` entity in constrained source space using constraints.
    ///
    /// - Parameters:
    ///   - rect: Rect for layout
    ///   - item: `LayoutItem` item contained `rect`
    ///   - sourceRect: Space for layout
    ///   - constraints: Array of constraint items
    /// - Returns: Corrected frame of layout item
    public func layout(rect: CGRect, from item: LayoutItem, in sourceRect: CGRect, use constraints: [LayoutConstraintProtocol] = []) -> CGRect {
        return layout(rect: rect, in: constraints.reduce(sourceRect) { $1.constrained(sourceRect: $0, in: item) })
    }
}

// MARK: RectBasedConstraint

/// Main protocol for any layout constraint
public protocol RectBasedConstraint {
    /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    func constrain(sourceRect: inout CGRect, by rect: CGRect)
}
extension RectBasedConstraint {
    /// Wrapper for main constrain function. This is used for working with immutable values.
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    /// - Returns: Constrained source rect
    public func constrained(sourceRect: CGRect, by rect: CGRect) -> CGRect {
        var sourceRect = sourceRect
        constrain(sourceRect: &sourceRect, by: rect)
        return sourceRect
    }
}
extension CGRect {
    /// Convenience method for constrain
    ///
    /// - Parameters:
    ///   - rect: Rect for constrain
    ///   - constraints: List of constraints
    /// - Returns: Constrained source rect
    func constrainedBy(rect: CGRect, use constraints: [RectBasedConstraint]) -> CGRect {
        return constraints.reduce(self) { $1.constrained(sourceRect: $0, by: rect) }
    }
    func constrainedBy(rect: CGRect, use constraint: RectBasedConstraint) -> CGRect {
        return constraint.constrained(sourceRect: self, by: rect)
    }
}

// MARK: LayoutItem

/// Protocol for any layout element
public protocol LayoutItem: class, LayoutCoordinateSpace {
    /// External representation of layout entity in coordinate space
    var frame: CGRect { get set }
    /// Internal coordinate space of layout entity
    var bounds: CGRect { get set }
    /// Layout item that maintained this layout entity
    weak var superItem: LayoutItem? { get }

    /// Removes layout item from hierarchy
    func removeFromSuperItem()
}
extension UIView: AdjustableLayoutItem {
    /// Layout item that maintained this layout entity
    public weak var superItem: LayoutItem? { return superview }
    /// Removes layout item from hierarchy
    public func removeFromSuperItem() { removeFromSuperview() }
}

extension LayoutItem {
    /// Convenience getter for tuple of item frame and anchor constraint
    ///
    /// - Parameter anchor: Anchor constraint
    /// - Returns: Tuple of item frame and anchor constraint
    func frameConstraint(for anchor: RectBasedConstraint) -> ConstrainRect {
        return (frame, anchor)
    }
    /// Convenience getter for tuple of item bounds and anchor constraint
    ///
    /// - Parameter anchor: Anchor constraint
    /// - Returns: Tuple of item bounds and anchor constraint
    func boundsConstraint(for anchor: RectBasedConstraint) -> ConstrainRect {
        return (bounds, anchor)
    }
    /// Convenience getter for constraint item related to this entity
    ///
    /// - Parameter anchors: Array of anchor constraints
    /// - Returns: Related constraint item
    public func layoutConstraint(for anchors: [RectBasedConstraint]) -> LayoutConstraint {
        return LayoutConstraint(item: self, constraints: anchors)
    }
    /// Convenience getter for layout block related to this entity
    ///
    /// - Parameters:
    ///   - layout: Main layout for this entity
    ///   - constraints: Array of related constraint items
    /// - Returns: Related layout block
    public func layoutBlock(with layout: RectBasedLayout, constraints: [LayoutConstraintProtocol] = []) -> LayoutBlock<Self> {
        return LayoutBlock(item: self, layout: layout, constraints: constraints)
    }
}

// MARK: AdjustableLayoutItem

/// Protocol for items that can calculate yourself fitted size
public protocol AdjustableLayoutItem: LayoutItem {
    /// Asks the layout item to calculate and return the size that best fits the specified size
    ///
    /// - Parameter size: The size for which the view should calculate its best-fitting size
    /// - Returns: A new size that fits the receiver’s content
    func sizeThatFits(_ size: CGSize) -> CGSize
}
extension AdjustableLayoutItem {
    /// Convenience getter for adjust constraint item related to this entity
    ///
    /// - Parameter anchors: Array of anchor constraints
    /// - Returns: Related adjust constraint item
    public func adjustLayoutConstraint(for anchors: [LayoutAnchor.Size]) -> AdjustLayoutConstraint {
        return AdjustLayoutConstraint(item: self, constraints: anchors)
    }
}

// MARK: LayoutConstraint

/// Provides rect for constrain source space. Used for related constraints.
// TODO: Change protocol definition. It is not exactly describe layout constraint.
public protocol LayoutConstraintProtocol: RectBasedConstraint {
    /// Flag that constraint not required other calculations. It`s true for size-based constraints.
    var isIndependent: Bool { get }
    /// `LayoutItem` object associated with this constraint
    func layoutItem(is object: AnyObject) -> Bool
    /// Return rectangle for constrain source rect
    ///
    /// - Parameter currentSpace: Source rect in current state
    /// - Parameter coordinateSpace: Working coordinate space
    /// - Returns: Rect for constrain
    func constrainRect(for currentSpace: CGRect, in coordinateSpace: LayoutItem) -> CGRect
    /// Converts rect from constraint coordinate space to destination coordinate space if needed.
    ///
    /// - Parameters:
    ///   - rect: Initial rect
    ///   - coordinateSpace: Destination coordinate space
    /// - Returns: Converted rect
    func convert(rectIfNeeded rect: CGRect, to coordinateSpace: LayoutItem) -> CGRect
}
extension LayoutConstraintProtocol {
    fileprivate func constrained(sourceRect: CGRect, in coordinateSpace: LayoutItem) -> CGRect {
        return constrained(sourceRect: sourceRect, by: constrainRect(for: sourceRect, in: coordinateSpace))
    }
}

/// Simple related constraint. Contains anchor constraints and layout item as source of frame for constrain
public struct LayoutConstraint {
    let constraints: [RectBasedConstraint]
    private(set) weak var item: LayoutItem!

    public init(item: LayoutItem, constraints: [RectBasedConstraint]) {
        self.item = item
        self.constraints = constraints
    }
}
extension LayoutConstraint: LayoutConstraintProtocol {
    public /// Flag that constraint not required other calculations. It`s true for size-based constraints.
    var isIndependent: Bool { return false }

    public /// `LayoutItem` object associated with this constraint
    func layoutItem(is object: AnyObject) -> Bool {
        return item === object
    }

    public /// Return rectangle for constrain source rect
    ///
    /// - Parameter currentSpace: Source rect in current state
    /// - Parameter coordinateSpace: Working coordinate space
    /// - Returns: Rect for constrain
    func constrainRect(for currentSpace: CGRect, in coordinateSpace: LayoutItem) -> CGRect {
        return convert(rectIfNeeded: item.frame, to: coordinateSpace)
    }

    public /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
        sourceRect = sourceRect.constrainedBy(rect: rect, use: constraints)
    }

    public /// Converts rect from constraint coordinate space to destination coordinate space if needed.
    ///
    /// - Parameters:
    ///   - rect: Initial rect
    ///   - coordinateSpace: Destination coordinate space
    /// - Returns: Converted rect
    func convert(rectIfNeeded rect: CGRect, to coordinateSpace: LayoutItem) -> CGRect {
        return coordinateSpace === item.superItem! ? rect : coordinateSpace.convert(rect: rect, from: item.superItem!)
    }
}

/// Related constraint for adjust size of source space. Contains size constraints and layout item for calculate size.
public struct AdjustLayoutConstraint {
    let constraints: [LayoutAnchor.Size]
    private(set) weak var item: AdjustableLayoutItem!

    public init(item: AdjustableLayoutItem, constraints: [LayoutAnchor.Size]) {
        self.item = item
        self.constraints = constraints
    }
}
extension AdjustLayoutConstraint: LayoutConstraintProtocol {
    public /// Flag that constraint not required other calculations. It`s true for size-based constraints.
    var isIndependent: Bool { return true }

    public /// `LayoutItem` object associated with this constraint
    func layoutItem(is object: AnyObject) -> Bool {
        return item === object
    }

    public /// Return rectangle for constrain source rect
    ///
    /// - Parameter currentSpace: Source rect in current state
    /// - Parameter coordinateSpace: Working coordinate space
    /// - Returns: Rect for constrain
    func constrainRect(for currentSpace: CGRect, in coordinateSpace: LayoutItem) -> CGRect {
        return currentSpace
    }

    public /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
        sourceRect = sourceRect.constrainedBy(rect: CGRect(origin: rect.origin, size: item.sizeThatFits(rect.size)), use: constraints)
    }

    public /// Converts rect from constraint coordinate space to destination coordinate space if needed.
    ///
    /// - Parameters:
    ///   - rect: Initial rect
    ///   - coordinateSpace: Destination coordinate space
    /// - Returns: Converted rect
    func convert(rectIfNeeded rect: CGRect, to coordinateSpace: LayoutItem) -> CGRect {
        return rect
    }
}

// MARK: LayoutBlock

/// Defines frame of layout block, and child blocks
public protocol LayoutSnapshotProtocol {
    /// Frame of layout block represented as snapshot
    var snapshotFrame: CGRect { get }
    /// Snapshots of child layout blocks
    var childSnapshots: [LayoutSnapshotProtocol] { get }
}
extension CGRect: LayoutSnapshotProtocol {
    /// Returns self value
    public var snapshotFrame: CGRect { return self }
    /// Returns empty array
    public var childSnapshots: [LayoutSnapshotProtocol] { return [] }
}

/// Represents frame of block where was received. Contains snapshots for child blocks.
struct LayoutSnapshot: LayoutSnapshotProtocol {
    let childSnapshots: [LayoutSnapshotProtocol]
    let snapshotFrame: CGRect
}

/// Defines general methods for any layout block
public protocol LayoutBlockProtocol {
    /// Snapshot for current state without recalculating
    var currentSnapshot: LayoutSnapshotProtocol { get }

    /// Calculate and apply frames layout items.
    /// Should be call when parent `LayoutItem` item has corrected bounds. Else result unexpected.
    func layout()

    /// Calculate and apply frames layout items in custom space.
    ///
    /// - Parameter sourceRect: Source space
    func layout(in sourceRect: CGRect)

    /// Returns snapshot for all `LayoutItem` items in block. Attention: in during calculating snapshot frames of layout items must not changed. 
    ///
    /// - Parameter sourceRect: Source space for layout
    /// - Returns: Snapshot contained frames layout items
    func snapshot(for sourceRect: CGRect) -> LayoutSnapshotProtocol

    /// Method for perform layout calculation in child blocks. Does not call this method directly outside `LayoutBlockProtocol` object.
    /// Layout block should be insert contained `LayoutItem` items to completedRects
    ///
    /// - Parameters:
    ///   - sourceRect: Source space for layout. For not top level blocks rect should be define available bounds of block
    ///   - completedRects: `LayoutItem` items with corrected frame
    /// - Returns: Frame of this block
    func snapshot(for sourceRect: CGRect, completedRects: inout [(AnyObject, CGRect)]) -> LayoutSnapshotProtocol

    /// Applying frames from snapshot to `LayoutItem` items in this block. 
    /// Snapshot array should be ordered such to match `LayoutItem` items sequence.
    ///
    /// - Parameter snapshot: Snapshot represented as array of frames.
    func apply(snapshot: LayoutSnapshotProtocol)
}

/// Makes full layout for `LayoutItem` entity. Contains main layout, related anchor constrains and item for layout.
public struct LayoutBlock<Item: LayoutItem>: LayoutBlockProtocol { // TODO: Rename to LayoutElement ???
    private let itemLayout: RectBasedLayout
    private let constraints: [LayoutConstraintProtocol]
    public private(set) weak var item: Item!

    public /// Snapshot for current state without recalculating
    var currentSnapshot: LayoutSnapshotProtocol { return item.frame }

    public init(item: Item, layout: RectBasedLayout, constraints: [LayoutConstraintProtocol] = []) {
        self.item = item
        self.itemLayout = layout
        self.constraints = constraints
    }

    public /// Calculate and apply frames layout items.
    /// Should be call when parent `LayoutItem` item has corrected bounds. Else result unexpected.
    func layout() {
        itemLayout.apply(for: item, use: constraints)
    }

    public /// Calculate and apply frames layout items in custom space.
    ///
    /// - Parameter sourceRect: Source space
    func layout(in sourceRect: CGRect) {
        itemLayout.apply(for: item, in: sourceRect, use: constraints)
    }

    public /// Returns snapshot for all `LayoutItem` items in block. Attention: in during calculating snapshot frames of layout items must not changed.
    ///
    /// - Parameter sourceRect: Source space for layout
    /// - Returns: Snapshot contained frames layout items
    func snapshot(for sourceRect: CGRect) -> LayoutSnapshotProtocol {
        return itemLayout.layout(rect: item.frame, from: item.superItem!, in: sourceRect, use: constraints)
    }

    public /// Method for perform layout calculation in child blocks. Does not call this method directly outside `LayoutBlockProtocol` object.
    /// Layout block should be insert contained `LayoutItem` items to completedRects
    ///
    /// - Parameters:
    ///   - sourceRect: Source space for layout. For not top level blocks rect should be define available bounds of block
    ///   - completedRects: `LayoutItem` items with corrected frame
    /// - Returns: Frame of this block
    func snapshot(for sourceRect: CGRect, completedRects: inout [(AnyObject, CGRect)]) -> LayoutSnapshotProtocol {
        let source = constraints.reduce(sourceRect) { (result, constraint) -> CGRect in
            let rect = constraint.isIndependent ? nil : completedRects.first { constraint.layoutItem(is: $0.0) }?.1
            let constrainRect = rect.map { constraint.convert(rectIfNeeded: $0, to: item.superItem!) } /// converts rect to current coordinate space if needed
                ?? constraint.constrainRect(for: result, in: item.superItem!)
            return result.constrainedBy(rect: constrainRect, use: constraint)
        }
        let frame = itemLayout.layout(rect: item.frame, in: source)
        completedRects.insert((item, frame), at: 0)
        return frame
    }

    public /// Applying frames from snapshot to `LayoutItem` items in this block.
    /// Snapshot array should be ordered such to match `LayoutItem` items sequence.
    ///
    /// - Parameter snapshot: Snapshot represented as array of frames.
    func apply(snapshot: LayoutSnapshotProtocol) {
        item.frame = snapshot.snapshotFrame
    }
}

/// LayoutScheme defines layout process for some layout blocks.
/// Represented as simple set of layout blocks with the right sequence, that means
/// currently performed block has constraints related to `LayoutItem` items with corrected frame.
/// LayoutScheme can contain other layout schemes.
public struct LayoutScheme: LayoutBlockProtocol {
    private let blocks: [LayoutBlockProtocol]

    public /// Snapshot for current state without recalculating
    var currentSnapshot: LayoutSnapshotProtocol {
        var snapshotFrame: CGRect!
        return LayoutSnapshot(childSnapshots: blocks.map { block in
            let blockFrame = block.currentSnapshot.snapshotFrame
            snapshotFrame = snapshotFrame?.union(blockFrame) ?? blockFrame
            return blockFrame
        }, snapshotFrame: snapshotFrame)
    }

    public init(blocks: [LayoutBlockProtocol]) {
        self.blocks = blocks
    }

    public /// Calculate and apply frames layout items.
    /// Should be call when parent `LayoutItem` item has corrected bounds. Else result unexpected.
    func layout() {
        blocks.forEach { $0.layout() }
    }

    public /// Calculate and apply frames layout items.
    ///
    /// - Parameter sourceRect: Source space
    func layout(in sourceRect: CGRect) {
        blocks.forEach { $0.layout(in: sourceRect) }
    }

    public /// Applying frames from snapshot to `LayoutItem` items in this block.
    /// Snapshot array should be ordered such to match `LayoutItem` items sequence.
    ///
    /// - Parameter snapshot: Snapshot represented as array of frames.
    func apply(snapshot: LayoutSnapshotProtocol) {
        var iterator = blocks.makeIterator()
        for child in snapshot.childSnapshots {
            iterator.next()?.apply(snapshot: child)
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
        return LayoutSnapshot(childSnapshots: blocks.map { block in
            let blockSnapshot = block.snapshot(for: sourceRect, completedRects: &completedRects)
            snapshotFrame = snapshotFrame?.union(blockSnapshot.snapshotFrame) ?? blockSnapshot.snapshotFrame
            return blockSnapshot
        }, snapshotFrame: snapshotFrame)
    }
}

// MARK: LayoutAnchor

// TODO: ! Add center, baseline and other behaviors
// TODO: !! Hide types that not used directly

/// Provides set of anchor constraints
public struct LayoutAnchor {
    /// Set of constraints related to center of restrictive rect
    public struct Center: RectBasedConstraint, Extended {
        public typealias Conformed = RectBasedConstraint
        private let base: RectBasedConstraint
        private init(base: RectBasedConstraint) { self.base = base }
        public /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func constrain(sourceRect: inout CGRect, by rect: CGRect) { base.constrain(sourceRect: &sourceRect, by: rect) }
        public /// Common method for create entity of this type with base behavior.
        ///
        /// - Parameter base: Entity implements required behavior
        /// - Returns: Initialized entity
        static func build(_ base: RectBasedConstraint) -> LayoutAnchor.Center { return .init(base: base) }

        /// Returns alignment constraint by center
        ///
        /// - Parameter dependency: Anchor dependency for target rect
        /// - Returns: Alignment constraint typed by Center
        public static func align(by dependency: Align.Dependence) -> Center { return Center(base: dependency) }
        public struct Align {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint
                public /// Main function for constrain source space by other rect
                ///
                /// - Parameters:
                ///   - sourceRect: Source space
                ///   - rect: Rect for constrain
                func constrain(sourceRect: inout CGRect, by rect: CGRect) { base.constrain(sourceRect: &sourceRect, by: rect) }

                public static var origin: Dependence { return Dependence(base: Origin()) }
                public struct Origin: RectBasedConstraint {
                    public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        sourceRect.origin.x = rect.midX
                        sourceRect.origin.y = rect.midY
                    }
                }
                public static var center: Dependence { return Dependence(base: Center()) }
                public struct Center: RectBasedConstraint {
                    private let alignment = Layout.Alignment(horizontal: .center(), vertical: .center())
                    public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        alignment.layout(rect: &sourceRect, in: rect)
                    }
                }
            }
        }
    }

    /// Returns constraint, that applies UIEdgeInsets to source rect.
    ///
    /// - Parameter value: UIEdgeInsets value
    /// - Returns: Inset constraint
    public static func insets(_ value: UIEdgeInsets) -> RectBasedConstraint { return Inset(insets: value) }
    private struct Inset: RectBasedConstraint {
        let insets: UIEdgeInsets
        /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func constrain(sourceRect: inout CGRect, by rect: CGRect) {
            sourceRect.apply(edgeInsets: insets)
        }
    }

    /// Constraint, that makes source rect equally to passed rect
    public static var equal: RectBasedConstraint { return Equal() }
    private struct Equal: RectBasedConstraint {
        /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func constrain(sourceRect: inout CGRect, by rect: CGRect) {
            sourceRect = rect
        }
    }

    /// Set of size-based constraints
    public struct Size: RectBasedConstraint, Extended {
        public typealias Conformed = RectBasedConstraint
        private let base: RectBasedConstraint
        private init(base: RectBasedConstraint) { self.base = base }

        public /// Common method for create entity of this type with base behavior.
        ///
        /// - Parameter base: Entity implements required behavior
        /// - Returns: Initialized entity
        static func build(_ base: RectBasedConstraint) -> LayoutAnchor.Size { return .init(base: base) }

        public /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func constrain(sourceRect: inout CGRect, by rect: CGRect) { base.constrain(sourceRect: &sourceRect, by: rect) }

        /// Constraint, that makes height of source rect equal to height passed rect.
        ///
        /// - Parameter multiplier: Multiplier for height value
        /// - Returns: Height constraint typed by Size
        public static func height(_ multiplier: CGFloat = 1) -> Size { return Size(base: Height(multiplier: multiplier)) }
        private struct Height: RectBasedConstraint {
            let multiplier: CGFloat

            /// Main function for constrain source space by other rect
            ///
            /// - Parameters:
            ///   - sourceRect: Source space
            ///   - rect: Rect for constrain
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                sourceRect.size.height = rect.height.multiplied(by: multiplier)
            }
        }

        /// Constraint, that makes width of source rect equal to width passed rect.
        ///
        /// - Parameter multiplier: Multiplier for width value
        /// - Returns: Width constraint typed by Size
        public static func width(_ multiplier: CGFloat = 1) -> Size { return Size(base: Width(multiplier: multiplier)) }
        private struct Width: RectBasedConstraint {
            let multiplier: CGFloat

            /// Main function for constrain source space by other rect
            ///
            /// - Parameters:
            ///   - sourceRect: Source space
            ///   - rect: Rect for constrain
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                sourceRect.size.width = rect.width.multiplied(by: multiplier)
            }
        }
    }

    /// Set of constraints related to bottom of restrictive rect
    public struct Bottom: RectBasedConstraint, Extended {
        public typealias Conformed = RectBasedConstraint
        private let base: RectBasedConstraint
        private init(base: RectBasedConstraint) { self.base = base }

        public /// Common method for create entity of this type with base behavior.
        ///
        /// - Parameter base: Entity implements required behavior
        /// - Returns: Initialized entity
        static func build(_ base: RectBasedConstraint) -> LayoutAnchor.Bottom { return .init(base: base) }

        public /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func constrain(sourceRect: inout CGRect, by rect: CGRect) {
            base.constrain(sourceRect: &sourceRect, by: rect)
        }

        /// Returns alignment constraint by bottom
        ///
        /// - Parameter dependency: Space dependency for target rect
        /// - Returns: Alignment constraint typed by Bottom
        public static func align(by dependency: Align.Dependence) -> Bottom { return Bottom(base: dependency) }
        public struct Align {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint

                public /// Main function for constrain source space by other rect
                ///
                /// - Parameters:
                ///   - sourceRect: Source space
                ///   - rect: Rect for constrain
                func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                    base.constrain(sourceRect: &sourceRect, by: rect)
                }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Bottom.alignInside(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }

                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Bottom.align(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
            }
        }

        // TODO: May be need use Limit as returned type to have strong type.
        // TODO: May be need rename to Crop.
        /// Returns constraint, that limits source rect by bottom of passed rect. If source rect intersects bottom of passed rect, source rect will be cropped, else will not changed.
        ///
        /// - Parameter dependency: Space dependency for target rect
        /// - Returns: Limit constraint typed by Bottom
        public static func limit(on dependency: Limit.Dependence) -> Bottom { return Bottom(base: dependency) }
        public struct Limit {
            public struct Dependence: RectBasedConstraint {// TODO: May be need implement inner/outer behaviors inside Limit space.
                private let base: RectBasedConstraint

                public /// Main function for constrain source space by other rect
                ///
                /// - Parameters:
                ///   - sourceRect: Source space
                ///   - rect: Rect for constrain
                func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                    base.constrain(sourceRect: &sourceRect, by: rect)
                }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Bottom.cropInside(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Bottom.crop(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
            }
        }

        /// Returns constraint, that pulls source rect to bottom of passed rect. If source rect intersects bottom of passed rect, source rect will be cropped, else will pulled with changing size.
        ///
        /// - Parameter dependency: Space dependency for target rect
        /// - Returns: Pull constraint typed by Bottom
        public static func pull(from dependency: Pull.Dependence) -> Bottom { return Bottom(base: dependency) }
        public struct Pull {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint

                public /// Main function for constrain source space by other rect
                ///
                /// - Parameters:
                ///   - sourceRect: Source space
                ///   - rect: Rect for constrain
                func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                    base.constrain(sourceRect: &sourceRect, by: rect)
                }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Bottom.pullInside(sourceRect: &sourceRect, toConstrained: rect)
                    }
                }
                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Bottom.pull(sourceRect: &sourceRect, toConstrained: rect)
                    }
                }
            }
        }

        static private func alignInside(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.origin.y = rect.maxY - sourceRect.height
        }
        static private func align(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.origin.y = rect.maxY
        }
        static private func cropInside(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.size.height = max(0, min(sourceRect.height, sourceRect.height - space(fromFarEdgeOf: sourceRect, toConstrained: rect)))
            sourceRect.origin.y = min(sourceRect.origin.y, rect.maxY)
        }
        static private func crop(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.size.height = max(0, min(sourceRect.height, space(fromFarEdgeOf: sourceRect, toConstrained: rect)))
            sourceRect.origin.y = max(sourceRect.origin.y, rect.maxY)
        }
        static private func pullInside(sourceRect: inout CGRect, toConstrained rect: CGRect) {
            sourceRect.size.height = max(0, rect.maxY - sourceRect.origin.y)
            alignInside(sourceRect: &sourceRect, byConstrained: rect)
        }
        static private func pull(sourceRect: inout CGRect, toConstrained rect: CGRect) {
            sourceRect.size.height = max(0, space(fromFarEdgeOf: sourceRect, toConstrained: rect))
            align(sourceRect: &sourceRect, byConstrained: rect)
        }
        static private func space(fromFarEdgeOf sourceRect: CGRect, toConstrained rect: CGRect) -> CGFloat {
            return sourceRect.maxY - rect.maxY
        }
    }

    /// Set of constraints related to right of restrictive rect
    public struct Right: RectBasedConstraint, Extended {
        public typealias Conformed = RectBasedConstraint
        private let base: RectBasedConstraint
        private init(base: RectBasedConstraint) { self.base = base }

        public /// Common method for create entity of this type with base behavior.
        ///
        /// - Parameter base: Entity implements required behavior
        /// - Returns: Initialized entity
        static func build(_ base: RectBasedConstraint) -> LayoutAnchor.Right { return .init(base: base) }

        public /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func constrain(sourceRect: inout CGRect, by rect: CGRect) { base.constrain(sourceRect: &sourceRect, by: rect) }

        /// Returns alignment constraint by right
        ///
        /// - Parameter dependency: Space dependency for target rect
        /// - Returns: Alignment constraint typed by Right
        public static func align(by dependency: Align.Dependence) -> Right { return Right(base: dependency) }
        public struct Align {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint

                public /// Main function for constrain source space by other rect
                ///
                /// - Parameters:
                ///   - sourceRect: Source space
                ///   - rect: Rect for constrain
                func constrain(sourceRect: inout CGRect, by rect: CGRect) { base.constrain(sourceRect: &sourceRect, by: rect) }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Right.alignInside(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }

                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Right.align(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
            }
        }

        /// Returns constraint, that limits source rect by right of passed rect. If source rect intersects right of passed rect, source rect will be cropped, else will not changed.
        ///
        /// - Parameter dependency: Space dependency for target rect
        /// - Returns: Limit constraint typed by Right
        public static func limit(on dependency: Limit.Dependence) -> Right { return Right(base: dependency) }
        public struct Limit {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint

                public /// Main function for constrain source space by other rect
                ///
                /// - Parameters:
                ///   - sourceRect: Source space
                ///   - rect: Rect for constrain
                func constrain(sourceRect: inout CGRect, by rect: CGRect) { base.constrain(sourceRect: &sourceRect, by: rect) }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Right.cropInside(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Right.crop(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
            }
        }

        /// Returns constraint, that pulls source rect to right of passed rect. If source rect intersects right of passed rect, source rect will be cropped, else will pulled with changing size.
        ///
        /// - Parameter dependency: Space dependency for target rect
        /// - Returns: Pull constraint typed by Right
        public static func pull(from dependency: Pull.Dependence) -> Right { return Right(base: dependency) }
        public struct Pull {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint

                public /// Main function for constrain source space by other rect
                ///
                /// - Parameters:
                ///   - sourceRect: Source space
                ///   - rect: Rect for constrain
                func constrain(sourceRect: inout CGRect, by rect: CGRect) { base.constrain(sourceRect: &sourceRect, by: rect) }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Right.pullInside(sourceRect: &sourceRect, toConstrained: rect)
                    }
                }
                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Right.pull(sourceRect: &sourceRect, toConstrained: rect)
                    }
                }
            }
        }

        static private func alignInside(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.origin.x = rect.maxX - sourceRect.width
        }
        static private func align(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.origin.x = rect.maxX
        }
        static private func cropInside(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.size.width = max(0, min(sourceRect.width, sourceRect.width - space(fromFarEdgeOf: sourceRect, toConstrained: rect)))
            sourceRect.origin.x = min(sourceRect.origin.x, rect.maxX)
        }
        static private func crop(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.size.width = max(0, min(sourceRect.width, space(fromFarEdgeOf: sourceRect, toConstrained: rect)))
            sourceRect.origin.x = max(sourceRect.origin.x, rect.maxX)
        }
        static private func pullInside(sourceRect: inout CGRect, toConstrained rect: CGRect) {
            sourceRect.size.width = max(0, rect.maxX - sourceRect.origin.x)
            alignInside(sourceRect: &sourceRect, byConstrained: rect)
        }
        static private func pull(sourceRect: inout CGRect, toConstrained rect: CGRect) {
            sourceRect.size.width = max(0, space(fromFarEdgeOf: sourceRect, toConstrained: rect))
            align(sourceRect: &sourceRect, byConstrained: rect)
        }
        static private func space(fromFarEdgeOf sourceRect: CGRect, toConstrained rect: CGRect) -> CGFloat {
            return sourceRect.maxX - rect.maxX
        }
    }

    /// Set of constraints related to left of restrictive rect
    public struct Left: RectBasedConstraint, Extended {
        public typealias Conformed = RectBasedConstraint
        private let base: RectBasedConstraint
        private init(base: RectBasedConstraint) { self.base = base }

        public /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func constrain(sourceRect: inout CGRect, by rect: CGRect) { base.constrain(sourceRect: &sourceRect, by: rect) }

        public /// Common method for create entity of this type with base behavior.
        ///
        /// - Parameter base: Entity implements required behavior
        /// - Returns: Initialized entity
        static func build(_ base: RectBasedConstraint) -> LayoutAnchor.Left { return .init(base: base) }

        /// Returns alignment constraint by left
        ///
        /// - Parameter dependency: Space dependency for target rect
        /// - Returns: Alignment constraint typed by Left
        public static func align(by dependency: Align.Dependence) -> Left { return Left(base: dependency) }
        public struct Align {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint

                public /// Main function for constrain source space by other rect
                ///
                /// - Parameters:
                ///   - sourceRect: Source space
                ///   - rect: Rect for constrain
                func constrain(sourceRect: inout CGRect, by rect: CGRect) { base.constrain(sourceRect: &sourceRect, by: rect) }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Left.alignInside(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }

                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Left.align(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
            }
        }

        /// Returns constraint, that limits source rect by left of passed rect. If source rect intersects left of passed rect, source rect will be cropped, else will not changed.
        ///
        /// - Parameter dependency: Space dependency for target rect
        /// - Returns: Limit constraint typed by Left
        public static func limit(on dependency: Limit.Dependence) -> Left { return Left(base: dependency) }
        public struct Limit {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint

                public /// Main function for constrain source space by other rect
                ///
                /// - Parameters:
                ///   - sourceRect: Source space
                ///   - rect: Rect for constrain
                func constrain(sourceRect: inout CGRect, by rect: CGRect) { base.constrain(sourceRect: &sourceRect, by: rect) }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Left.cropInside(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Left.crop(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
            }
        }

        /// Returns constraint, that pulls source rect to left of passed rect. If source rect intersects left of passed rect, source rect will be cropped, else will pulled with changing size.
        ///
        /// - Parameter dependency: Space dependency for target rect
        /// - Returns: Pull constraint typed by Left
        public static func pull(from dependency: Pull.Dependence) -> Left { return Left(base: dependency) }
        public struct Pull {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint

                public /// Main function for constrain source space by other rect
                ///
                /// - Parameters:
                ///   - sourceRect: Source space
                ///   - rect: Rect for constrain
                func constrain(sourceRect: inout CGRect, by rect: CGRect) { base.constrain(sourceRect: &sourceRect, by: rect) }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Left.pullInside(sourceRect: &sourceRect, toConstrained: rect)
                    }
                }
                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Left.pull(sourceRect: &sourceRect, toConstrained: rect)
                    }
                }
            }
        }

        static private func alignInside(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.origin.x = rect.minX
        }
        static private func align(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.origin.x = rect.minX - sourceRect.width
        }
        static private func cropInside(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.size.width = max(0, min(sourceRect.width, sourceRect.width - space(fromFarEdgeOf: sourceRect, toConstrained: rect)))
            sourceRect.origin.x = max(sourceRect.origin.x, rect.minX)
        }
        static private func crop(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.size.width = max(0, min(sourceRect.width, space(fromFarEdgeOf: sourceRect, toConstrained: rect)))
            sourceRect.origin.x = min(sourceRect.origin.x, rect.minX)
        }
        static private func pullInside(sourceRect: inout CGRect, toConstrained rect: CGRect) {
            sourceRect.size.width = max(0, sourceRect.maxX - rect.minX)
            alignInside(sourceRect: &sourceRect, byConstrained: rect)
        }
        static private func pull(sourceRect: inout CGRect, toConstrained rect: CGRect) {
            sourceRect.size.width = max(0, space(fromFarEdgeOf: sourceRect, toConstrained: rect))
            align(sourceRect: &sourceRect, byConstrained: rect)
        }
        static private func space(fromFarEdgeOf sourceRect: CGRect, toConstrained rect: CGRect) -> CGFloat {
            return rect.minX - sourceRect.minX
        }
    }

    /// Set of constraints related to top of restrictive rect
    public struct Top: RectBasedConstraint, Extended {
        public typealias Conformed = RectBasedConstraint
        private let base: RectBasedConstraint
        private init(base: RectBasedConstraint) { self.base = base }

        public /// Common method for create entity of this type with base behavior.
        ///
        /// - Parameter base: Entity implements required behavior
        /// - Returns: Initialized entity
        static func build(_ base: RectBasedConstraint) -> LayoutAnchor.Top { return .init(base: base) }

        public /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func constrain(sourceRect: inout CGRect, by rect: CGRect) { base.constrain(sourceRect: &sourceRect, by: rect) }

        /// Returns alignment constraint by top
        ///
        /// - Parameter dependency: Space dependency for target rect
        /// - Returns: Alignment constraint typed by Top
        public static func align(by dependency: Align.Dependence) -> Top { return Top(base: dependency) }
        public struct Align {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint

                public /// Main function for constrain source space by other rect
                ///
                /// - Parameters:
                ///   - sourceRect: Source space
                ///   - rect: Rect for constrain
                func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                    base.constrain(sourceRect: &sourceRect, by: rect)
                }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Top.alignInside(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }

                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Top.align(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
            }
        }

        /// Returns constraint, that limits source rect by top of passed rect. If source rect intersects top of passed rect, source rect will be cropped, else will not changed.
        ///
        /// - Parameter dependency: Space dependency for target rect
        /// - Returns: Limit constraint typed by Top
        public static func limit(on dependency: Limit.Dependence) -> Top { return Top(base: dependency) }
        public struct Limit {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint
                public /// Main function for constrain source space by other rect
                ///
                /// - Parameters:
                ///   - sourceRect: Source space
                ///   - rect: Rect for constrain
                func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                    base.constrain(sourceRect: &sourceRect, by: rect)
                }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Top.cropInside(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Top.crop(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
            }
        }

        /// Returns constraint, that pulls source rect to top of passed rect. If source rect intersects top of passed rect, source rect will be cropped, else will pulled with changing size.
        ///
        /// - Parameter dependency: Space dependency for target rect
        /// - Returns: Pull constraint typed by Top
        public static func pull(from dependency: Pull.Dependence) -> Top { return Top(base: dependency) }
        public struct Pull {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint
                public /// Main function for constrain source space by other rect
                ///
                /// - Parameters:
                ///   - sourceRect: Source space
                ///   - rect: Rect for constrain
                func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                    base.constrain(sourceRect: &sourceRect, by: rect)
                }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Top.pullInside(sourceRect: &sourceRect, toConstrained: rect)
                    }
                }
                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    /// Main function for constrain source space by other rect
                    ///
                    /// - Parameters:
                    ///   - sourceRect: Source space
                    ///   - rect: Rect for constrain
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Top.pull(sourceRect: &sourceRect, toConstrained: rect)
                    }
                }
            }
        }

        static private func alignInside(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.origin.y = rect.minY
        }
        static private func align(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.origin.y = rect.minY - sourceRect.height
        }
        static private func cropInside(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.size.height = max(0, min(sourceRect.height, sourceRect.height - space(fromFarEdgeOf: sourceRect, toConstrained: rect)))
            sourceRect.origin.y = max(sourceRect.origin.y, rect.minY)
        }
        static private func crop(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.size.height = max(0, min(sourceRect.height, space(fromFarEdgeOf: sourceRect, toConstrained: rect)))
            sourceRect.origin.y = min(sourceRect.origin.y, rect.minY)
        }
        static private func pullInside(sourceRect: inout CGRect, toConstrained rect: CGRect) {
            sourceRect.size.height = max(0, sourceRect.maxY - rect.minY)
            alignInside(sourceRect: &sourceRect, byConstrained: rect)
        }
        static private func pull(sourceRect: inout CGRect, toConstrained rect: CGRect) {
            sourceRect.size.height = max(0, space(fromFarEdgeOf: sourceRect, toConstrained: rect))
            align(sourceRect: &sourceRect, byConstrained: rect)
        }
        static private func space(fromFarEdgeOf sourceRect: CGRect, toConstrained rect: CGRect) -> CGFloat {
            return rect.minY - sourceRect.minY
        }
    }
}

// MARK: Layout

/// Main layout structure. Use his for positioning and filling in source rect (which can be constrained using `RectBasedConstraint` constraints).
public struct Layout: RectBasedLayout {
    private let alignment: Alignment
    private let filling: Filling

    /// Designed initializer
    ///
    /// - Parameters:
    ///   - alignment: Alignment layout behavior
    ///   - filling: Filling layout behavior
    public init(alignment: Alignment, filling: Filling) {
        self.alignment = alignment
        self.filling = filling
    }

    public /// Performing layout of given rect inside available rect.
    /// Attention: Apply layout for view frame using code as layout(rect: &view.frame,...) has side effect and called setFrame method on view.
    ///
    /// - Parameters:
    ///   - rect: Rect for layout
    ///   - source: Available space for layout
    func layout(rect: inout CGRect, in source: CGRect) {
        filling.layout(rect: &rect, in: source)
        alignment.layout(rect: &rect, in: source)
    }

    /// Alignment part of main layout.
    public struct Alignment: RectBasedLayout {
        private let horizontal: Horizontal
        private let vertical: Vertical

        /// Designed initializer
        ///
        /// - Parameters:
        ///   - horizontal: Horizontal alignment behavior
        ///   - vertical: Vertical alignment behavior
        public init(horizontal: Horizontal, vertical: Vertical) {
            self.vertical = vertical
            self.horizontal = horizontal
        }

        public /// Performing layout of given rect inside available rect.
        /// Attention: Apply layout for view frame using code as layout(rect: &view.frame,...) has side effect and called setFrame method on view.
        ///
        /// - Parameters:
        ///   - rect: Rect for layout
        ///   - source: Available space for layout
        func layout(rect: inout CGRect, in source: CGRect) {
            vertical.layout(rect: &rect, in: source)
            horizontal.layout(rect: &rect, in: source)
        }

        public struct Horizontal: RectBasedLayout, Extended {
            public typealias Conformed = RectBasedLayout
            private let base: RectBasedLayout
            private init(base: RectBasedLayout) { self.base = base }

            public /// Performing layout of given rect inside available rect.
            /// Attention: Apply layout for view frame using code as layout(rect: &view.frame,...) has side effect and called setFrame method on view.
            ///
            /// - Parameters:
            ///   - rect: Rect for layout
            ///   - source: Available space for layout
            func layout(rect: inout CGRect, in source: CGRect) { base.layout(rect: &rect, in: source) }

            public /// Common method for create entity of this type with base behavior.
            ///
            /// - Parameter base: Entity implements required behavior
            /// - Returns: Initialized entity
            static func build(_ base: RectBasedLayout) -> Layout.Alignment.Horizontal { return .init(base: base) }

            /// Horizontal alignment by center of source rect
            ///
            /// - Parameter offset: Offset value. Positive value gives offset to right.
            /// - Returns: Center alignment typed by Horizontal
            public static func center(_ offset: CGFloat = 0) -> Horizontal { return Horizontal(base: Center(offset: offset)) }
            private struct Center: RectBasedLayout {
                let offset: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.x = source.midX - (rect.width / 2) + offset
                }
            }
            /// Horizontal alignment by left of source rect
            ///
            /// - Parameter offset: Offset value. Positive value gives offset to right.
            /// - Returns: Left alignment typed by Horizontal
            public static func left(_ offset: CGFloat = 0) -> Horizontal { return Horizontal(base: Left(offset: offset)) }
            private struct Left: RectBasedLayout {
                let offset: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.x = source.origin.x + offset
                }
            }
            /// Horizontal alignment by right of source rect
            ///
            /// - Parameter offset: Offset value. Positive value gives offset to left.
            /// - Returns: Right alignment typed by Horizontal
            public static func right(_ offset: CGFloat = 0) -> Horizontal { return Horizontal(base: Right(offset: offset)) }
            private struct Right: RectBasedLayout {
                let offset: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.x = source.maxX - rect.width - offset
                }
            }
        }
        public struct Vertical: RectBasedLayout, Extended {
            public typealias Conformed = RectBasedLayout
            private let base: RectBasedLayout
            private init(base: RectBasedLayout) { self.base = base }

            public /// Performing layout of given rect inside available rect.
            /// Attention: Apply layout for view frame using code as layout(rect: &view.frame,...) has side effect and called setFrame method on view.
            ///
            /// - Parameters:
            ///   - rect: Rect for layout
            ///   - source: Available space for layout
            func layout(rect: inout CGRect, in source: CGRect) { return base.layout(rect: &rect, in: source) }

            public /// Common method for create entity of this type with base behavior.
            ///
            /// - Parameter base: Entity implements required behavior
            /// - Returns: Initialized entity
            static func build(_ base: RectBasedLayout) -> Layout.Alignment.Vertical { return .init(base: base) }

            /// Vertical alignment by center of source rect
            ///
            /// - Parameter offset: Offset value. Positive value gives offset to bottom.
            /// - Returns: Center alignment typed by 'Vertical'
            public static func center(_ offset: CGFloat = 0) -> Vertical { return Vertical(base: Center(offset: offset)) }
            private struct Center: RectBasedLayout {
                let offset: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.y = source.midY - (rect.height / 2) + offset
                }
            }
            /// Vertical alignment by top of source rect
            ///
            /// - Parameter offset: Offset value. Positive value gives offset to bottom.
            /// - Returns: Top alignment typed by 'Vertical'
            public static func top(_ offset: CGFloat = 0) -> Vertical { return Vertical(base: Top(offset: offset)) }
            private struct Top: RectBasedLayout {
                let offset: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.y = source.origin.y + offset
                }
            }
            /// Vertical alignment by bottom of source rect
            ///
            /// - Parameter offset: Offset value. Positive value gives offset to top.
            /// - Returns: Bottom alignment typed by 'Vertical'
            public static func bottom(_ offset: CGFloat = 0) -> Vertical { return Vertical(base: Bottom(offset: offset)) }
            private struct Bottom: RectBasedLayout {
                let offset: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.y = source.maxY - rect.height - offset
                }
            }
        }
    }

    // TODO: ! Add ratio behavior
    /// Filling part of main layout
    public struct Filling: RectBasedLayout {
        private let horizontal: Horizontal
        private let vertical: Vertical

        public /// Performing layout of given rect inside available rect.
        /// Attention: Apply layout for view frame using code as layout(rect: &view.frame,...) has side effect and called setFrame method on view.
        ///
        /// - Parameters:
        ///   - rect: Rect for layout
        ///   - source: Available space for layout
        func layout(rect: inout CGRect, in source: CGRect) {
            vertical.layout(rect: &rect, in: source)
            horizontal.layout(rect: &rect, in: source)
        }

        /// Designed initializer
        ///
        /// - Parameters:
        ///   - horizontal: Horizontal filling behavior
        ///   - vertical: Vertical filling behavior
        public init(horizontal: Horizontal, vertical: Vertical) {
            self.vertical = vertical
            self.horizontal = horizontal
        }

        public struct Horizontal: RectBasedLayout, Extended {
            public typealias Conformed = RectBasedLayout
            fileprivate let base: RectBasedLayout
            fileprivate init(base: RectBasedLayout) { self.base = base }

            public /// Performing layout of given rect inside available rect.
            /// Attention: Apply layout for view frame using code as layout(rect: &view.frame,...) has side effect and called setFrame method on view.
            ///
            /// - Parameters:
            ///   - rect: Rect for layout
            ///   - source: Available space for layout
            func layout(rect: inout CGRect, in source: CGRect) { return base.layout(rect: &rect, in: source) }

            public /// Common method for create entity of this type with base behavior.
            ///
            /// - Parameter base: Entity implements required behavior
            /// - Returns: Initialized entity
            static func build(_ base: RectBasedLayout) -> Layout.Filling.Horizontal { return .init(base: base) }

//            public static var identity: Horizontal { return Horizontal(base: Identity()) }
//            private struct Identity: RectBasedLayout {
//                func layout(rect: inout CGRect, in source: CGRect) {}
//            }

            /// Provides rect with independed horizontal filling with fixed value
            ///
            /// - Parameter value: Value of width
            /// - Returns: Fixed behavior typed by 'Horizontal'
            public static func fixed(_ value: CGFloat) -> Horizontal { return Horizontal(base: Fixed(value: value)) }
            private struct Fixed: RectBasedLayout {
                let value: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.size.width = value
                }
            }

            /// Provides rect with width value scaled from width of source rect
            ///
            /// - Parameter scale: Scale value.
            /// - Returns: Scaled behavior typed by 'Horizontal'
            public static func scaled(_ scale: CGFloat) -> Horizontal { return Horizontal(base: Scaled(scale: scale)) }
            private struct Scaled: RectBasedLayout {
                let scale: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.size.width = source.width.multiplied(by: scale)
                }
            }

            /// Provides rect, that width is smaller or larger than the source rect, with the same center point.
            ///
            /// - Parameter insets: Value to use for adjusting the source rectangle
            /// - Returns: Boxed behavior typed by 'Horizontal'
            public static func boxed(_ insets: CGFloat) -> Horizontal { return Horizontal(base: Boxed(insets: insets)) }
            private struct Boxed: RectBasedLayout {
                let insets: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.size.width = max(0, source.width.subtracting(insets))
                }
            }
        }
        public struct Vertical: RectBasedLayout, Extended {
            public typealias Conformed = RectBasedLayout
            fileprivate let base: RectBasedLayout
            fileprivate init(base: RectBasedLayout) { self.base = base }

            public /// Performing layout of given rect inside available rect.
            /// Attention: Apply layout for view frame using code as layout(rect: &view.frame,...) has side effect and called setFrame method on view.
            ///
            /// - Parameters:
            ///   - rect: Rect for layout
            ///   - source: Available space for layout
            func layout(rect: inout CGRect, in source: CGRect) { return base.layout(rect: &rect, in: source) }

            public /// Common method for create entity of this type with base behavior.
            ///
            /// - Parameter base: Entity implements required behavior
            /// - Returns: Initialized entity
            static func build(_ base: RectBasedLayout) -> Layout.Filling.Vertical { return .init(base: base) }

//            public static var identity: Vertical { return Vertical(base: Identity()) }
//            private struct Identity: RectBasedLayout {
//                func layout(rect: inout CGRect, in source: CGRect) {}
//            }

            /// Provides rect with independed vertical filling with fixed value
            ///
            /// - Parameter value: Value of height
            /// - Returns: Fixed behavior typed by 'Vertical'
            public static func fixed(_ value: CGFloat) -> Vertical { return Vertical(base: Fixed(value: value)) }
            private struct Fixed: RectBasedLayout {
                let value: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.size.height = value
                }
            }

            /// Provides rect with height value scaled from height of source rect
            ///
            /// - Parameter scale: Scale value.
            /// - Returns: Scaled behavior typed by 'Vertical'
            public static func scaled(_ scale: CGFloat) -> Vertical { return Vertical(base: Scaled(scale: scale)) }
            private struct Scaled: RectBasedLayout {
                let scale: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.size.height = source.height.multiplied(by: scale)
                }
            }

            /// Provides rect, that height is smaller or larger than the source rect, with the same center point.
            ///
            /// - Parameter insets: Value to use for adjusting the source rectangle
            /// - Returns: Boxed behavior typed by 'Vertical'
            public static func boxed(_ insets: CGFloat) -> Vertical { return Vertical(base: Boxed(insets: insets)) }
            private struct Boxed: RectBasedLayout {
                let insets: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.size.height = max(0, source.height.subtracting(insets))
                }
            }
        }
    }
}

public extension Layout {
    /// Layout behavior, that makes passed rect equally to space rect
    public static var equal: RectBasedLayout { return Equal() }
    private struct Equal: RectBasedLayout {
        func layout(rect: inout CGRect, in source: CGRect) {
            rect = source
        }
    }
}

public extension Layout {
    public init(vertical: (alignment: Alignment.Vertical, filling: Filling.Vertical), horizontal: (alignment: Alignment.Horizontal, filling: Filling.Horizontal)) {
        self.init(alignment: Alignment(horizontal: horizontal.alignment, vertical: vertical.alignment),
                  filling: Filling(horizontal: horizontal.filling, vertical: vertical.filling))
    }
    /// Convinience initializer similar CGRect initializer.
    ///
    /// - Parameters:
    ///   - x: Horizontal alignment behavior
    ///   - y: Vertical alignment behavior
    ///   - width: Width filling behavior
    ///   - height: Height filling behavior
    public init(x: Alignment.Horizontal, y: Alignment.Vertical, width: Filling.Horizontal, height: Filling.Vertical) {
        self.init(alignment: Alignment(horizontal: x, vertical: y),
                  filling: Filling(horizontal: width, vertical: height))
    }
}

extension Layout.Alignment {
    /// Convenience method for apply alignment layout together with filling layout.
    ///
    /// - Parameters:
    ///   - filling: Filling layout
    ///   - item: Item for layout
    ///   - constraints: Required constraints
    public func apply<Item: LayoutItem>(with filling: Layout.Filling, for item: Item, use constraints: [ConstrainRect]) {
        filling.apply(for: item, use: constraints)
        apply(for: item, use: constraints)
    }
}

extension Layout.Filling {
    /// Convenience method for apply filling layout together with alignment layout.
    ///
    /// - Parameters:
    ///   - alignment: Alignment layout
    ///   - item: Item for layout
    ///   - constraints: Required constraints
    public func apply<Item: LayoutItem>(with alignment: Layout.Alignment, for item: Item, use constraints: [ConstrainRect]) {
        apply(for: item, use: constraints)
        alignment.apply(for: item, use: constraints)
    }
}


// MARK: Attempts, not used

// TODO: !!! `constraints` has not priority, because conflicted constraints will be replaced result previous constraints
// ANSWER: While this responsobility orientied on user.

/* Swift 4(.1)+
fileprivate protocol Absorbing {
    associatedtype Base
    var base: Base { get }
    init(base: Base)
}

extension Extended where Self: Absorbing, Self.Conformed == Self.Base {
    fileprivate func build(_ base: Conformed) -> Self {
        return .init(base: base)
    }
}*/

// Value wrapper for possibility use calculated values. Status: 'blocked'. Referred in:
// TODO: Add type wrapper for layout parameter for representation as literal or calculation. Or move behavior (like as .scaled, .boxed) to `ValueType`
protocol CGLayoutValue {
    associatedtype CGLayoutValue
    var cgLayoutValue: CGLayoutValue { get }
}
extension CGFloat: CGLayoutValue {
    var cgLayoutValue: CGFloat { return self }
}
struct AnyLayoutValue<Value>: CGLayoutValue {
    private let getter: () -> Value
    var cgLayoutValue: Value { return getter() }
}

// New anchors
// Target: Add possibility to connect two anchors into one constraint. Question: This is improvement?
typealias Setter<Anchor: LayoutAnchorGetter> = (_ anchor: Anchor, _ rect: CGRect, _ targetRect: inout CGRect) -> Void
protocol LayoutAnchorSetter {
    associatedtype AnchorMetric
    func set<Anchor: LayoutAnchorGetter>(anchor: Anchor, of rect: CGRect, to targetRect: inout CGRect) where Anchor.AnchorMetric == AnchorMetric
}

protocol LayoutAnchorGetter {
    associatedtype AnchorMetric
    func get(for rect: CGRect) -> AnchorMetric
}

protocol LayoutAnchorProtocol: LayoutAnchorSetter, LayoutAnchorGetter {}

struct AnyAnchorGetter<Metric>: LayoutAnchorGetter {
    typealias AnchorMetric = Metric
    let getter: (_ rect: CGRect) -> Metric

    init<Anchor: LayoutAnchorGetter>(_ base: Anchor) where Anchor.AnchorMetric == AnchorMetric {
        self.getter = base.get
    }

    func get(for rect: CGRect) -> Metric {
        return getter(rect)
    }
}

struct LeftAnchor: LayoutAnchorProtocol {
    typealias AnchorMetric = CGFloat

    private let setter: Setter<AnyAnchorGetter<AnchorMetric>>
    private init<Setter: LayoutAnchorSetter>(setter: Setter) where Setter.AnchorMetric == AnchorMetric { self.setter = setter.set }

    static var align: LeftAnchor { return LeftAnchor(setter: Align()) }
    struct Align: LayoutAnchorSetter {
        typealias AnchorMetric = CGFloat
        func set<Anchor>(anchor: Anchor, of rect: CGRect, to targetRect: inout CGRect) where Anchor : LayoutAnchorGetter, Anchor.AnchorMetric == Align.AnchorMetric {
            targetRect.origin.x = anchor.get(for: rect)
        }
    }
    static var alignOuter: LeftAnchor { return LeftAnchor(setter: AlignOuter()) }
    struct AlignOuter: LayoutAnchorSetter {
        typealias AnchorMetric = CGFloat
        func set<Anchor>(anchor: Anchor, of rect: CGRect, to targetRect: inout CGRect) where Anchor : LayoutAnchorGetter, Anchor.AnchorMetric == Align.AnchorMetric {
            targetRect.origin.x = anchor.get(for: rect) + targetRect.width
        }
    }

    func set<Anchor>(anchor: Anchor, of rect: CGRect, to targetRect: inout CGRect) where Anchor : LayoutAnchorGetter, Anchor.AnchorMetric == CGFloat {
        setter(AnyAnchorGetter(anchor), rect, &targetRect)
    }

    func get(for rect: CGRect) -> CGFloat {
        return rect.left
    }
}

struct RightAnchor: LayoutAnchorProtocol {
    typealias AnchorMetric = CGFloat
    func set<Anchor>(anchor: Anchor, of rect: CGRect, to targetRect: inout CGRect) where Anchor : LayoutAnchorGetter, Anchor.AnchorMetric == CGFloat {
        targetRect.origin.x = anchor.get(for: rect)
    }

    func get(for rect: CGRect) -> CGFloat {
        return rect.right
    }
}


/*
/// Using for constraint size ???
protocol SizeBasedConstraint: RectBasedConstraint {
    func constrain(sourceSize: inout CGSize)
}
extension SizeBasedConstraint {
    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
        constrain(sourceSize: &sourceRect.size)
    }
}

protocol CGRectAxis {
    func set(size: CGFloat, for rect: inout CGRect)
    func get(sizeAt rect: CGRect) -> CGFloat
    func set(origin: CGFloat, for rect: inout CGRect)
    func get(originAt rect: CGRect) -> CGFloat

    func get(maxOf rect: CGRect) -> CGFloat
    func get(minOf rect: CGRect) -> CGFloat
    //    func get(midOf rect: CGRect) -> CGFloat
}

extension CGRect {
    struct Horizontal: CGRectAxis {
        func set(size: CGFloat, for rect: inout CGRect) { rect.size.width = size }
        func set(origin: CGFloat, for rect: inout CGRect) { rect.origin.x = origin }
        func get(originAt rect: CGRect) -> CGFloat { return rect.origin.x }
        func get(sizeAt rect: CGRect) -> CGFloat { return rect.width }
        func get(maxOf rect: CGRect) -> CGFloat { return rect.maxX }
        func get(minOf rect: CGRect) -> CGFloat { return rect.minX }
    }
    struct Vertical: CGRectAxis {
        func set(size: CGFloat, for rect: inout CGRect) { rect.size.height = size }
        func set(origin: CGFloat, for rect: inout CGRect) { rect.origin.y = origin }
        func get(sizeAt rect: CGRect) -> CGFloat { return rect.height }
        func get(originAt rect: CGRect) -> CGFloat { return rect.origin.y }
        func get(maxOf rect: CGRect) -> CGFloat { return rect.maxY }
        func get(minOf rect: CGRect) -> CGFloat { return rect.minY }
    }
    struct WorkingSpace {
        struct After {
            func align(rect: inout CGRect, by position: CGFloat, in axis: CGRectAxis) {
                axis.set(origin: position, for: &rect)
            }
            func crop(rect: inout CGRect, by position: CGFloat, in axis: CGRectAxis) {
                axis.set(size: max(0, min(axis.get(sizeAt: rect), axis.get(sizeAt: rect) - (axis.get(maxOf: rect) - position))),
                         for: &rect)
                axis.set(origin: min(axis.get(originAt: rect), position), for: &rect)
            }
            func pull(rect: inout CGRect, to position: CGFloat, in axis: CGRectAxis) {
                axis.set(size: max(0, axis.get(maxOf: rect) - position), for: &rect)
                align(rect: &rect, by: position, in: axis)
            }
        }
        struct Before {
            func align(rect: inout CGRect, by position: CGFloat, in axis: CGRectAxis) {
                axis.set(origin: position - axis.get(sizeAt: rect), for: &rect)
            }
            func crop(rect: inout CGRect, by position: CGFloat, in axis: CGRectAxis) {
                axis.set(size: max(0, min(axis.get(sizeAt: rect), axis.get(sizeAt: rect) - (axis.get(maxOf: rect) - position))),
                         for: &rect)
                axis.set(origin: min(axis.get(originAt: rect), position), for: &rect)
            }
            func pull(rect: inout CGRect, to position: CGFloat, in axis: CGRectAxis) {
                axis.set(size: max(0, position - axis.get(minOf: rect)), for: &rect)
                align(rect: &rect, by: position, in: axis)
            }
        }
    }
}

extension CGRect {
    struct AnchorDependence {
        struct Inner {
            func align(rect: inout CGRect, by position: CGFloat, in axis: CGRectAxis) {
                axis.set(origin: position, to: &rect)
            }
        }
    }
}
*/
