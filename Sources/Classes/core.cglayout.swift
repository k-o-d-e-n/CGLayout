//
//  Layout.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 29/08/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

import Foundation

/// Defines method for wrapping entity with base behavior to this type.
public protocol Extensible {
    associatedtype Conformed
    /// Common method for create entity of this type with base behavior.
    ///
    /// - Parameter base: Entity implements required behavior
    /// - Returns: Initialized entity
    static func build(_ base: Conformed) -> Self
}

@available(*, deprecated, renamed: "Extensible")
typealias Extended = Extensible

// MARK: RectBasedLayout

public protocol RectBasedLayout {
    /// Performing layout of given rect inside available rect.
    /// Attention: Apply layout for view frame using code as layout(rect: &view.frame,...) has side effect and called setFrame method on view.
    ///
    /// - Parameters:
    ///   - rect: Rect for layout
    ///   - source: Available space for layout
    func formLayout(rect: inout CGRect, in source: CGRect)
}

/// Tuple of rect and constraint for constrain other rect
public typealias ConstrainRect = (rect: CGRect, constraints: [RectBasedConstraint])

public extension RectBasedLayout {
    /// Wrapper for main layout function. This is used for working with immutable values.
    ///
    /// - Parameters:
    ///   - rect: Rect for layout
    ///   - source: Available space for layout
    /// - Returns: Corrected rect
    func layout(rect: CGRect, in source: CGRect) -> CGRect {
        var rect = rect
        formLayout(rect: &rect, in: source)
        return rect
    }

    /// Used for layout `LayoutElement` entity in constrained bounds of parent element using constraints. Must call only on main thread.
    ///
    /// - Parameters:
    ///   - element: Element for layout
    ///   - constraints: Array of tuples with rect and constraint
    func apply(for item: LayoutElement, use constraints: [ConstrainRect] = []) {
        item.frame = layout(rect: item.frame, in: item.superElement!.layoutBounds, use: constraints)
    }
    /// Used for layout `LayoutElement` entity in constrained source space using constraints. Must call only on main thread.
    ///
    /// - Parameters:
    ///   - element: Element for layout
    ///   - source: Source space
    ///   - constraints: Array of tuples with rect and constraint
    func apply(for item: LayoutElement, in source: CGRect, use constraints: [ConstrainRect] = []) {
        item.frame = layout(rect: item.frame, in: source, use: constraints)
    }

    /// Calculates frame of `LayoutElement` entity in constrained source space using constraints.
    ///
    /// - Parameters:
    ///   - element: Element for layout
    ///   - constraints: Array of constraint elements
    /// - Returns: Array of tuples with rect and constraint
    func layout(rect: CGRect, in sourceRect: CGRect, use constraints: [ConstrainRect] = []) -> CGRect {
        return layout(rect: rect, in: constraints.reduce(into: sourceRect) { (result, constrained) in
            result = result.constrainedBy(rect: constrained.rect, use: constrained.constraints)
        })
    }

    /// Use for layout `LayoutElement` entity in constrained bounds of parent element using constraints. Must call only on main thread.
    ///
    /// - Parameters:
    ///   - element: Element for layout
    ///   - constraints: Array of constraint elements
    func apply(for item: LayoutElement, use constraints: [LayoutConstraintProtocol]) {
        debugFatalError(item.superElement == nil, "Layout item is not in hierarchy")
        apply(for: item, in: item.superElement!.layoutBounds, use: constraints)
    }
    /// Use for layout `LayoutElement` entity in constrained source space using constraints. Must call only on main thread.
    ///
    /// - Parameters:
    ///   - element: Element for layout
    ///   - sourceRect: Source space
    ///   - constraints: Array of constraint elements
    func apply(for item: LayoutElement, in sourceRect: CGRect, use constraints: [LayoutConstraintProtocol]) {
        debugFatalError(item.superElement == nil, "Layout element is not in hierarchy")
        item.frame = layout(rect: item.frame, from: item.superElement!, in: sourceRect, use: constraints)
    }

    /// Calculates frame of `LayoutElement` entity in constrained source space using constraints.
    ///
    /// - Parameters:
    ///   - rect: Rect for layout
    ///   - element: `LayoutElement` contained `rect`
    ///   - sourceRect: Space for layout
    ///   - constraints: Array of constraint elements
    /// - Returns: Corrected frame of layout element
    func layout(rect: CGRect, from item: LayoutElement, in sourceRect: CGRect, use constraints: [LayoutConstraintProtocol] = []) -> CGRect {
        return layout(rect: rect, in: constraints.reduce(into: sourceRect) { $1.constrain(sourceRect: &$0, in: item) })
    }
}

/// Closure based implementation RectBasedLayout
public struct AnyRectBasedLayout: RectBasedLayout {
    private let layout: (inout CGRect, CGRect) -> Void
    public init(_ layout: @escaping (inout CGRect, CGRect) -> Void) { self.layout = layout }
    public func formLayout(rect: inout CGRect, in source: CGRect) {
        layout(&rect, source)
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
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect)
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
        formConstrain(sourceRect: &sourceRect, by: rect)
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
        return constraints.reduce(into: self) { $1.formConstrain(sourceRect: &$0, by: rect) }
    }
    /// Convenience method for constrain
    ///
    /// - Parameters:
    ///   - rect: Rect for constrain
    ///   - constraint: Constraint
    /// - Returns: Constrained source rect
    func constrainedBy(rect: CGRect, use constraint: RectBasedConstraint) -> CGRect {
        return constraint.constrained(sourceRect: self, by: rect)
    }
}

/// Closure based implementation of RectBasedConstraint
public struct AnyRectBasedConstraint: RectBasedConstraint {
    let action: (inout CGRect, CGRect) -> Void

    public init(_ action: @escaping (inout CGRect, CGRect) -> Void) {
        self.action = action
    }

    public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        action(&sourceRect, rect)
    }
}

// MARK: LayoutElement

public protocol RectBasedElement {
    /// External representation of layout entity in coordinate space
    var frame: CGRect { get set }
    /// Internal coordinate space of layout entity
    var bounds: CGRect { get set }
}

/// Protocol for any layout element
public protocol LayoutElement: class, RectBasedElement, LayoutCoordinateSpace {
    /// External representation of layout entity in coordinate space
    var frame: CGRect { get set }
    /// Internal coordinate space of layout entity
    var bounds: CGRect { get set }
    /// Internal space for layout subelements
    var layoutBounds: CGRect { get }
    /// Layout element that maintains this layout entity
    var superElement: LayoutElement? { get }
    /// Entity that represents element in layout time
    var inLayoutTime: ElementInLayoutTime { get }
    /// Removes layout element from hierarchy
    func removeFromSuperElement()
}
extension Equatable where Self: LayoutElement {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs === rhs
    }
}

/// Defines requirements for thread confined wrapper of layout element
public protocol ElementInLayoutTime: RectBasedElement {
    /// Layout element that maintains this layout entity
    var superElement: LayoutElement? { get } // TODO: replace with coordinate space
    /// Internal space for layout subelements
    var layoutBounds: CGRect { get }
}

/// Protocol for text elements. Provides their specific parameters.
public protocol TextPresentedElement {
    associatedtype BaselineElement: LayoutElement
    /// Defines y-position from origin in internal coordinate space
    var baselineElement: BaselineElement { get }
}

extension LayoutElement {
    /// Convenience getter for constraint element related to this entity
    ///
    /// - Parameter anchors: Array of anchor constraints
    /// - Returns: Related constraint element
    public func layoutConstraint(for anchors: [LayoutAnchor]) -> LayoutConstraint {
        return LayoutConstraint(element: self, constraints: anchors.map { $0.constraint })
    }
    /// Convenience getter for layout block related to this entity
    ///
    /// - Parameters:
    ///   - layout: Main layout for this entity
    ///   - constraints: Array of related constraint elements
    /// - Returns: Related layout block
    public func layoutBlock(with layout: Layout = Layout.equal, constraints: [LayoutConstraintProtocol]) -> LayoutBlock<Self> {
        return LayoutBlock(element: self, layout: layout, constraints: constraints)
    }
    public func layoutBlock(with layout: Layout = Layout.equal) -> LayoutBlock<Self> {
        return layoutBlock(with: layout, constraints: [])
    }

    /// Convenience getter for constraint that uses internal bounds to constrain, defined in 'layoutBounds' property
    ///
    /// - Parameter anchors: Array of anchor constraints
    /// - Returns: Related constraint element
    public func contentLayoutConstraint(for anchors: [LayoutAnchor]) -> ContentLayoutConstraint {
        return ContentLayoutConstraint(element: self, constraints: anchors.map { $0.constraint })
    }

    #if DEBUG
    public func layoutConstraint(for anchors: [LayoutAnchor], debug: @escaping ((before: CGRect, after: CGRect), CGRect) -> Void) -> LayoutConstraint {
        return LayoutConstraint(element: self, constraints: anchors.map { anchor in
            let constraint = anchor.constraint
            return AnyRectBasedConstraint({ s, r in
                var source: (before: CGRect, after: CGRect) = (s, .zero)
                constraint.formConstrain(sourceRect: &s, by: r)
                source.after = s
                debug(source, r)
            })
        })
    }
    #endif
}
public extension LayoutElement where Self: TextPresentedElement {
    /// Convenience getter for constraint by baseline position
    ///
    /// - Parameter anchors: Array of anchor constraints
    /// - Returns: Related constraint element
    func baselineLayoutConstraint(for anchors: [LayoutAnchor]) -> LayoutConstraint {
        return LayoutConstraint(element: baselineElement, constraints: anchors.map { $0.constraint })
    }
}

// MARK: AdjustableLayoutElement

/// Element that may adapt to proposed size
public protocol AdaptiveLayoutElement: class {
    /// Asks the layout element to calculate and return the size that best fits the specified size
    ///
    /// - Parameter size: The size for which the view should calculate its best-fitting size
    /// - Returns: A new size that fits the receiver’s content
    func sizeThatFits(_ size: CGSize) -> CGSize
}

/// Protocol for elements that can calculate yourself content size
public protocol AdjustableLayoutElement: LayoutElement {
    /// Constraint, that defines content size of element
    var contentConstraint: RectBasedConstraint { get }
}
extension AdjustableLayoutElement where Self: AdaptiveLayoutElement {
    /// Constraint, that defines content size of element
    public var contentConstraint: RectBasedConstraint { return _SizeThatFitsConstraint(item: self) }
}
extension AdjustableLayoutElement {
    /// Convenience getter for adjust constraint related to this element
    ///
    /// - Parameter anchors: Array of anchor constraints
    /// - Returns: Related adjust constraint element
    public func adjustLayoutConstraint(for anchors: [Size]) -> AdjustLayoutConstraint {
        return AdjustLayoutConstraint(element: self, constraints: anchors)
    }

    #if DEBUG
    public func adjustLayoutConstraint(for anchors: [Size],
                                       debug: @escaping ((before: CGRect, after: CGRect), CGRect) -> Void) -> AdjustLayoutConstraint {
        return AdjustLayoutConstraint(element: self, constraints: anchors.map({ (anchor) -> Size in
            return Size.build(AnyRectBasedConstraint({ s, r in
                var source: (before: CGRect, after: CGRect) = (s, .zero)
                anchor.formConstrain(sourceRect: &s, by: r)
                source.after = s
                debug(source, r)
            }))
        }))
    }
    #endif
}

// MARK: API v.1

// MARK: LayoutAnchor

/// Provides set of anchor constraints
public enum LayoutAnchor {
    case center(Center)
    case leading(Leading)
    case trailing(Trailing)
    case left(Left)
    case right(Right)
    case top(Top)
    case bottom(Bottom)
    case size(Size)
    case insets(EdgeInsets)
    case equal(CGRect)
    case equally
    case custom(RectBasedConstraint)

    internal var constraint: RectBasedConstraint {
        switch self {
        case .center(let c): return c
        case .leading(let c): return c
        case .trailing(let c): return c
        case .left(let c): return c
        case .right(let c): return c
        case .top(let c): return c
        case .bottom(let c): return c
        case .size(let c): return c
        case .insets(let c): return Inset(c)
        case .equal(let c): return Constantly(value: c)
        case .equally: return Equal()
        case .custom(let c): return c
        }
    }
}
extension LayoutAnchor {
    /// Layout behavior, that makes passed rect equally to  rect
    internal struct Constantly: RectBasedConstraint {
        let value: CGRect
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
            sourceRect = value
        }
    }
}

/// Set of constraints related to center of restrictive rect
public struct Center: RectBasedConstraint, Extensible {
    public typealias Conformed = RectBasedConstraint
    private let base: RectBasedConstraint
    private init(base: RectBasedConstraint) { self.base = base }
    public /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }
    public /// Common method for create entity of this type with base behavior.
    ///
    /// - Parameter base: Entity implements required behavior
    /// - Returns: Initialized entity
    static func build(_ base: RectBasedConstraint) -> Center { return .init(base: base) }

    /// Returns alignment constraint by center
    ///
    /// - Parameter dependency: Anchor dependency for target rect
    /// - Returns: Alignment constraint typed by Center
    public static func align(by dependency: AlignDependence) -> Center { return Center(base: dependency) }
    public struct AlignDependence: RectBasedConstraint {
        private let base: RectBasedConstraint

        public /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
            base.formConstrain(sourceRect: &sourceRect, by: rect)
        }

        public static var center: AlignDependence {
            return AlignDependence(base: ConstraintsAggregator([LayoutWorkspace.Center.align(axis: CGRectAxis.vertical, anchor: CGRectAxisAnchor.center),
                                                                LayoutWorkspace.Center.align(axis: CGRectAxis.horizontal, anchor: CGRectAxisAnchor.center)]))
        }
        public static var origin: AlignDependence {
            return AlignDependence(base: ConstraintsAggregator([LayoutWorkspace.After.align(axis: CGRectAxis.horizontal, anchor: CGRectAxisAnchor.center),
                                                                LayoutWorkspace.After.align(axis: CGRectAxis.vertical, anchor: CGRectAxisAnchor.center)]))
        }
        /// ...
    }
}

/// Returns constraint, that applies UIEdgeInsets to source rect.
///
/// - Parameter value: UIEdgeInsets value
/// - Returns: Inset constraint
public struct Inset: RectBasedConstraint {
    let insets: EdgeInsets
    public init(_ insets: EdgeInsets) {
        self.insets = insets
    }
    /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        sourceRect.apply(edgeInsets: insets)
    }
}

/// Constraint, that makes source rect equally to passed rect
public struct Equal: RectBasedConstraint {
    public init() {}

    /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        sourceRect = rect
    }
}

public struct Leading: RectBasedConstraint, Extensible {
    public typealias Conformed = RectBasedConstraint
    private let base: RectBasedConstraint
    private init(base: RectBasedConstraint) { self.base = base }

    public /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }

    public /// Common method for create entity of this type with base behavior.
    ///
    /// - Parameter base: Entity implements required behavior
    /// - Returns: Initialized entity
    static func build(_ base: RectBasedConstraint) -> Leading { return .init(base: base) }

    /// Returns alignment constraint by leading
    ///
    /// - Parameter dependency: Space dependency for target rect
    /// - Returns: Alignment constraint typed by Leading
    public static func align(by dependency: Align.Dependence) -> Leading { return Leading(base: dependency) }
    public struct Align {
        public struct Dependence: RectBasedConstraint {
            private let base: RectBasedConstraint

            public /// Main function for constrain source space by other rect
            ///
            /// - Parameters:
            ///   - sourceRect: Source space
            ///   - rect: Rect for constrain
            func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }

            public static var inner: Dependence { return Dependence(base: Configuration.default.isRTLMode ? Right.AlignDependence.inner : Left.AlignDependence.inner) }
            public static var outer: Dependence { return Dependence(base: Configuration.default.isRTLMode ? Right.AlignDependence.outer : Left.AlignDependence.outer) }
        }
    }

    /// Returns constraint, that limits source rect by leading of passed rect. If source rect intersects leading of passed rect, source rect will be cropped, else will not changed.
    ///
    /// - Parameter dependency: Space dependency for target rect
    /// - Returns: Limit constraint typed by Leading
    public static func limit(on dependency: Limit.Dependence) -> Leading { return Leading(base: dependency) }
    public struct Limit {
        public struct Dependence: RectBasedConstraint {
            private let base: RectBasedConstraint

            public /// Main function for constrain source space by other rect
            ///
            /// - Parameters:
            ///   - sourceRect: Source space
            ///   - rect: Rect for constrain
            func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }

            public static var inner: Dependence { return Dependence(base: Configuration.default.isRTLMode ? Right.LimitDependence.inner : Left.LimitDependence.inner) }
            public static var outer: Dependence { return Dependence(base: Configuration.default.isRTLMode ? Right.LimitDependence.outer : Left.LimitDependence.outer) }
        }
    }

    /// Returns constraint, that pulls source rect to leading of passed rect. If source rect intersects leading of passed rect, source rect will be cropped, else will pulled with changing size.
    ///
    /// - Parameter dependency: Space dependency for target rect
    /// - Returns: Pull constraint typed by Leading
    public static func pull(from dependency: Pull.Dependence) -> Leading { return Leading(base: dependency) }
    public struct Pull {
        public struct Dependence: RectBasedConstraint {
            private let base: RectBasedConstraint

            public /// Main function for constrain source space by other rect
            ///
            /// - Parameters:
            ///   - sourceRect: Source space
            ///   - rect: Rect for constrain
            func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }

            public static var inner: Dependence { return Dependence(base: Configuration.default.isRTLMode ? Right.PullDependence.inner : Left.PullDependence.inner) }
            public static var outer: Dependence { return Dependence(base: Configuration.default.isRTLMode ? Right.PullDependence.outer : Left.PullDependence.outer) }
        }
    }
}

public struct Trailing: RectBasedConstraint, Extensible {
    public typealias Conformed = RectBasedConstraint
    private let base: RectBasedConstraint
    private init(base: RectBasedConstraint) { self.base = base }

    public /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }

    public /// Common method for create entity of this type with base behavior.
    ///
    /// - Parameter base: Entity implements required behavior
    /// - Returns: Initialized entity
    static func build(_ base: RectBasedConstraint) -> Trailing { return .init(base: base) }

    /// Returns alignment constraint by trailing
    ///
    /// - Parameter dependency: Space dependency for target rect
    /// - Returns: Alignment constraint typed by Trailing
    public static func align(by dependency: Align.Dependence) -> Trailing { return Trailing(base: dependency) }
    public struct Align {
        public struct Dependence: RectBasedConstraint {
            private let base: RectBasedConstraint

            public /// Main function for constrain source space by other rect
            ///
            /// - Parameters:
            ///   - sourceRect: Source space
            ///   - rect: Rect for constrain
            func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }

            public static var inner: Dependence { return Dependence(base: Configuration.default.isRTLMode ? Left.AlignDependence.inner : Right.AlignDependence.inner) }
            public static var outer: Dependence { return Dependence(base: Configuration.default.isRTLMode ? Left.AlignDependence.outer : Right.AlignDependence.outer) }
        }
    }

    /// Returns constraint, that limits source rect by trailing of passed rect. If source rect intersects trailing of passed rect, source rect will be cropped, else will not changed.
    ///
    /// - Parameter dependency: Space dependency for target rect
    /// - Returns: Limit constraint typed by Trailing
    public static func limit(on dependency: Limit.Dependence) -> Trailing { return Trailing(base: dependency) }
    public struct Limit {
        public struct Dependence: RectBasedConstraint {
            private let base: RectBasedConstraint

            public /// Main function for constrain source space by other rect
            ///
            /// - Parameters:
            ///   - sourceRect: Source space
            ///   - rect: Rect for constrain
            func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }

            public static var inner: Dependence { return Dependence(base: Configuration.default.isRTLMode ? Left.LimitDependence.inner : Right.LimitDependence.inner) }
            public static var outer: Dependence { return Dependence(base: Configuration.default.isRTLMode ? Left.LimitDependence.outer : Right.LimitDependence.outer) }
        }
    }

    /// Returns constraint, that pulls source rect to trailing of passed rect. If source rect intersects trailing of passed rect, source rect will be cropped, else will pulled with changing size.
    ///
    /// - Parameter dependency: Space dependency for target rect
    /// - Returns: Pull constraint typed by Trailing
    public static func pull(from dependency: Pull.Dependence) -> Trailing { return Trailing(base: dependency) }
    public struct Pull {
        public struct Dependence: RectBasedConstraint {
            private let base: RectBasedConstraint

            public /// Main function for constrain source space by other rect
            ///
            /// - Parameters:
            ///   - sourceRect: Source space
            ///   - rect: Rect for constrain
            func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }

            public static var inner: Dependence { return Dependence(base: Configuration.default.isRTLMode ? Left.PullDependence.inner : Right.PullDependence.inner) }
            public static var outer: Dependence { return Dependence(base: Configuration.default.isRTLMode ? Left.PullDependence.outer : Right.PullDependence.outer) }
        }
    }
}

/// Set of size-based constraints
public struct Size: RectBasedConstraint, Extensible {
    public typealias Conformed = RectBasedConstraint
    private let base: RectBasedConstraint
    private init(base: RectBasedConstraint) { self.base = base }

    public /// Common method for create entity of this type with base behavior.
    ///
    /// - Parameter base: Entity implements required behavior
    /// - Returns: Initialized entity
    static func build(_ base: RectBasedConstraint) -> Size { return .init(base: base) }

    public /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }

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
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
            sourceRect.size.height = rect.height * multiplier
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
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
            sourceRect.size.width = rect.width * multiplier
        }
    }
}

/// Set of constraints related to bottom of restrictive rect
public struct Bottom: RectBasedConstraint, Extensible {
    public typealias Conformed = RectBasedConstraint
    private let base: RectBasedConstraint
    private init(base: RectBasedConstraint) { self.base = base }

    public /// Common method for create entity of this type with base behavior.
    ///
    /// - Parameter base: Entity implements required behavior
    /// - Returns: Initialized entity
    static func build(_ base: RectBasedConstraint) -> Bottom { return .init(base: base) }

    public /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        base.formConstrain(sourceRect: &sourceRect, by: rect)
    }

    /// Returns alignment constraint by bottom
    ///
    /// - Parameter dependency: Space dependency for target rect
    /// - Returns: Alignment constraint typed by Bottom
    public static func align(by dependency: AlignDependence) -> Bottom { return Bottom(base: dependency) }
    public struct AlignDependence: RectBasedConstraint {
        private let base: RectBasedConstraint

        public /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
            base.formConstrain(sourceRect: &sourceRect, by: rect)
        }

        public static var inner: AlignDependence { return AlignDependence(base: LayoutWorkspace.Before.align(axis: CGRectAxis.vertical, anchor: CGRectAxisAnchor.trailing)) }
        public static var outer: AlignDependence { return AlignDependence(base: LayoutWorkspace.After.align(axis: CGRectAxis.vertical, anchor: CGRectAxisAnchor.trailing)) }
    }

    /// Returns constraint, that limits source rect by bottom of passed rect. If source rect intersects bottom of passed rect, source rect will be cropped, else will not changed.
    ///
    /// - Parameter dependency: Space dependency for target rect
    /// - Returns: Limit constraint typed by Bottom
    public static func limit(on dependency: LimitDependence) -> Bottom { return Bottom(base: dependency) }
    public struct LimitDependence: RectBasedConstraint {
        private let base: RectBasedConstraint

        public /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
            base.formConstrain(sourceRect: &sourceRect, by: rect)
        }

        public static var inner: LimitDependence { return .init(base: LayoutWorkspace.Before.limit(axis: CGRectAxis.vertical, anchor: CGRectAxisAnchor.trailing)) }
        public static var outer: LimitDependence { return .init(base: LayoutWorkspace.After.limit(axis: CGRectAxis.vertical, anchor: CGRectAxisAnchor.trailing)) }
    }

    /// Returns constraint, that pulls source rect to bottom of passed rect. If source rect intersects bottom of passed rect, source rect will be cropped, else will pulled with changing size.
    ///
    /// - Parameter dependency: Space dependency for target rect
    /// - Returns: Pull constraint typed by Bottom
    public static func pull(from dependency: PullDependence) -> Bottom { return Bottom(base: dependency) }
    public struct PullDependence: RectBasedConstraint {
        private let base: RectBasedConstraint

        public /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
            base.formConstrain(sourceRect: &sourceRect, by: rect)
        }

        public static var inner: PullDependence { return .init(base: LayoutWorkspace.Before.pull(axis: CGRectAxis.vertical, anchor: CGRectAxisAnchor.trailing)) }
        public static var outer: PullDependence { return .init(base: LayoutWorkspace.After.pull(axis: CGRectAxis.vertical, anchor: CGRectAxisAnchor.trailing)) }
    }
}

/// Set of constraints related to right of restrictive rect
public struct Right: RectBasedConstraint, Extensible {
    public typealias Conformed = RectBasedConstraint
    private let base: RectBasedConstraint
    private init(base: RectBasedConstraint) { self.base = base }

    public /// Common method for create entity of this type with base behavior.
    ///
    /// - Parameter base: Entity implements required behavior
    /// - Returns: Initialized entity
    static func build(_ base: RectBasedConstraint) -> Right { return .init(base: base) }

    public /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }

    /// Returns alignment constraint by right
    ///
    /// - Parameter dependency: Space dependency for target rect
    /// - Returns: Alignment constraint typed by Right
    public static func align(by dependency: AlignDependence) -> Right { return Right(base: dependency) }
    public struct AlignDependence: RectBasedConstraint {
        private let base: RectBasedConstraint

        public /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }

        public static var inner: AlignDependence { return .init(base: LayoutWorkspace.Before.align(axis: CGRectAxis.horizontal, anchor: CGRectAxisAnchor.trailing)) }
        public static var outer: AlignDependence { return .init(base: LayoutWorkspace.After.align(axis: CGRectAxis.horizontal, anchor: CGRectAxisAnchor.trailing)) }
    }

    /// Returns constraint, that limits source rect by right of passed rect. If source rect intersects right of passed rect, source rect will be cropped, else will not changed.
    ///
    /// - Parameter dependency: Space dependency for target rect
    /// - Returns: Limit constraint typed by Right
    public static func limit(on dependency: LimitDependence) -> Right { return Right(base: dependency) }
    public struct LimitDependence: RectBasedConstraint {
        private let base: RectBasedConstraint

        public /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }

        public static var inner: LimitDependence { return .init(base: LayoutWorkspace.Before.limit(axis: CGRectAxis.horizontal, anchor: CGRectAxisAnchor.trailing)) }
        public static var outer: LimitDependence { return .init(base: LayoutWorkspace.After.limit(axis: CGRectAxis.horizontal, anchor: CGRectAxisAnchor.trailing)) }
    }

    /// Returns constraint, that pulls source rect to right of passed rect. If source rect intersects right of passed rect, source rect will be cropped, else will pulled with changing size.
    ///
    /// - Parameter dependency: Space dependency for target rect
    /// - Returns: Pull constraint typed by Right
    public static func pull(from dependency: PullDependence) -> Right { return Right(base: dependency) }
    public struct PullDependence: RectBasedConstraint {
        private let base: RectBasedConstraint

        public /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }

        public static var inner: PullDependence { return .init(base: LayoutWorkspace.Before.pull(axis: CGRectAxis.horizontal, anchor: CGRectAxisAnchor.trailing)) }
        public static var outer: PullDependence { return .init(base: LayoutWorkspace.After.pull(axis: CGRectAxis.horizontal, anchor: CGRectAxisAnchor.trailing)) }
    }
}

/// Set of constraints related to left of restrictive rect
public struct Left: RectBasedConstraint, Extensible {
    public typealias Conformed = RectBasedConstraint
    private let base: RectBasedConstraint
    private init(base: RectBasedConstraint) { self.base = base }

    public /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }

    public /// Common method for create entity of this type with base behavior.
    ///
    /// - Parameter base: Entity implements required behavior
    /// - Returns: Initialized entity
    static func build(_ base: RectBasedConstraint) -> Left { return .init(base: base) }

    /// Returns alignment constraint by left
    ///
    /// - Parameter dependency: Space dependency for target rect
    /// - Returns: Alignment constraint typed by Left
    public static func align(by dependency: AlignDependence) -> Left { return Left(base: dependency) }
    public struct AlignDependence: RectBasedConstraint {
        private let base: RectBasedConstraint

        public /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }

        public static var inner: AlignDependence { return .init(base: LayoutWorkspace.After.align(axis: CGRectAxis.horizontal, anchor: CGRectAxisAnchor.leading)) }
        public static var outer: AlignDependence { return .init(base: LayoutWorkspace.Before.align(axis: CGRectAxis.horizontal, anchor: CGRectAxisAnchor.leading)) }
    }

    /// Returns constraint, that limits source rect by left of passed rect. If source rect intersects left of passed rect, source rect will be cropped, else will not changed.
    ///
    /// - Parameter dependency: Space dependency for target rect
    /// - Returns: Limit constraint typed by Left
    public static func limit(on dependency: LimitDependence) -> Left { return Left(base: dependency) }
    public struct LimitDependence: RectBasedConstraint {
        private let base: RectBasedConstraint

        public /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }

        public static var inner: LimitDependence { return .init(base: LayoutWorkspace.After.limit(axis: CGRectAxis.horizontal, anchor: CGRectAxisAnchor.leading)) }
        public static var outer: LimitDependence { return .init(base: LayoutWorkspace.Before.limit(axis: CGRectAxis.horizontal, anchor: CGRectAxisAnchor.leading)) }
    }

    /// Returns constraint, that pulls source rect to left of passed rect. If source rect intersects left of passed rect, source rect will be cropped, else will pulled with changing size.
    ///
    /// - Parameter dependency: Space dependency for target rect
    /// - Returns: Pull constraint typed by Left
    public static func pull(from dependency: PullDependence) -> Left { return Left(base: dependency) }
    public struct PullDependence: RectBasedConstraint {
        private let base: RectBasedConstraint

        public /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }

        public static var inner: PullDependence { return .init(base: LayoutWorkspace.After.pull(axis: CGRectAxis.horizontal, anchor: CGRectAxisAnchor.leading)) }
        public static var outer: PullDependence { return .init(base: LayoutWorkspace.Before.pull(axis: CGRectAxis.horizontal, anchor: CGRectAxisAnchor.leading)) }
    }
}

/// Set of constraints related to top of restrictive rect
public struct Top: RectBasedConstraint, Extensible {
    public typealias Conformed = RectBasedConstraint
    private let base: RectBasedConstraint
    private init(base: RectBasedConstraint) { self.base = base }

    public /// Common method for create entity of this type with base behavior.
    ///
    /// - Parameter base: Entity implements required behavior
    /// - Returns: Initialized entity
    static func build(_ base: RectBasedConstraint) -> Top { return .init(base: base) }

    public /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }

    /// Returns alignment constraint by top
    ///
    /// - Parameter dependency: Space dependency for target rect
    /// - Returns: Alignment constraint typed by Top
    public static func align(by dependency: AlignDependence) -> Top { return Top(base: dependency) }
    public struct AlignDependence: RectBasedConstraint {
        private let base: RectBasedConstraint

        public /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
            base.formConstrain(sourceRect: &sourceRect, by: rect)
        }

        public static var inner: AlignDependence { return .init(base: LayoutWorkspace.After.align(axis: CGRectAxis.vertical, anchor: CGRectAxisAnchor.leading)) }
        public static var outer: AlignDependence { return .init(base: LayoutWorkspace.Before.align(axis: CGRectAxis.vertical, anchor: CGRectAxisAnchor.leading)) }
    }

    /// Returns constraint, that limits source rect by top of passed rect. If source rect intersects top of passed rect, source rect will be cropped, else will not changed.
    ///
    /// - Parameter dependency: Space dependency for target rect
    /// - Returns: Limit constraint typed by Top
    public static func limit(on dependency: LimitDependence) -> Top { return Top(base: dependency) }
    public struct LimitDependence: RectBasedConstraint {
        private let base: RectBasedConstraint
        public /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
            base.formConstrain(sourceRect: &sourceRect, by: rect)
        }

        public static var inner: LimitDependence { return .init(base: LayoutWorkspace.After.limit(axis: CGRectAxis.vertical, anchor: CGRectAxisAnchor.leading)) }
        public static var outer: LimitDependence { return .init(base: LayoutWorkspace.Before.limit(axis: CGRectAxis.vertical, anchor: CGRectAxisAnchor.leading)) }
    }

    /// Returns constraint, that pulls source rect to top of passed rect. If source rect intersects top of passed rect, source rect will be cropped, else will pulled with changing size.
    ///
    /// - Parameter dependency: Space dependency for target rect
    /// - Returns: Pull constraint typed by Top
    public static func pull(from dependency: PullDependence) -> Top { return Top(base: dependency) }
    public struct PullDependence: RectBasedConstraint {
        private let base: RectBasedConstraint
        public /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
            base.formConstrain(sourceRect: &sourceRect, by: rect)
        }

        public static var inner: PullDependence { return .init(base: LayoutWorkspace.After.pull(axis: CGRectAxis.vertical, anchor: CGRectAxisAnchor.leading)) }
        public static var outer: PullDependence { return .init(base: LayoutWorkspace.Before.pull(axis: CGRectAxis.vertical, anchor: CGRectAxisAnchor.leading)) }
    }
}

// MARK: Layout

/// Main layout structure. Use his for positioning and filling in source rect (which can be constrained using `RectBasedConstraint` constraints).
public struct Layout: RectBasedLayout, Extensible {
    let layouts: [RectBasedLayout]

    /// Designed public initializer
    ///
    /// - Parameters:
    ///   - alignment: Alignment layout behavior
    ///   - filling: Filling layout behavior
    public init(alignment: Alignment, filling: Filling) {
        self.init(layouts: [filling, alignment])
    }

    /// Designed initializer
    init(layouts: [RectBasedLayout]) {
        self.layouts = layouts
    }

    public static func build(_ base: RectBasedLayout) -> Layout {
        return Layout(layouts: [base])
    }

    public /// Performing layout of given rect inside available rect.
    /// Attention: Apply layout for view frame using code as layout(rect: &view.frame,...) has side effect and called setFrame method on view.
    ///
    /// - Parameters:
    ///   - rect: Rect for layout
    ///   - source: Available space for layout
    func formLayout(rect: inout CGRect, in source: CGRect) {
        layouts.forEach({ $0.formLayout(rect: &rect, in: source) })
    }

    /// Alignment part of main layout.
    public struct Alignment: RectBasedLayout {
        fileprivate let horizontal: Horizontal
        fileprivate let vertical: Vertical

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
        func formLayout(rect: inout CGRect, in source: CGRect) {
            vertical.formLayout(rect: &rect, in: source)
            horizontal.formLayout(rect: &rect, in: source)
        }

        public static var equal: Alignment { return Alignment(horizontal: .equal, vertical: .equal) }

        internal static func trailing(by axis: RectAxis, offset: CGFloat = 0) -> RectAxisLayout { return AxisTrailing(offset: offset, axis: axis) }
        struct AxisTrailing: RectAxisLayout {
            let offset: CGFloat
            let axis: RectAxis
            func formLayout(rect: inout CGRect, in source: CGRect) {
                axis.set(origin: axis.get(maxOf: source) - axis.get(sizeAt: rect) - offset, for: &rect)
            }

            func by(axis: RectAxis) -> AxisTrailing { return AxisTrailing(offset: offset, axis: axis) }
        }
        internal static func leading(by axis: RectAxis, offset: CGFloat = 0) -> RectAxisLayout { return AxisLeading(offset: offset, axis: axis) }
        struct AxisLeading: RectAxisLayout {
            let offset: CGFloat
            let axis: RectAxis
            func formLayout(rect: inout CGRect, in source: CGRect) {
                axis.set(origin: axis.get(minOf: source) + offset, for: &rect)
            }

            func by(axis: RectAxis) -> AxisLeading { return AxisLeading(offset: offset, axis: axis) }
        }
        internal static func center(by axis: RectAxis, offset: CGFloat = 0) -> RectAxisLayout { return AxisCenter(offset: offset, axis: axis) }
        struct AxisCenter: RectAxisLayout {
            let offset: CGFloat
            let axis: RectAxis
            func formLayout(rect: inout CGRect, in source: CGRect) {
                axis.set(origin: axis.get(midOf: source) - (axis.get(sizeAt: rect) / 2) + offset, for: &rect)
            }

            func by(axis: RectAxis) -> AxisCenter { return AxisCenter(offset: offset, axis: axis) }
        }

        public struct Horizontal: RectBasedLayout, Extensible {
            public typealias Conformed = RectBasedLayout
            fileprivate let base: RectBasedLayout
            private init(base: RectBasedLayout) { self.base = base }

            public /// Performing layout of given rect inside available rect.
            /// Attention: Apply layout for view frame using code as layout(rect: &view.frame,...) has side effect and called setFrame method on view.
            ///
            /// - Parameters:
            ///   - rect: Rect for layout
            ///   - source: Available space for layout
            func formLayout(rect: inout CGRect, in source: CGRect) { base.formLayout(rect: &rect, in: source) }

            public /// Common method for create entity of this type with base behavior.
            ///
            /// - Parameter base: Entity implements required behavior
            /// - Returns: Initialized entity
            static func build(_ base: RectBasedLayout) -> Layout.Alignment.Horizontal { return .init(base: base) }

            public static var equal: Horizontal { return Horizontal(base: Equal()) }
            fileprivate struct Equal: RectBasedLayout {
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.x = source.origin.x
                }
            }

            /// Horizontal alignment by center of source rect
            ///
            /// - Parameter offset: Offset value. Positive value gives offset to right.
            /// - Returns: Center alignment typed by Horizontal
            public static func center(_ offset: CGFloat = 0) -> Horizontal { return Horizontal(base: Center(offset: offset)) }
            fileprivate struct Center: RectBasedLayout {
                let offset: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.x = source.midX - (rect.width / 2) + offset
                }
            }
            /// Horizontal alignment by left of source rect
            ///
            /// - Parameter offset: Offset value. Positive value gives offset to right.
            /// - Returns: Left alignment typed by Horizontal
            public static func left(_ offset: CGFloat = 0) -> Horizontal { return Horizontal(base: Left(offset: offset)) }
            fileprivate struct Left: RectBasedLayout {
                let offset: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.x = source.origin.x + offset
                }
            }
            /// Provides rect with left alignment with spacing that depends on position calculated using multiplier
            ///
            /// - Parameter multiplier: Multiplier value.
            /// - Returns: Left aligment typed with 'Vertical'
            public static func left(multiplier: CGFloat) -> Horizontal { return Horizontal(base: LeftOffsetMultiplier(multiplier: multiplier)) }
            fileprivate struct LeftOffsetMultiplier: RectBasedLayout {
                let multiplier: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.x = source.minX + (source.width * multiplier)
                }
            }
            /// Horizontal alignment by right of source rect
            ///
            /// - Parameter offset: Offset value. Positive value gives offset to left.
            /// - Returns: Right alignment typed by Horizontal
            public static func right(_ offset: CGFloat = 0) -> Horizontal { return Horizontal(base: Right(offset: offset)) }
            fileprivate struct Right: RectBasedLayout {
                let offset: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.x = source.maxX - rect.width - offset
                }
            }
            /// Provides rect with right alignment with spacing that depends on position calculated using multiplier
            ///
            /// - Parameter multiplier: Multiplier value.
            /// - Returns: Right aligment typed with 'Horizontal'
            public static func right(multiplier: CGFloat) -> Horizontal { return Horizontal(base: RightOffsetMultiplier(multiplier: multiplier)) }
            fileprivate struct RightOffsetMultiplier: RectBasedLayout {
                let multiplier: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.x = source.maxX - rect.width - (source.width * multiplier)
                }
            }
            /// See description: `left(between space: ClosedRange<CGFloat>)`
            public static func left(between space: Range<CGFloat>) -> Horizontal { return Horizontal(base: LeftSpace(space: space.lowerBound...space.upperBound+1)) }
            /// Provides rect with left alignment and space between defined range depending on available space.
            ///
            /// - Parameter space: Range valid space values
            /// - Returns: Between behavior typed with 'Vertical'
            public static func left(between space: ClosedRange<CGFloat>) -> Horizontal { return Horizontal(base: LeftSpace(space: space)) }
            fileprivate struct LeftSpace: RectBasedLayout {
                let space: ClosedRange<CGFloat>
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.x = source.minX + max(space.lowerBound, min(space.upperBound, source.width - rect.width))
                }
            }
            /// See description: `right(between space: ClosedRange<CGFloat>)`
            public static func right(between space: Range<CGFloat>) -> Horizontal { return Horizontal(base: RightSpace(space: space.lowerBound...space.upperBound+1)) }
            /// Provides rect with right alignment and space between defined range depending on available space.
            ///
            /// - Parameter space: Range valid space values
            /// - Returns: Between behavior typed with 'Horizontal'
            public static func right(between space: ClosedRange<CGFloat>) -> Horizontal { return Horizontal(base: RightSpace(space: space)) }
            fileprivate struct RightSpace: RectBasedLayout {
                let space: ClosedRange<CGFloat>
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.x = source.maxX - rect.width - max(space.lowerBound, min(space.upperBound, source.width - rect.width))
                }
            }

            public static func trailing(_ offset: CGFloat = 0) -> Horizontal { return Horizontal(base: Configuration.default.isRTLMode ? Left(offset: offset) : Right(offset: offset)) }
            public static func leading(_ offset: CGFloat = 0) -> Horizontal { return Horizontal(base: Configuration.default.isRTLMode ? Right(offset: offset) : Left(offset: offset)) }
        }
        public struct Vertical: RectBasedLayout, Extensible {
            public typealias Conformed = RectBasedLayout
            fileprivate let base: RectBasedLayout
            private init(base: RectBasedLayout) { self.base = base }

            public /// Performing layout of given rect inside available rect.
            /// Attention: Apply layout for view frame using code as layout(rect: &view.frame,...) has side effect and called setFrame method on view.
            ///
            /// - Parameters:
            ///   - rect: Rect for layout
            ///   - source: Available space for layout
            func formLayout(rect: inout CGRect, in source: CGRect) { return base.formLayout(rect: &rect, in: source) }

            public /// Common method for create entity of this type with base behavior.
            ///
            /// - Parameter base: Entity implements required behavior
            /// - Returns: Initialized entity
            static func build(_ base: RectBasedLayout) -> Layout.Alignment.Vertical { return .init(base: base) }

            public static var equal: Vertical { return Vertical(base: Equal()) }
            fileprivate struct Equal: RectBasedLayout {
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.y = source.origin.y
                }
            }

            /// Vertical alignment by center of source rect
            ///
            /// - Parameter offset: Offset value. Positive value gives offset to bottom.
            /// - Returns: Center alignment typed by 'Vertical'
            public static func center(_ offset: CGFloat = 0) -> Vertical { return Vertical(base: Center(offset: offset)) }
            fileprivate struct Center: RectBasedLayout {
                let offset: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.y = source.midY - (rect.height / 2) + offset
                }
            }
            /// Vertical alignment by top of source rect
            ///
            /// - Parameter offset: Offset value. Positive value gives offset to bottom.
            /// - Returns: Top alignment typed by 'Vertical'
            public static func top(_ offset: CGFloat = 0) -> Vertical { return Vertical(base: Top(offset: offset)) }
            fileprivate struct Top: RectBasedLayout {
                let offset: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.y = source.origin.y + offset
                }
            }
            /// Provides rect with top alignment with spacing that depends on position calculated using multiplier
            ///
            /// - Parameter multiplier: Multiplier value.
            /// - Returns: Top aligment typed with 'Vertical'
            public static func top(multiplier: CGFloat) -> Vertical { return Vertical(base: TopOffsetMultiplier(multiplier: multiplier)) }
            fileprivate struct TopOffsetMultiplier: RectBasedLayout {
                let multiplier: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.y = source.minY + (source.height * multiplier)
                }
            }
            /// Vertical alignment by bottom of source rect
            ///
            /// - Parameter offset: Offset value. Positive value gives offset to top.
            /// - Returns: Bottom alignment typed by 'Vertical'
            public static func bottom(_ offset: CGFloat = 0) -> Vertical { return Vertical(base: Bottom(offset: offset)) }
            fileprivate struct Bottom: RectBasedLayout {
                let offset: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.y = source.maxY - rect.height - offset
                }
            }
            /// Provides rect with bottom alignment with spacing that depends on position calculated using multiplier
            ///
            /// - Parameter multiplier: Multiplier value.
            /// - Returns: Bottom aligment typed with 'Vertical'
            public static func bottom(multiplier: CGFloat) -> Vertical { return Vertical(base: BottomOffsetMultiplier(multiplier: multiplier)) }
            fileprivate struct BottomOffsetMultiplier: RectBasedLayout {
                let multiplier: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.y = source.maxY - rect.height - (source.height * multiplier)
                }
            }

            /// See description: `top(between space: ClosedRange<CGFloat>)`
            public static func top(between space: Range<CGFloat>) -> Vertical { return Vertical(base: TopSpace(space: space.lowerBound...space.upperBound+1)) }
            /// Provides rect with bottom alignment and space between defined range depending on available space.
            ///
            /// - Parameter space: Range valid space values
            /// - Returns: Between behavior typed with 'Vertical'
            public static func top(between space: ClosedRange<CGFloat>) -> Vertical { return Vertical(base: TopSpace(space: space)) }
            fileprivate struct TopSpace: RectBasedLayout {
                let space: ClosedRange<CGFloat>
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.y = source.minY + max(space.lowerBound, min(space.upperBound, source.height - rect.height))
                }
            }
            public static func top(between space: Range<CGFloat>, step: CGFloat = 0.1) -> Vertical { return Vertical(base: TopSpaceWithStep(space: space.lowerBound...space.upperBound+1, step: step)) }
            public static func top(between space: ClosedRange<CGFloat>, step: CGFloat = 0.1) -> Vertical { return Vertical(base: TopSpaceWithStep(space: space, step: step)) }
            fileprivate struct TopSpaceWithStep: RectBasedLayout {
                let space: ClosedRange<CGFloat>
                let step: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    let offset = max(space.lowerBound, min(space.upperBound, source.height - rect.height))
                    rect.origin.y = source.minY + (offset >= space.upperBound ? offset : offset - offset.truncatingRemainder(dividingBy: step))
                }
            }

            /// See description: `bottom(between space: ClosedRange<CGFloat>)`
            public static func bottom(between space: Range<CGFloat>) -> Vertical { return Vertical(base: BottomSpace(space: space.lowerBound...space.upperBound+1)) }
            /// Provides rect with bottom alignment and space between defined range depending on available space.
            ///
            /// - Parameter space: Range valid space values
            /// - Returns: Between behavior typed with 'Vertical'
            public static func bottom(between space: ClosedRange<CGFloat>) -> Vertical { return Vertical(base: BottomSpace(space: space)) }
            fileprivate struct BottomSpace: RectBasedLayout {
                let space: ClosedRange<CGFloat>
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.y = source.maxY - rect.height - max(space.lowerBound, min(space.upperBound, source.height - rect.height))
                }
            }
        }
    }

    /// Filling part of main layout
    public struct Filling: RectBasedLayout {
        let horizontal: Horizontal
        let vertical: Vertical

        public /// Performing layout of given rect inside available rect.
        /// Attention: Apply layout for view frame using code as layout(rect: &view.frame,...) has side effect and called setFrame method on view.
        ///
        /// - Parameters:
        ///   - rect: Rect for layout
        ///   - source: Available space for layout
        func formLayout(rect: inout CGRect, in source: CGRect) {
            vertical.formLayout(rect: &rect, in: source)
            horizontal.formLayout(rect: &rect, in: source)
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

        public static var equal: Filling { return Filling(horizontal: .equal, vertical: .equal) }

        public struct Horizontal: RectBasedLayout, Extensible {
            public typealias Conformed = RectBasedLayout
            fileprivate let base: RectBasedLayout
            fileprivate init(base: RectBasedLayout) { self.base = base }

            public /// Performing layout of given rect inside available rect.
            /// Attention: Apply layout for view frame using code as layout(rect: &view.frame,...) has side effect and called setFrame method on view.
            ///
            /// - Parameters:
            ///   - rect: Rect for layout
            ///   - source: Available space for layout
            func formLayout(rect: inout CGRect, in source: CGRect) { return base.formLayout(rect: &rect, in: source) }

            public /// Common method for create entity of this type with base behavior.
            ///
            /// - Parameter base: Entity implements required behavior
            /// - Returns: Initialized entity
            static func build(_ base: RectBasedLayout) -> Layout.Filling.Horizontal { return .init(base: base) }

            public static var equal: Horizontal { return Horizontal(base: Equal()) }
            fileprivate struct Equal: RectBasedLayout {
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.size.width = source.width
                }
            }
            /// Provides rect with width less or equal defined size depending on available space.
            ///
            /// - Parameter size: Width limiter value.
            /// - Returns: UpTo behavior typed with 'Horizontal'
            public static func upTo(_ size: CGFloat) -> Horizontal { return Horizontal(base: UpTo(size: size)) }
            fileprivate struct UpTo: RectBasedLayout {
                let size: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.size.width = min(size, source.width)
                }
            }
            /// Provides rect with width value more or equal defined size depending on available space.
            ///
            /// - Parameter size: Width limiter value
            /// - Returns: From behavior typed with 'Horizontal'
            public static func from(_ size: CGFloat) -> Horizontal { return Horizontal(base: From(size: size)) }
            fileprivate struct From: RectBasedLayout {
                let size: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.size.width = max(size, source.width)
                }
            }

            /// Provides rect with independed horizontal filling with fixed value
            ///
            /// - Parameter value: Value of width
            /// - Returns: Fixed behavior typed by 'Horizontal'
            public static func fixed(_ value: CGFloat) -> Horizontal { return Horizontal(base: Fixed(value: value)) }
            fileprivate struct Fixed: RectBasedLayout {
                let value: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.size.width = value
                }
            }

            /// Provides rect with width value scaled from width of source rect
            ///
            /// - Parameter scale: Scale value.
            /// - Returns: Scaled behavior typed by 'Horizontal'
            public static func scaled(_ scale: CGFloat) -> Horizontal { return Horizontal(base: Scaled(scale: scale)) }
            fileprivate struct Scaled: RectBasedLayout {
                let scale: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.size.width = source.width * scale
                }
            }

            /// Provides rect, that width is smaller or larger than the source rect, with the same center point.
            ///
            /// - Parameter insets: Value to use for adjusting the source rectangle
            /// - Returns: Boxed behavior typed by 'Horizontal'
            public static func boxed(_ insets: CGFloat) -> Horizontal { return Horizontal(base: Boxed(insets: insets)) }
            fileprivate struct Boxed: RectBasedLayout {
                let insets: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.size.width = max(0, source.width - insets)
                }
            }

            /// See description: `between(_ space: ClosedRange<CGFloat>)`
            public static func between(_ space: Range<CGFloat>) -> Horizontal { return Horizontal(base: Between(space: space.lowerBound...space.upperBound+1)) }
            /// Provides rect with width value between defined range depending on available space.
            ///
            /// - Parameter space: Range valid width values
            /// - Returns: Between behavior typed with 'Horizontal'
            public static func between(_ space: ClosedRange<CGFloat>) -> Horizontal { return Horizontal(base: Between(space: space)) }
            fileprivate struct Between: RectBasedLayout {
                let space: ClosedRange<CGFloat>
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.size.width = max(space.lowerBound, min(space.upperBound, source.width))
                }
            }
        }
        public struct Vertical: RectBasedLayout, Extensible {
            public typealias Conformed = RectBasedLayout
            fileprivate let base: RectBasedLayout
            fileprivate init(base: RectBasedLayout) { self.base = base }

            public /// Performing layout of given rect inside available rect.
            /// Attention: Apply layout for view frame using code as layout(rect: &view.frame,...) has side effect and called setFrame method on view.
            ///
            /// - Parameters:
            ///   - rect: Rect for layout
            ///   - source: Available space for layout
            func formLayout(rect: inout CGRect, in source: CGRect) { return base.formLayout(rect: &rect, in: source) }

            public /// Common method for create entity of this type with base behavior.
            ///
            /// - Parameter base: Entity implements required behavior
            /// - Returns: Initialized entity
            static func build(_ base: RectBasedLayout) -> Layout.Filling.Vertical { return .init(base: base) }

            public static var equal: Vertical { return Vertical(base: Equal()) }
            fileprivate struct Equal: RectBasedLayout {
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.size.height = source.height
                }
            }
            /// Provides rect with height less or equal defined size depending on available space.
            ///
            /// - Parameter size: Height limiter value.
            /// - Returns: UpTo behavior typed with 'Vertical'
            public static func upTo(_ size: CGFloat) -> Vertical { return Vertical(base: UpTo(size: size)) }
            fileprivate struct UpTo: RectBasedLayout {
                let size: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.size.height = min(size, source.height)
                }
            }
            /// Provides rect with height value more or equal defined size depending on available space.
            ///
            /// - Parameter size: Height limiter value
            /// - Returns: From behavior typed with 'Vertical'
            public static func from(_ size: CGFloat) -> Vertical { return Vertical(base: From(size: size)) }
            fileprivate struct From: RectBasedLayout {
                let size: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.size.height = max(size, source.height)
                }
            }

            /// Provides rect with independed vertical filling with fixed value
            ///
            /// - Parameter value: Value of height
            /// - Returns: Fixed behavior typed by 'Vertical'
            public static func fixed(_ value: CGFloat) -> Vertical { return Vertical(base: Fixed(value: value)) }
            fileprivate struct Fixed: RectBasedLayout {
                let value: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.size.height = value
                }
            }

            /// Provides rect with height value scaled from height of source rect
            ///
            /// - Parameter scale: Scale value.
            /// - Returns: Scaled behavior typed by 'Vertical'
            public static func scaled(_ scale: CGFloat) -> Vertical { return Vertical(base: Scaled(scale: scale)) }
            fileprivate struct Scaled: RectBasedLayout {
                let scale: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.size.height = source.height * scale
                }
            }

            /// Provides rect, that height is smaller or larger than the source rect, with the same center point.
            ///
            /// - Parameter insets: Value to use for adjusting the source rectangle
            /// - Returns: Boxed behavior typed by 'Vertical'
            public static func boxed(_ insets: CGFloat) -> Vertical { return Vertical(base: Boxed(insets: insets)) }
            fileprivate struct Boxed: RectBasedLayout {
                let insets: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.size.height = max(0, source.height - insets)
                }
            }

            /// See description: `between(_ space: ClosedRange<CGFloat>)`
            public static func between(_ space: Range<CGFloat>) -> Vertical { return Vertical(base: Between(space: space.lowerBound...space.upperBound+1)) }
            /// Provides rect with height value between defined range depending on available space.
            ///
            /// - Parameter space: Range valid height values
            /// - Returns: Between behavior typed with 'Vertical'
            public static func between(_ space: ClosedRange<CGFloat>) -> Vertical { return Vertical(base: Between(space: space)) }
            fileprivate struct Between: RectBasedLayout {
                let space: ClosedRange<CGFloat>
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.size.height = max(space.lowerBound, min(space.upperBound, source.height))
                }
            }
        }
    }
}

public extension Layout {
    /// Layout behavior, that makes passed rect equally to space rect
    static var equal: Layout { return Layout.build(Equal()) }
    private struct Equal: RectBasedLayout {
        func formLayout(rect: inout CGRect, in source: CGRect) {
            rect = source
        }
    }

    /// Layout behavior, that makes passed rect equally to  rect
    static func equal(_ value: CGRect) -> Layout { return Layout.build(Constantly(value: value)) }
    private struct Constantly: RectBasedLayout {
        let value: CGRect
        func formLayout(rect: inout CGRect, in source: CGRect) {
            rect = value
        }
    }

    /// This layout do nothing.
    /// Use this if you create compound layout and you need begin with old frame
    static var nothing: Layout { return Layout.build(Nothing()) }
    private struct Nothing: RectBasedLayout {
        func formLayout(rect: inout CGRect, in source: CGRect) {}
    }
}

public extension Layout {
    /// Convinience initializer similar CGRect initializer.
    ///
    /// - Parameters:
    ///   - x: Horizontal alignment behavior
    ///   - y: Vertical alignment behavior
    ///   - width: Width filling behavior
    ///   - height: Height filling behavior
    init(x: Alignment.Horizontal, y: Alignment.Vertical, width: Filling.Horizontal, height: Filling.Vertical) {
        self.init(layouts: [
            width, height,
            x, y
        ])
    }

    func with(height: Filling.Vertical) -> Layout {
        return Layout(layouts: [height] + layouts)
    }
    func with(width: Filling.Horizontal) -> Layout {
        return Layout(layouts: [width] + layouts)
    }
    func with(y: Alignment.Vertical) -> Layout {
        return Layout(layouts: layouts + [y])
    }
    func with(x: Alignment.Horizontal) -> Layout {
        return Layout(layouts: layouts + [x])
    }
}

extension Layout.Filling.Vertical: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    public init(floatLiteral value: Float) {
        self.base = Fixed(value: CGFloat(value))
    }
    public init(integerLiteral value: Int) {
        self.base = Fixed(value: CGFloat(value))
    }
}
extension Layout.Filling.Horizontal: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    public init(floatLiteral value: Float) {
        self.base = Fixed(value: CGFloat(value))
    }
    public init(integerLiteral value: Int) {
        self.base = Fixed(value: CGFloat(value))
    }
}
extension Layout.Alignment.Vertical: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    public init(floatLiteral value: Float) {
        self.base = Top(offset: CGFloat(value))
    }
    public init(integerLiteral value: Int) {
        self.base = Top(offset: CGFloat(value))
    }
}
extension Layout.Alignment.Horizontal: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    public init(floatLiteral value: Float) {
        self.base = Left(offset: CGFloat(value))
    }
    public init(integerLiteral value: Int) {
        self.base = Left(offset: CGFloat(value))
    }
}

public extension Layout.Alignment.Horizontal {
    static func +(lhs: Layout.Alignment.Horizontal, rhs: Layout.Alignment.Horizontal) -> Layout.Alignment.Horizontal {
        return Layout.Alignment.Horizontal.build(AnyRectBasedLayout({ (rect, source) in
            lhs.formLayout(rect: &rect, in: source)
            rhs.formLayout(rect: &rect, in: source)
        }))
    }
}
public extension Layout.Alignment.Vertical {
    static func +(lhs: Layout.Alignment.Vertical, rhs: Layout.Alignment.Vertical) -> Layout.Alignment.Vertical {
        return Layout.Alignment.Vertical.build(AnyRectBasedLayout({ (rect, source) in
            lhs.formLayout(rect: &rect, in: source)
            rhs.formLayout(rect: &rect, in: source)
        }))
    }
}
public extension Layout.Filling.Horizontal {
    static func +(lhs: Layout.Filling.Horizontal, rhs: Layout.Filling.Horizontal) -> Layout.Filling.Horizontal {
        return Layout.Filling.Horizontal.build(AnyRectBasedLayout({ (rect, source) in
            lhs.formLayout(rect: &rect, in: source)
            rhs.formLayout(rect: &rect, in: source)
        }))
    }
}
public extension Layout.Filling.Vertical {
    static func +(lhs: Layout.Filling.Vertical, rhs: Layout.Filling.Vertical) -> Layout.Filling.Vertical {
        return Layout.Filling.Vertical.build(AnyRectBasedLayout({ (rect, source) in
            lhs.formLayout(rect: &rect, in: source)
            rhs.formLayout(rect: &rect, in: source)
        }))
    }
}

#if DEBUG
struct Debug: RectBasedLayout, RectBasedConstraint {
    let base: (RectBasedLayout?, RectBasedConstraint?)
    let before: (CGRect, CGRect) -> Void
    let after: (CGRect) -> Void
    func formLayout(rect: inout CGRect, in source: CGRect) {
        before(rect, source)
        base.0?.formLayout(rect: &rect, in: source)
        after(rect)
    }
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        before(sourceRect, rect)
        base.1?.formConstrain(sourceRect: &sourceRect, by: rect)
        after(sourceRect)
    }
}
public extension RectBasedLayout where Self: Extensible, Self.Conformed == RectBasedLayout {
    func debug(before: @escaping (CGRect, CGRect) -> Void, after: @escaping (CGRect) -> Void) -> Self {
        return Self.build(Debug(base: (self, nil), before: before, after: after))
    }
}
public extension RectBasedConstraint where Self: Extensible, Self.Conformed == RectBasedConstraint {
    func debug(before: @escaping (CGRect, CGRect) -> Void, after: @escaping (CGRect) -> Void) -> Self {
        return Self.build(Debug(base: (nil, self), before: before, after: after))
    }
}
#endif

extension Layout {
    /// beta
    static func from<PointAnchor: RectAnchorPoint, SizeAnchor: SizeRectAnchor>(
        _ anchor: PointAnchor, size: SizeAnchor, operator op: @escaping (CGFloat, CGFloat) -> CGFloat, space: PartialRangeFrom<CGFloat>
    ) -> Layout where PointAnchor.Metric == CGFloat, SizeAnchor.Metric == CGFloat {
        return .build(AnyRectBasedLayout({ (rect, source) in
            anchor.move(in: &rect, to: op(anchor.get(for: source), max(space.lowerBound, size.get(for: source) - size.get(for: rect))))
        }))
    }

    public static func left(_ space: PartialRangeFrom<CGFloat>) -> Layout {
        return Layout.from(LeftAnchor(), size: WidthAnchor.width, operator: +, space: space)
    }
    public static func right(_ space: PartialRangeFrom<CGFloat>) -> Layout {
        return Layout.from(RightAnchor(), size: WidthAnchor.width, operator: -, space: space)
    }
    public static func bottom(_ space: PartialRangeFrom<CGFloat>) -> Layout {
        return Layout.from(BottomAnchor(), size: HeightAnchor.height, operator: -, space: space)
    }
    public static func top(_ space: PartialRangeFrom<CGFloat>) -> Layout {
        return Layout.from(TopAnchor(), size: HeightAnchor.height, operator: +, space: space)
    }
}

public extension Layout {
    static func +(lhs: Layout, rhs: Layout) -> Layout {
        return Layout(layouts: lhs.layouts + rhs.layouts)
    }
}
