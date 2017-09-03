//
//  Layout.swift
//  FirstAppObjC
//
//  Created by Denis Koryttsev on 29/08/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

import UIKit

// TODO: Comment all code
// TODO: Add behaviors with UIView size that fits and others
// TODO: Add auto resized behaviors in Filling set. // SizeBasedConstraint
// TODO: Think how can be use OptionSet type.
// TODO: Create interface for calculate layout without set result to LayoutItem, which will be return rect (size) of full scheme. Useful for dynamic UITableViewCell.
// TODO: Add RTL (right to left language)
// TODO: Fix on remove view from hierarchy

public protocol LayoutItem: class { // TODO: should be avoid limit only on class types
    var frame: CGRect { get set }
    var bounds: CGRect { get set }
    var superItem: LayoutItem? { get }
}
extension UIView: AdjustableLayoutItem {
    public var superItem: LayoutItem? { return superview }
}
extension CALayer: LayoutItem {
    public var superItem: LayoutItem? { return superlayer }
}

public protocol AdjustableLayoutItem: LayoutItem {
    func sizeThatFits(_ size: CGSize) -> CGSize
}
extension AdjustableLayoutItem {
    public func adjustedConstraintItem(for anchors: [LayoutAnchor.Size]) -> AdjustedConstraintItem {
        return AdjustedConstraintItem(item: self, constraints: anchors)
    }
}

// TODO: Try use LayoutItem as not rendered "layout view", which only make layout for subItems(?). Example as UIStackView
// TODO: Add extension to LayoutItem with anchor getters
extension LayoutItem {
    public func frameConstraint(for anchor: RectBasedConstraint) -> ConstrainRect {
        return (frame, anchor)
    }
    public func boundsConstraint(for anchor: RectBasedConstraint) -> ConstrainRect {
        return (bounds, anchor)
    }
    public func constraintItem(for anchors: [RectBasedConstraint]) -> ConstraintItem {
        return ConstraintItem(item: self, constraints: anchors)
    }
    public func layoutBlock(with layout: Layout, constraints: [ConstraintItemProtocol] = []) -> LayoutBlock {
        return LayoutBlock(item: self, layout: layout, constraints: constraints)
    }
}

public struct StringLayoutConstraint: ConstraintItemProtocol {
    let string: String?
    let attributes: [String: Any]?
    let context: NSStringDrawingContext?

    public init(string: String?, attributes: [String: Any]? = nil, context: NSStringDrawingContext? = nil) {
        self.string = string
        self.attributes = attributes
        self.context = context
    }

    public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
        sourceRect.size = string?.boundingRect(with: rect.size, options: .usesLineFragmentOrigin, attributes: attributes, context: context).size ?? .zero
    }

    public func constrainRect(current: CGRect) -> CGRect {
        return current
    }
}
extension String {
    func layoutConstraint(with attributes: [String: Any]? = nil, context: NSStringDrawingContext? = nil) -> StringLayoutConstraint {
        return StringLayoutConstraint(string: self, attributes: attributes, context: context)
    }
}

public protocol ConstraintItemProtocol: RectBasedConstraint {
    // TODO: Think normal it or not
    func constrainRect(current: CGRect) -> CGRect
}

public struct ConstraintItem {
    let constraints: [RectBasedConstraint]
    weak var item: LayoutItem!

    public init(item: LayoutItem, constraints: [RectBasedConstraint]) {
        self.item = item
        self.constraints = constraints
    }
}
extension ConstraintItem: ConstraintItemProtocol {
    public func constrainRect(current: CGRect) -> CGRect {
        return item.frame
    }
    public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
        sourceRect = constraints.reduce(sourceRect) { $1.constrained(sourceRect: $0, by: rect) }
    }
}

public struct AdjustedConstraintItem {
    let constraints: [LayoutAnchor.Size]
    weak var item: AdjustableLayoutItem!

    public init(item: AdjustableLayoutItem, constraints: [LayoutAnchor.Size]) {
        self.item = item
        self.constraints = constraints
    }
}
extension AdjustedConstraintItem: ConstraintItemProtocol {
    public func constrainRect(current: CGRect) -> CGRect {
        return CGRect(origin: current.origin, size: item.sizeThatFits(current.size))
    }
    public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
        sourceRect = constraints.reduce(sourceRect) { $1.constrained(sourceRect: $0, by: rect) }
    }
}

public struct LayoutBlock {
    let itemLayout: RectBasedLayout
    let constraints: [ConstraintItemProtocol]
    weak var item: LayoutItem!

    public init(item: LayoutItem, layout: RectBasedLayout, constraints: [ConstraintItemProtocol] = []) {
        self.item = item
        self.itemLayout = layout
        self.constraints = constraints
    }

    public func layout() {
        itemLayout.apply(for: item, use: constraints)
    }
}

// TODO: Add LayoutGuide as in SDK. It is constraint represented as simple rect with constraints (like ConstraintItem). Should implement LayoutItem protocol.
// TODO: Add support UITraitCollection to LayoutScheme
// TODO: Layout scheme - main layout entity for make up. Contain full layout process
public struct LayoutScheme {
    let blocks: [LayoutBlock]

    public init(blocks: [LayoutBlock]) {
        self.blocks = blocks
    }

    public func layout() {
        blocks.forEach { $0.layout() }
    }
}

public protocol RectBasedLayout {
    /// Performing layout of given rect inside available rect
    /// Warning: Apply layout for view frame (as layout(rect: &view.frame,...)) has side effect and called setFrame method on view.
    ///
    /// - Parameters:
    ///   - rect: Rect for layout
    ///   - source: Available space for layout
    func layout(rect: inout CGRect, in source: CGRect)
}

public typealias ConstrainRect = (rect: CGRect, constraint: RectBasedConstraint)
public extension RectBasedLayout {
    func layout(rect: CGRect, in source: CGRect) -> CGRect {
        var rect = rect
        layout(rect: &rect, in: source)
        return rect
    }

    // TODO: `constraints` has not priority, because conflicted constraints will be replaced result previous constraints
    func apply(for item: LayoutItem, use constraints: [ConstrainRect] = []) {
        let source = constraints.reduce(item.superItem!.bounds) { (result, constrained) -> CGRect in
            return result.constrainedBy(rect: constrained.rect, use: constrained.constraint)
        }
        item.frame = layout(rect: item.frame, in: source)
    }

    func apply(for item: LayoutItem, use constraints: [ConstraintItemProtocol] = []) {
        let source = constraints.reduce(item.superItem!.bounds) { (result, constraint) -> CGRect in
            return result.constrainedBy(rect: constraint.constrainRect(current: result), use: constraint)
        }
        item.frame = layout(rect: item.frame, in: source)
    }
}

public protocol RectBasedConstraint {
    func constrain(sourceRect: inout CGRect, by rect: CGRect)
}

/// Using for constraint size ???
public protocol SizeBasedConstraint: RectBasedConstraint {
    func constrain(sourceSize: inout CGSize)
}
extension SizeBasedConstraint {
    public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
        constrain(sourceSize: &sourceRect.size)
    }
}

extension RectBasedConstraint {
    public func constrained(sourceRect: CGRect, by rect: CGRect) -> CGRect {
        var sourceRect = sourceRect
        constrain(sourceRect: &sourceRect, by: rect)
        return sourceRect
    }
}

extension CGRect {
    var left: CGFloat { return minX }
    var right: CGFloat { return maxX }
    var top: CGFloat { return minY }
    var bottom: CGFloat { return maxY }
}

extension UIEdgeInsets {
    var horizontal: CGFloat { return left + right }
    var vertical: CGFloat { return top + bottom }

    public struct Vertical {
        var top: CGFloat
        var bottom: CGFloat
        var full: CGFloat { return top + bottom }

        public init(top: CGFloat, bottom: CGFloat) {
            self.top = top
            self.bottom = bottom
        }
    }
    public struct Horizontal {
        var left: CGFloat
        var right: CGFloat
        var full: CGFloat { return left + right }

        public init(left: CGFloat, right: CGFloat) {
            self.left = left
            self.right = right
        }
    }
    public init(vertical: Vertical, horizontal: Horizontal) {
        self.init(top: vertical.top, left: horizontal.left, bottom: vertical.bottom, right: horizontal.right)
    }
}

extension CGRect {
    func constrainedBy(rect: CGRect, use constraints: RectBasedConstraint...) -> CGRect {
        return constraints.reduce(self) { $1.constrained(sourceRect: $0, by: rect) }
    }
}

// TODO: Add center, baseline and other behaviors
// TODO: Hide types that not used directly
public struct LayoutAnchor {
    public struct Center: RectBasedConstraint {
        private let base: RectBasedConstraint
        private init(base: RectBasedConstraint) { self.base = base }

        public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
            base.constrain(sourceRect: &sourceRect, by: rect)
        }

        public static func align(by dependency: Align.Dependence) -> Center { return Center(base: dependency) }
        public struct Align {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint
                public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                    base.constrain(sourceRect: &sourceRect, by: rect)
                }
                public static var origin: Dependence { return Dependence(base: Origin()) }
                public struct Origin: RectBasedConstraint {
                    public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        sourceRect.origin.x = rect.midX
                        sourceRect.origin.y = rect.midY
                    }
                }
                public static var center: Dependence { return Dependence(base: Center()) }
                public struct Center: RectBasedConstraint {
                    private let alignment = Layout.Alignment(vertical: .center(), horizontal: .center())
                    public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        alignment.layout(rect: &sourceRect, in: rect)
//                        sourceRect.origin.x = rect.midX - (sourceRect.)
//                        sourceRect.origin.y = rect.midY
                    }
                }
            }
        }
    }

    public struct Size: RectBasedConstraint {
        private let base: RectBasedConstraint
        private init(base: RectBasedConstraint) { self.base = base }

        public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
            base.constrain(sourceRect: &sourceRect, by: rect)
        }

        public static func height(_ multiplier: CGFloat = 1) -> Size { return Size(base: Height(multiplier: multiplier)) }
        private struct Height: RectBasedConstraint {
            let multiplier: CGFloat
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                sourceRect.size.height = rect.height.multiplied(by: multiplier)
            }
        }
        public static func width(_ multiplier: CGFloat = 1) -> Size { return Size(base: Width(multiplier: multiplier)) }
        private struct Width: RectBasedConstraint {
            let multiplier: CGFloat
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                sourceRect.size.width = rect.width.multiplied(by: multiplier)
            }
        }
    }

    public struct Bottom: RectBasedConstraint {
        private let base: RectBasedConstraint
        private init(base: RectBasedConstraint) { self.base = base }

        public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
            base.constrain(sourceRect: &sourceRect, by: rect)
        }

        public static func align(by dependency: Align.Dependence) -> Bottom { return Bottom(base: dependency) }
        public struct Align {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint
                public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                    base.constrain(sourceRect: &sourceRect, by: rect)
                }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Bottom.alignInside(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }

                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Bottom.align(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
            }
        }

        // TODO: May be need use Limit as returned type to have strong type.
        // TODO: May be need rename to Crop.
        public static func limit(on dependency: Limit.Dependence) -> Bottom { return Bottom(base: dependency) }
        public struct Limit {
            public struct Dependence: RectBasedConstraint { // TODO: May be need implement inner/outer behaviors inside Limit space.
                private let base: RectBasedConstraint
                public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                    base.constrain(sourceRect: &sourceRect, by: rect)
                }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Bottom.cropInside(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Bottom.crop(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
            }
        }
        public static func pull(from dependency: Pull.Dependence) -> Bottom { return Bottom(base: dependency) }
        public struct Pull {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint
                public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                    base.constrain(sourceRect: &sourceRect, by: rect)
                }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Bottom.pullInside(sourceRect: &sourceRect, toConstrained: rect)
                    }
                }
                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
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

    public struct Right: RectBasedConstraint {
        private let base: RectBasedConstraint
        private init(base: RectBasedConstraint) { self.base = base }

        public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
            base.constrain(sourceRect: &sourceRect, by: rect)
        }

        public static func align(by dependency: Align.Dependence) -> Right { return Right(base: dependency) }
        public struct Align {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint
                public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                    base.constrain(sourceRect: &sourceRect, by: rect)
                }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Right.alignInside(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }

                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Right.align(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
            }
        }

        public static func limit(on dependency: Limit.Dependence) -> Right { return Right(base: dependency) }
        public struct Limit {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint
                public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                    base.constrain(sourceRect: &sourceRect, by: rect)
                }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Right.cropInside(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Right.crop(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
            }
        }
        public static func pull(from dependency: Pull.Dependence) -> Right { return Right(base: dependency) }
        public struct Pull {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint
                public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                    base.constrain(sourceRect: &sourceRect, by: rect)
                }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Right.pullInside(sourceRect: &sourceRect, toConstrained: rect)
                    }
                }
                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
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

    public struct Left: RectBasedConstraint {
        private let base: RectBasedConstraint
        private init(base: RectBasedConstraint) { self.base = base }

        public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
            base.constrain(sourceRect: &sourceRect, by: rect)
        }

        public static func align(by dependency: Align.Dependence) -> Left { return Left(base: dependency) }
        public struct Align {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint
                public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                    base.constrain(sourceRect: &sourceRect, by: rect)
                }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Left.alignInside(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }

                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Left.align(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
            }
        }

        public static func limit(on dependency: Limit.Dependence) -> Left { return Left(base: dependency) }
        public struct Limit {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint
                public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                    base.constrain(sourceRect: &sourceRect, by: rect)
                }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Left.cropInside(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Left.crop(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
            }
        }
        public static func pull(from dependency: Pull.Dependence) -> Left { return Left(base: dependency) }
        public struct Pull {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint
                public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                    base.constrain(sourceRect: &sourceRect, by: rect)
                }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Left.pullInside(sourceRect: &sourceRect, toConstrained: rect)
                    }
                }
                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
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

    public struct Top: RectBasedConstraint {
        private let base: RectBasedConstraint
        private init(base: RectBasedConstraint) { self.base = base }

        public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
            base.constrain(sourceRect: &sourceRect, by: rect)
        }

        public static func align(by dependency: Align.Dependence) -> Top { return Top(base: dependency) }
        public struct Align {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint
                public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                    base.constrain(sourceRect: &sourceRect, by: rect)
                }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Top.alignInside(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }

                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Top.align(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
            }
        }

        public static func limit(on dependency: Limit.Dependence) -> Top { return Top(base: dependency) }
        public struct Limit {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint
                public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                    base.constrain(sourceRect: &sourceRect, by: rect)
                }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Top.cropInside(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Top.crop(sourceRect: &sourceRect, byConstrained: rect)
                    }
                }
            }
        }
        public static func pull(from dependency: Pull.Dependence) -> Top { return Top(base: dependency) }
        public struct Pull {
            public struct Dependence: RectBasedConstraint {
                private let base: RectBasedConstraint
                public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                    base.constrain(sourceRect: &sourceRect, by: rect)
                }

                public static var inner: Dependence { return Dependence(base: Inner()) }
                private struct Inner: RectBasedConstraint {
                    func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                        Top.pullInside(sourceRect: &sourceRect, toConstrained: rect)
                    }
                }
                public static var outer: Dependence { return Dependence(base: Outer()) }
                private struct Outer: RectBasedConstraint {
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

// TODO: Add type wrapper for layout parameter for representation as literal or calculation. Or move behavior (like as .scaled, .boxed) to `ValueType`
public struct Layout: RectBasedLayout {
    private let alignment: Alignment
    private let filling: Filling

    public init(alignment: Alignment, filling: Filling) {
        self.alignment = alignment
        self.filling = filling
    }

    public func layout(rect: inout CGRect, in source: CGRect) {
        filling.layout(rect: &rect, in: source)
        alignment.layout(rect: &rect, in: source)
    }

    public struct Alignment: RectBasedLayout {
        private let vertical: Vertical
        private let horizontal: Horizontal

        public init(vertical: Vertical, horizontal: Horizontal) {
            self.vertical = vertical
            self.horizontal = horizontal
        }

        public func layout(rect: inout CGRect, in source: CGRect) {
            vertical.layout(rect: &rect, in: source)
            horizontal.layout(rect: &rect, in: source)
        }

        public struct Horizontal: RectBasedLayout {
            private let base: RectBasedLayout
            private init(base: RectBasedLayout) { self.base = base }
            public func layout(rect: inout CGRect, in source: CGRect) {
                base.layout(rect: &rect, in: source)
            }

            public static func center(_ offset: CGFloat = 0) -> Horizontal { return Horizontal(base: Center(offset: offset)) }
            private struct Center: RectBasedLayout {
                let offset: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.x = source.midX - (rect.width / 2) + offset
                }
            }
            public static func left(_ offset: CGFloat = 0) -> Horizontal { return Horizontal(base: Left(offset: offset)) }
            private struct Left: RectBasedLayout {
                let offset: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.x = source.origin.x + offset
                }
            }
            public static func right(_ offset: CGFloat = 0) -> Horizontal { return Horizontal(base: Right(offset: offset)) }
            private struct Right: RectBasedLayout {
                let offset: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.x = source.maxX - rect.width - offset
                }
            }
        }
        public struct Vertical: RectBasedLayout {
            private let base: RectBasedLayout
            private init(base: RectBasedLayout) { self.base = base }
            public func layout(rect: inout CGRect, in source: CGRect) {
                return base.layout(rect: &rect, in: source)
            }

            public static func center(_ offset: CGFloat = 0) -> Vertical { return Vertical(base: Center(offset: offset)) }
            private struct Center: RectBasedLayout {
                let offset: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.y = source.midY - (rect.height / 2) + offset
                }
            }
            public static func top(_ offset: CGFloat = 0) -> Vertical { return Vertical(base: Top(offset: offset)) }
            private struct Top: RectBasedLayout {
                let offset: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.y = source.origin.y + offset
                }
            }
            public static func bottom(_ offset: CGFloat = 0) -> Vertical { return Vertical(base: Bottom(offset: offset)) }
            private struct Bottom: RectBasedLayout {
                let offset: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.origin.y = source.maxY - rect.height - offset
                }
            }
        }
    }
    // TODO: Boxed behavior is misleading with edge insets values, because change size metric in fact
    // TODO: Add ratio behavior
    public struct Filling: RectBasedLayout {
        private let vertical: Vertical
        private let horizontal: Horizontal

        public func layout(rect: inout CGRect, in source: CGRect) {
            vertical.layout(rect: &rect, in: source)
            horizontal.layout(rect: &rect, in: source)
        }

        public init(vertical: Vertical, horizontal: Horizontal) {
            self.vertical = vertical
            self.horizontal = horizontal
        }

        public struct Horizontal: RectBasedLayout {
            private let base: RectBasedLayout
            private init(base: RectBasedLayout) { self.base = base }
            public func layout(rect: inout CGRect, in source: CGRect) {
                return base.layout(rect: &rect, in: source)
            }

//            public static var identity: Horizontal { return Horizontal(base: Identity()) }
//            private struct Identity: RectBasedLayout {
//                func layout(rect: inout CGRect, in source: CGRect) {}
//            }

            // TODO: May be rename to fixed ?
            public static func constantly(_ value: CGFloat) -> Horizontal { return Horizontal(base: Constantly(value: value)) }
            private struct Constantly: RectBasedLayout {
                let value: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.size.width = value
                }
            }

            public static func scaled(_ scale: CGFloat) -> Horizontal { return Horizontal(base: Scaled(scale: scale)) }
            private struct Scaled: RectBasedLayout {
                let scale: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.size.width = source.width.multiplied(by: scale)
                }
            }
            public static func boxed(_ edges: UIEdgeInsets.Horizontal) -> Horizontal { return Horizontal(base: Boxed(edges: edges)) }
            private struct Boxed: RectBasedLayout {
                let edges: UIEdgeInsets.Horizontal
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.size.width = max(0, source.width.subtracting(edges.full))
                }
            }
        }
        public struct Vertical: RectBasedLayout {
            private let base: RectBasedLayout
            private init(base: RectBasedLayout) { self.base = base }
            public func layout(rect: inout CGRect, in source: CGRect) {
                return base.layout(rect: &rect, in: source)
            }

//            public static var identity: Vertical { return Vertical(base: Identity()) }
//            private struct Identity: RectBasedLayout {
//                func layout(rect: inout CGRect, in source: CGRect) {}
//            }

            public static func constantly(_ value: CGFloat) -> Vertical { return Vertical(base: Constantly(value: value)) }
            private struct Constantly: RectBasedLayout {
                let value: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.size.height = value
                }
            }

            public static func scaled(_ scale: CGFloat) -> Vertical { return Vertical(base: Scaled(scale: scale)) }
            private struct Scaled: RectBasedLayout {
                let scale: CGFloat
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.size.height = source.height.multiplied(by: scale)
                }
            }
            public static func boxed(_ edges: UIEdgeInsets.Vertical) -> Vertical { return Vertical(base: Boxed(edges: edges)) }
            private struct Boxed: RectBasedLayout {
                let edges: UIEdgeInsets.Vertical
                func layout(rect: inout CGRect, in source: CGRect) {
                    rect.size.height = max(0, source.height.subtracting(edges.full))
                }
            }
        }
    }
}

public extension Layout {
    public init(vertical: (alignment: Alignment.Vertical, filling: Filling.Vertical), horizontal: (alignment: Alignment.Horizontal, filling: Filling.Horizontal)) {
        self.init(alignment: Alignment(vertical: vertical.alignment, horizontal: horizontal.alignment),
                  filling: Filling(vertical: vertical.filling, horizontal: horizontal.filling))
    }
    public init(x: Alignment.Horizontal, y: Alignment.Vertical, width: Filling.Horizontal, height: Filling.Vertical) {
        self.init(alignment: Alignment(vertical: y, horizontal: x),
                  filling: Filling(vertical: height, horizontal: width))
    }
}

extension Layout.Alignment {
    public func apply(with filling: Layout.Filling, for item: LayoutItem, use constraints: [ConstrainRect]) {
        filling.apply(for: item, use: constraints)
        apply(for: item, use: constraints)
    }
}

extension Layout.Filling {
    public func apply(with alignment: Layout.Alignment, for item: LayoutItem, use constraints: [ConstrainRect]) {
        apply(for: item, use: constraints)
        alignment.apply(for: item, use: constraints)
    }
}


// MARK: Attempts, not used

/*
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
