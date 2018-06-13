//
//  Layout.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 29/08/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#elseif os(Linux)
import Foundation
#endif

// TODO: !! Comment all code
// TODO: ! Add RTL (right to left language)
// TODO: ! Add support UITraitCollection
// TODO: !! Optimization for macOS API
// TODO: !!! Resolve problem with create offset for adjusted views.
// TODO: ! Add CGRect.integral
// TODO: !! Add implementation description variables if needed
// TODO: ! Move reduce to inout with swift 4

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
    func formLayout(rect: inout CGRect, in source: CGRect)
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
        formLayout(rect: &rect, in: source)
        return rect
    }

    /// Used for layout `LayoutItem` entity in constrained bounds of parent item using constraints. Must call only on main thread.
    ///
    /// - Parameters:
    ///   - item: Item for layout
    ///   - constraints: Array of tuples with rect and constraint
    public func apply(for item: LayoutItem, use constraints: [ConstrainRect] = []) {
        item.frame = layout(rect: item.frame, in: item.superItem!.layoutBounds, use: constraints)
    }
    /// Used for layout `LayoutItem` entity in constrained source space using constraints. Must call only on main thread.
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

    /// Use for layout `LayoutItem` entity in constrained bounds of parent item using constraints. Must call only on main thread.
    ///
    /// - Parameters:
    ///   - item: Item for layout
    ///   - constraints: Array of constraint items
    public func apply(for item: LayoutItem, use constraints: [LayoutConstraintProtocol]) {
        // TODO: ! Add flag for using layout margins. IMPL: Apply 'inset' constraint from LayotAnchor to super bounds.
        debugFatalError(item.superItem == nil, "Layout item is not in hierarchy")
        apply(for: item, in: item.superItem!.layoutBounds, use: constraints)
    }
    /// Use for layout `LayoutItem` entity in constrained source space using constraints. Must call only on main thread.
    ///
    /// - Parameters:
    ///   - item: Item for layout
    ///   - sourceRect: Source space
    ///   - constraints: Array of constraint items
    public func apply(for item: LayoutItem, in sourceRect: CGRect, use constraints: [LayoutConstraintProtocol]) {
        debugFatalError(item.superItem == nil, "Layout item is not in hierarchy")
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
        return constraints.reduce(self) { $1.constrained(sourceRect: $0, by: rect) }
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

// MARK: LayoutItem

public protocol RectBasedItem {
    /// External representation of layout entity in coordinate space
    var frame: CGRect { get set }
    /// Internal coordinate space of layout entity
    var bounds: CGRect { get set }
}

/// Protocol for any layout element
public protocol LayoutItem: class, RectBasedItem, LayoutCoordinateSpace {
    /// External representation of layout entity in coordinate space
    var frame: CGRect { get set }
    /// Internal coordinate space of layout entity
    var bounds: CGRect { get set }
    /// Internal space for layout subitems
    var layoutBounds: CGRect { get }
    /// Layout item that maintains this layout entity
    var superItem: LayoutItem? { get }
    /// Entity that represents item in layout time
    var inLayoutTime: InLayoutTimeItem { get }
    /// Removes layout item from hierarchy
    func removeFromSuperItem()
}

public protocol InLayoutTimeItem: RectBasedItem {
    /// Layout item that maintains this layout entity
    var superItem: LayoutItem? { get }
    /// Internal layout space of super item
    var superLayoutBounds: CGRect { get }
    /// Internal space for layout subitems
    var layoutBounds: CGRect { get }
}

public protocol TextPresentedItem {
    // Defines y-position from origin in internal coordinate space
    var baselinePosition: CGFloat { get }
}

extension LayoutItem {
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
    public func layoutBlock(with layout: RectBasedLayout = Layout.equal, constraints: [LayoutConstraintProtocol] = []) -> LayoutBlock<Self> {
        return LayoutBlock(item: self, layout: layout, constraints: constraints)
    }

    func contentLayoutConstraint(for anchors: [RectBasedConstraint]) -> ContentLayoutConstraint {
        return ContentLayoutConstraint(item: self, constraints: anchors)
    }
}
public extension LayoutItem where Self: TextPresentedItem {
    func baselineLayoutConstraint(for anchors: [RectBasedConstraint]) -> BaselineLayoutConstraint {
        return BaselineLayoutConstraint(item: self, constraints: anchors)
    }
}

// MARK: AdjustableLayoutItem

public protocol SelfSizedLayoutItem: class {
    /// Asks the layout item to calculate and return the size that best fits the specified size
    ///
    /// - Parameter size: The size for which the view should calculate its best-fitting size
    /// - Returns: A new size that fits the receiver’s content
    func sizeThatFits(_ size: CGSize) -> CGSize
}

/// Protocol for items that can calculate yourself fitted size
public protocol AdjustableLayoutItem: LayoutItem {
    /// Constraint, that defines content size for item
    var contentConstraint: RectBasedConstraint { get }
}
extension AdjustableLayoutItem where Self: SelfSizedLayoutItem {
    /// Constraint, that defines content size for item
    public var contentConstraint: RectBasedConstraint { return _SizeThatFitsConstraint(item: self) }
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

// MARK: LayoutAnchor

// TODO: ! Add center, baseline and other behaviors
// TODO: !! Hide types that not used directly
// TODO: RectBasedConstraint should have possible be wrapped by transformations (min, max, ...) 

/// Provides set of anchor constraints
public struct LayoutAnchor {
    /// Set of constraints related to base line of restrictive rect
    public struct Baseline: RectBasedConstraint, Extended {
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
        static func build(_ base: RectBasedConstraint) -> LayoutAnchor.Baseline { return .init(base: base) }

        /// Returns alignment constraint by baseline
        ///
        /// - Parameter dependency: Anchor dependency for target rect
        /// - Returns: Alignment constraint typed by Baseline
        public static func align(of textPresenter: TextPresentedItem & LayoutItem) -> Baseline { return Baseline(base: Align(textPresenter: textPresenter)) }
        public struct Align: RectBasedConstraint {
            fileprivate unowned var textPresenter: TextPresentedItem & LayoutItem

            public /// Main function for constrain source space by other rect
            ///
            /// - Parameters:
            ///   - sourceRect: Source space
            ///   - rect: Rect for constrain
            func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
                sourceRect.origin.y = rect.maxY - textPresenter.baselinePosition
            }
        }
    }

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
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }
        public /// Common method for create entity of this type with base behavior.
        ///
        /// - Parameter base: Entity implements required behavior
        /// - Returns: Initialized entity
        static func build(_ base: RectBasedConstraint) -> LayoutAnchor.Center { return .init(base: base) }

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
    public static func insets(_ value: EdgeInsets) -> RectBasedConstraint { return Inset(insets: value) }
    private struct Inset: RectBasedConstraint {
        let insets: EdgeInsets
        /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
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
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
            sourceRect = rect
        }
    }

    /// Constraint, that makes source rect equally to passed rect
    public static var zero: RectBasedConstraint { return Equal() }
    private struct Fixed: RectBasedConstraint {
        /// Main function for constrain source space by other rect
        ///
        /// - Parameters:
        ///   - sourceRect: Source space
        ///   - rect: Rect for constrain
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
            sourceRect = .zero
        }
    }

    public struct Leading: RectBasedConstraint, Extended {
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
        static func build(_ base: RectBasedConstraint) -> LayoutAnchor.Leading { return .init(base: base) }

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

    public struct Trailing: RectBasedConstraint, Extended {
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
        static func build(_ base: RectBasedConstraint) -> LayoutAnchor.Trailing { return .init(base: base) }

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

        // TODO: May be need use Limit as returned type to have strong type.
        /// Returns constraint, that limits source rect by bottom of passed rect. If source rect intersects bottom of passed rect, source rect will be cropped, else will not changed.
        ///
        /// - Parameter dependency: Space dependency for target rect
        /// - Returns: Limit constraint typed by Bottom
        public static func limit(on dependency: LimitDependence) -> Bottom { return Bottom(base: dependency) }
        public struct LimitDependence: RectBasedConstraint {// TODO: May be need implement inner/outer behaviors inside Limit space.
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
    public struct Left: RectBasedConstraint, Extended {
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
        static func build(_ base: RectBasedConstraint) -> LayoutAnchor.Left { return .init(base: base) }

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
    func formLayout(rect: inout CGRect, in source: CGRect) {
        filling.formLayout(rect: &rect, in: source)
        alignment.formLayout(rect: &rect, in: source)
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
            func formLayout(rect: inout CGRect, in source: CGRect) { base.formLayout(rect: &rect, in: source) }

            public /// Common method for create entity of this type with base behavior.
            ///
            /// - Parameter base: Entity implements required behavior
            /// - Returns: Initialized entity
            static func build(_ base: RectBasedLayout) -> Layout.Alignment.Horizontal { return .init(base: base) }

            public static var equal: Horizontal { return Horizontal(base: Equal()) }
            private struct Equal: RectBasedLayout {
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.x = source.origin.x
                }
            }

            /// Horizontal alignment by center of source rect
            ///
            /// - Parameter offset: Offset value. Positive value gives offset to right.
            /// - Returns: Center alignment typed by Horizontal
            public static func center(_ offset: CGFloat = 0) -> Horizontal { return Horizontal(base: Center(offset: offset)) }
            private struct Center: RectBasedLayout {
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
            private struct Left: RectBasedLayout {
                let offset: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
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
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.x = source.maxX - rect.width - offset
                }
            }

            public static func trailing(_ offset: CGFloat = 0) -> Horizontal { return Horizontal(base: Configuration.default.isRTLMode ? Left(offset: offset) : Right(offset: offset)) }
            public static func leading(_ offset: CGFloat = 0) -> Horizontal { return Horizontal(base: Configuration.default.isRTLMode ? Right(offset: offset) : Left(offset: offset)) }
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
            func formLayout(rect: inout CGRect, in source: CGRect) { return base.formLayout(rect: &rect, in: source) }

            public /// Common method for create entity of this type with base behavior.
            ///
            /// - Parameter base: Entity implements required behavior
            /// - Returns: Initialized entity
            static func build(_ base: RectBasedLayout) -> Layout.Alignment.Vertical { return .init(base: base) }

            public static var equal: Vertical { return Vertical(base: Equal()) }
            private struct Equal: RectBasedLayout {
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.y = source.origin.y
                }
            }

            /// Vertical alignment by center of source rect
            ///
            /// - Parameter offset: Offset value. Positive value gives offset to bottom.
            /// - Returns: Center alignment typed by 'Vertical'
            public static func center(_ offset: CGFloat = 0) -> Vertical { return Vertical(base: Center(offset: offset)) }
            private struct Center: RectBasedLayout {
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
            private struct Top: RectBasedLayout {
                let offset: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
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
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.y = source.maxY - rect.height - offset
                }
            }
        }
    }

    // TODO: ! Add ratio behavior
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
            func formLayout(rect: inout CGRect, in source: CGRect) { return base.formLayout(rect: &rect, in: source) }

            public /// Common method for create entity of this type with base behavior.
            ///
            /// - Parameter base: Entity implements required behavior
            /// - Returns: Initialized entity
            static func build(_ base: RectBasedLayout) -> Layout.Filling.Horizontal { return .init(base: base) }

            public static var equal: Horizontal { return Horizontal(base: Equal()) }
            private struct Equal: RectBasedLayout {
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.size.width = source.width
                }
            }

            /// Provides rect with independed horizontal filling with fixed value
            ///
            /// - Parameter value: Value of width
            /// - Returns: Fixed behavior typed by 'Horizontal'
            public static func fixed(_ value: CGFloat) -> Horizontal { return Horizontal(base: Fixed(value: value)) }
            private struct Fixed: RectBasedLayout {
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
            private struct Scaled: RectBasedLayout {
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
            private struct Boxed: RectBasedLayout {
                let insets: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.size.width = max(0, source.width - insets)
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
            func formLayout(rect: inout CGRect, in source: CGRect) { return base.formLayout(rect: &rect, in: source) }

            public /// Common method for create entity of this type with base behavior.
            ///
            /// - Parameter base: Entity implements required behavior
            /// - Returns: Initialized entity
            static func build(_ base: RectBasedLayout) -> Layout.Filling.Vertical { return .init(base: base) }

            public static var equal: Vertical { return Vertical(base: Equal()) }
            private struct Equal: RectBasedLayout {
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.size.height = source.height
                }
            }

            /// Provides rect with independed vertical filling with fixed value
            ///
            /// - Parameter value: Value of height
            /// - Returns: Fixed behavior typed by 'Vertical'
            public static func fixed(_ value: CGFloat) -> Vertical { return Vertical(base: Fixed(value: value)) }
            private struct Fixed: RectBasedLayout {
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
            private struct Scaled: RectBasedLayout {
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
            private struct Boxed: RectBasedLayout {
                let insets: CGFloat
                func formLayout(rect: inout CGRect, in source: CGRect) {
                    rect.size.height = max(0, source.height - insets)
                }
            }
        }
    }
}

public struct Configuration {
    let isRTLMode: Bool = false // TODO: RTL in UIKit and AppKit oriented on view.

    static private(set) var `default` = Configuration()

    static func setDefault(configuration: Configuration) {
        Configuration.default = configuration
    }
}

public extension Layout {
    /// Layout behavior, that makes passed rect equally to space rect
    public static var equal: RectBasedLayout { return Equal() }
    private struct Equal: RectBasedLayout {
        func formLayout(rect: inout CGRect, in source: CGRect) {
            rect = source
        }
    }

    /// Layout behavior, that makes passed rect equally to  rect
    public static func equal(_ value: CGRect) -> RectBasedLayout { return Constantly(value: value) }
    private struct Constantly: RectBasedLayout {
        let value: CGRect
        func formLayout(rect: inout CGRect, in source: CGRect) {
            rect = value
        }
    }
}

extension LayoutAnchor {
    /// Layout behavior, that makes passed rect equally to  rect
    public static func equal(_ value: CGRect) -> RectBasedConstraint { return Constantly(value: value) }
    private struct Constantly: RectBasedConstraint {
        let value: CGRect
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
            sourceRect = value
        }
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

public struct AnyRectBasedLayout: RectBasedLayout {
    private let layout: (inout CGRect, CGRect) -> Void
    public init(_ layout: @escaping (inout CGRect, CGRect) -> Void) { self.layout = layout }
    public func formLayout(rect: inout CGRect, in source: CGRect) {
        layout(&rect, source)
    }
}

public extension Layout.Filling.Vertical {
    static func calculated(_ use: @escaping (CGRect) -> CGFloat) -> Layout.Filling.Vertical {
        return build(AnyRectBasedLayout { $0.size.height = use($1) })
    }
}
public extension Layout.Filling.Horizontal {
    static func calculated(_ use: @escaping (CGRect) -> CGFloat) -> Layout.Filling.Horizontal {
        return build(AnyRectBasedLayout { $0.size.width = use($1) })
    }
}
public extension Layout.Alignment.Vertical {
    static func calculated(_ use: @escaping (CGRect) -> CGFloat) -> Layout.Alignment.Vertical {
        return build(AnyRectBasedLayout { $0.origin.y = use($1) })
    }
}
public extension Layout.Alignment.Horizontal {
    static func calculated(_ use: @escaping (CGRect) -> CGFloat) -> Layout.Alignment.Horizontal {
        return build(AnyRectBasedLayout { $0.origin.x = use($1) })
    }
}
