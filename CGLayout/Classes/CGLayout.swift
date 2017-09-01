//
//  Layout.swift
//  FirstAppObjC
//
//  Created by Denis Koryttsev on 29/08/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

import UIKit

// TODO: Add behaviors with UIView size that fits and others
// TODO: Add auto resized behaviors in Filling set. // SizeBasedConstraint
// TODO: Think how can be use OptionSet type.

public protocol LayoutItem: class { // TODO: should be avoid limit only on class types
    var frame: CGRect { get set }
    var bounds: CGRect { get set }
    var superItem: LayoutItem? { get }
}
extension UIView: LayoutItem {
    public var superItem: LayoutItem? { return superview }
}
extension CALayer: LayoutItem {
    public var superItem: LayoutItem? { return superlayer }
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

public typealias ConstraintItem = (rect: CGRect, constraint: RectBasedConstraint)
public extension RectBasedLayout {
    func layout(rect: CGRect, in source: CGRect) -> CGRect {
        var rect = rect
        layout(rect: &rect, in: source)
        return rect
    }

    // TODO: Make ConstraintItem is more conviently
    // TODO: `constraints` has not priority, because conflicted constraints will be replaced result previous constraints
    func apply(for item: LayoutItem, use constraints: [ConstraintItem] = []) {
        let source = constraints.reduce(item.superItem!.bounds) { (result, constrained) -> CGRect in
            return result.constrainedBy(rect: constrained.rect, use: constrained.constraint)
        }
        item.frame = layout(rect: item.frame, in: source)
    }
}

// TODO: Add tests for RectBasedConstraint
public protocol RectBasedConstraint {
    func constrain(sourceRect: inout CGRect, by rect: CGRect)
}

/// Using for constraint size
public protocol SizeBasedConstraint {
    // TODO:
}

extension RectBasedConstraint {
    func constrained(sourceRect: CGRect, by rect: CGRect) -> CGRect {
        var sourceRect = sourceRect
        constrain(sourceRect: &sourceRect, by: rect)
        return sourceRect
    }
}

// TODO: Add center and other behaviors
// TODO: Add extension CGRect for calculate spaces between edges of frames, and replace calculations inside behaviors
public struct LayoutAnchor {
    public struct Bottom: RectBasedConstraint {
        private let base: RectBasedConstraint
        private init(base: RectBasedConstraint) { self.base = base }

        public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
            base.constrain(sourceRect: &sourceRect, by: rect)
        }

        public static func alignBy(inner: Bool) -> Bottom { return Bottom(base: inner ? AlignInner() : Align()) } // TODO: May be need to make it static let
        private struct Align: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Bottom.align(sourceRect: &sourceRect, byConstrained: rect)
            }
        }
        private struct AlignInner: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Bottom.alignInside(sourceRect: &sourceRect, byConstrained: rect)
            }
        }
        public static func limitOn(inner: Bool) -> Bottom { return Bottom(base: inner ? LimitInner() : Limit()) }
        private struct Limit: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Bottom.crop(sourceRect: &sourceRect, byConstrained: rect)
            }
        }
        private struct LimitInner: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Bottom.cropInside(sourceRect: &sourceRect, byConstrained: rect)
            }
        }
        public static func pullFrom(inner: Bool) -> Bottom { return Bottom(base: inner ? PullInner() : Pull()) }
        private struct Pull: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Bottom.pull(sourceRect: &sourceRect, toConstrained: rect)
            }
        }
        private struct PullInner: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Bottom.pullInside(sourceRect: &sourceRect, toConstrained: rect)
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
            sourceRect.origin.y = max(sourceRect.origin.y, rect.maxY - sourceRect.height)
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

        public static func alignBy(inner: Bool) -> Right { return Right(base: inner ? AlignInner() : Align()) }
        private struct Align: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Right.align(sourceRect: &sourceRect, byConstrained: rect)
            }
        }
        private struct AlignInner: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Right.alignInside(sourceRect: &sourceRect, byConstrained: rect)
            }
        }
        public static func limitOn(inner: Bool) -> Right { return Right(base: inner ? LimitInner() : Limit()) }
        private struct Limit: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Right.crop(sourceRect: &sourceRect, byConstrained: rect)
            }
        }
        private struct LimitInner: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Right.cropInside(sourceRect: &sourceRect, byConstrained: rect)
            }
        }
        public static func pullFrom(inner: Bool) -> Right { return Right(base: inner ? PullInner() : Pull()) }
        private struct Pull: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Right.pull(sourceRect: &sourceRect, toConstrained: rect)
            }
        }
        private struct PullInner: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Right.pullInside(sourceRect: &sourceRect, toConstrained: rect)
            }
        }

        static private func alignInside(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.origin.x = rect.maxX - sourceRect.width
        }
        static private func align(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.origin.x = rect.maxX
        }
        static private func cropInside(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.size.width = min(sourceRect.width, sourceRect.width - space(fromFarEdgeOf: sourceRect, toConstrained: rect))
        }
        static private func crop(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.size.width = min(sourceRect.width, space(fromFarEdgeOf: sourceRect, toConstrained: rect))
            sourceRect.origin.x = max(sourceRect.origin.x, rect.maxX)
        }
        static private func pullInside(sourceRect: inout CGRect, toConstrained rect: CGRect) {
            sourceRect.size.width = max(0, rect.maxX - sourceRect.origin.x)
            alignInside(sourceRect: &sourceRect, byConstrained: rect)
        }
        static private func pull(sourceRect: inout CGRect, toConstrained rect: CGRect) {
            sourceRect.size.width = space(fromFarEdgeOf: sourceRect, toConstrained: rect)
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

        public static func alignBy(inner: Bool) -> Left { return Left(base: inner ? AlignInner() : Align()) }
        private struct Align: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Left.align(sourceRect: &sourceRect, byConstrained: rect)
            }
        }
        private struct AlignInner: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Left.alignInside(sourceRect: &sourceRect, byConstrained: rect)
            }
        }
        public static func limitOn(inner: Bool) -> Left { return Left(base: inner ? LimitInner() : Limit()) }
        private struct Limit: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Left.crop(sourceRect: &sourceRect, byConstrained: rect)
            }
        }
        private struct LimitInner: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Left.cropInside(sourceRect: &sourceRect, byConstrained: rect)
            }
        }
        public static func pullFrom(inner: Bool) -> Left { return Left(base: inner ? PullInner() : Pull()) }
        private struct Pull: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Left.pull(sourceRect: &sourceRect, toConstrained: rect)
            }
        }
        private struct PullInner: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Left.pullInside(sourceRect: &sourceRect, toConstrained: rect)
            }
        }

        static private func alignInside(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.origin.x = rect.minX
        }
        static private func align(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.origin.x = rect.minX - sourceRect.width
        }
        static private func cropInside(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.size.width = min(sourceRect.width, sourceRect.width - space(fromFarEdgeOf: sourceRect, toConstrained: rect))
            sourceRect.origin.x = max(sourceRect.origin.x, rect.minX)
        }
        static private func crop(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.size.width = min(sourceRect.width, space(fromFarEdgeOf: sourceRect, toConstrained: rect))
            sourceRect.origin.x = min(sourceRect.origin.x, rect.minX)
        }
        static private func pullInside(sourceRect: inout CGRect, toConstrained rect: CGRect) {
            sourceRect.size.width = max(0, sourceRect.maxX - rect.minX)
            alignInside(sourceRect: &sourceRect, byConstrained: rect)
        }
        static private func pull(sourceRect: inout CGRect, toConstrained rect: CGRect) {
            sourceRect.size.width = space(fromFarEdgeOf: sourceRect, toConstrained: rect)
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

        public static func alignBy(inner: Bool) -> Top { return Top(base: inner ? AlignInner() : Align()) }
        private struct Align: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Top.align(sourceRect: &sourceRect, byConstrained: rect)
            }
        }
        private struct AlignInner: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Top.alignInside(sourceRect: &sourceRect, byConstrained: rect)
            }
        }
        public static func limitOn(inner: Bool) -> Top { return Top(base: inner ? LimitInner() : Limit()) }
        private struct Limit: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Top.crop(sourceRect: &sourceRect, byConstrained: rect)
            }
        }
        private struct LimitInner: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Top.cropInside(sourceRect: &sourceRect, byConstrained: rect)
            }
        }
        public static func pullFrom(inner: Bool) -> Top { return Top(base: inner ? PullInner() : Pull()) }
        private struct Pull: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Top.pull(sourceRect: &sourceRect, toConstrained: rect)
            }
        }
        private struct PullInner: RectBasedConstraint {
            func constrain(sourceRect: inout CGRect, by rect: CGRect) {
                Top.pull(sourceRect: &sourceRect, toConstrained: rect)
            }
        }

        static private func alignInside(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.origin.y = rect.minY
        }
        static private func align(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.origin.y = rect.minY - sourceRect.height
        }
        static private func cropInside(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.size.height = min(sourceRect.height, sourceRect.height - space(fromFarEdgeOf: sourceRect, toConstrained: rect))
            sourceRect.origin.y = max(sourceRect.origin.y, rect.minY)
        }
        static private func crop(sourceRect: inout CGRect, byConstrained rect: CGRect) {
            sourceRect.size.height = min(sourceRect.height, space(fromFarEdgeOf: sourceRect, toConstrained: rect))
            sourceRect.origin.y = min(sourceRect.origin.y, rect.minY)
        }
        static private func pullInside(sourceRect: inout CGRect, toConstrained rect: CGRect) {
            sourceRect.size.height = max(0, sourceRect.maxY - rect.minY)
            alignInside(sourceRect: &sourceRect, byConstrained: rect)
        }
        static private func pull(sourceRect: inout CGRect, toConstrained rect: CGRect) {
            sourceRect.size.height = space(fromFarEdgeOf: sourceRect, toConstrained: rect)
            align(sourceRect: &sourceRect, byConstrained: rect)
        }
        static private func space(fromFarEdgeOf sourceRect: CGRect, toConstrained rect: CGRect) -> CGFloat {
            return rect.minY - sourceRect.minY
        }
    }
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

// TODO: Add type wrapper for layout parameter for representation as literal or calculation
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
    // TODO: Boxed behavior is misleading with edge insets values, but change size metric in fact
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
    public init(alignmentV: Alignment.Vertical, fillingV: Filling.Vertical, alignmentH: Alignment.Horizontal, fillingH: Filling.Horizontal) {
        self.init(alignment: Alignment(vertical: alignmentV, horizontal: alignmentH),
                  filling: Filling(vertical: fillingV, horizontal: fillingH))
    }
}
