//
//  CGLayoutPrivateEvolution.swift
//  CGLayout-iOS
//
//  Created by Denis Koryttsev on 07/10/2017.
//

import Foundation

public struct LayoutWorkspace {
    public struct Before {
        public static func align(axis: RectAxis, anchor: RectAxisAnchor) -> RectBasedConstraint { return Align(axis: axis, anchor: anchor) }
        internal struct Align: RectBasedConstraint {
            let axis: RectAxis
            let anchor: RectAxisAnchor

            public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
                axis.set(origin: anchor.value(for: rect, in: axis) - axis.get(sizeAt: sourceRect), for: &sourceRect)
            }
        }
        public static func limit(axis: RectAxis, anchor: RectAxisAnchor) -> RectBasedConstraint { return Limit(axis: axis, anchor: anchor) }
        internal struct Limit: RectBasedConstraint {
            let axis: RectAxis
            let anchor: RectAxisAnchor

            public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
                let anchorPosition = anchor.value(for: rect, in: axis)
                axis.set(size: max(0, min(axis.get(sizeAt: sourceRect), anchorPosition - axis.get(minOf: sourceRect))),
                         for: &sourceRect)
                axis.set(origin: min(anchorPosition, axis.get(minOf: sourceRect)), for: &sourceRect)
            }
        }
        public static func pull(axis: RectAxis, anchor: RectAxisAnchor) -> RectBasedConstraint { return Pull(axis: axis, anchor: anchor) }
        internal struct Pull: RectBasedConstraint {
            let axis: RectAxis
            let anchor: RectAxisAnchor

            public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
                let anchorPosition = anchor.value(for: rect, in: axis)
                axis.set(size: max(0, anchorPosition - axis.get(minOf: sourceRect)),
                         for: &sourceRect)
                axis.set(origin: anchorPosition - axis.get(sizeAt: sourceRect), for: &sourceRect)
            }
        }
    }
    public struct After {
        public static func align(axis: RectAxis, anchor: RectAxisAnchor) -> RectBasedConstraint { return Align(axis: axis, anchor: anchor) }
        internal struct Align: RectBasedConstraint {
            let axis: RectAxis
            let anchor: RectAxisAnchor

            public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
                axis.set(origin: anchor.value(for: rect, in: axis), for: &sourceRect)
            }
        }
        public static func limit(axis: RectAxis, anchor: RectAxisAnchor) -> RectBasedConstraint { return Limit(axis: axis, anchor: anchor) }
        internal struct Limit: RectBasedConstraint {
            let axis: RectAxis
            let anchor: RectAxisAnchor

            public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
                let anchorPosition = anchor.value(for: rect, in: axis)
                axis.set(size: max(0, min(axis.get(sizeAt: sourceRect), axis.get(maxOf: sourceRect) - anchorPosition)),
                         for: &sourceRect)
                axis.set(origin: max(anchorPosition, axis.get(minOf: sourceRect)), for: &sourceRect)
            }
        }
        public static func pull(axis: RectAxis, anchor: RectAxisAnchor) -> RectBasedConstraint { return Pull(axis: axis, anchor: anchor) }
        internal struct Pull: RectBasedConstraint {
            let axis: RectAxis
            let anchor: RectAxisAnchor

            public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
                let anchorPosition = anchor.value(for: rect, in: axis)
                axis.set(size: max(0, axis.get(maxOf: sourceRect) - anchorPosition),
                         for: &sourceRect)
                axis.set(origin: anchorPosition, for: &sourceRect)
            }
        }
    }
}

public protocol RectAxisAnchor {
    //    func set(value: CGFloat, for rect: inout CGRect, in axis: RectAxis)
    func value(for rect: CGRect, in axis: RectAxis) -> CGFloat
}
public struct _RectAxisAnchor {
    public static var leading: RectAxisAnchor = Leading()
    struct Leading: RectAxisAnchor {
        func value(for rect: CGRect, in axis: RectAxis) -> CGFloat {
            return axis.get(minOf: rect)
        }
    }
    public static var trailing: RectAxisAnchor = Trailing()
    struct Trailing: RectAxisAnchor {
        func value(for rect: CGRect, in axis: RectAxis) -> CGFloat {
            return axis.get(maxOf: rect)
        }
    }
    public static var center: RectAxisAnchor = Center()
    struct Center: RectAxisAnchor {
        func value(for rect: CGRect, in axis: RectAxis) -> CGFloat {
            return axis.get(midOf: rect)
        }
    }
    struct Size: RectAxisAnchor {
        func value(for rect: CGRect, in axis: RectAxis) -> CGFloat {
            return axis.get(sizeAt: rect)
        }
    }
}

public protocol RectAxis {
    func set(size: CGFloat, for rect: inout CGRect)
    func get(sizeAt rect: CGRect) -> CGFloat
    func set(origin: CGFloat, for rect: inout CGRect)
    func get(originAt rect: CGRect) -> CGFloat

    func get(maxOf rect: CGRect) -> CGFloat
    func get(minOf rect: CGRect) -> CGFloat
    func get(midOf rect: CGRect) -> CGFloat

    func offset(rect: CGRect, by value: CGFloat) -> CGRect
}
extension RectAxis {
    func invertedIn2D() -> RectAxis { return self is _RectAxis.Horizontal ? _RectAxis.vertical : _RectAxis.horizontal }
}

public struct _RectAxis: RectAxis {
    let base: RectAxis

    public func set(size: CGFloat, for rect: inout CGRect) { base.set(size: size, for: &rect) }
    public func set(origin: CGFloat, for rect: inout CGRect) { base.set(origin: origin, for: &rect) }
    public func get(originAt rect: CGRect) -> CGFloat { return base.get(originAt: rect) }
    public func get(sizeAt rect: CGRect) -> CGFloat { return base.get(sizeAt: rect) }
    public func get(maxOf rect: CGRect) -> CGFloat { return base.get(maxOf: rect) }
    public func get(minOf rect: CGRect) -> CGFloat { return base.get(minOf: rect) }
    public func get(midOf rect: CGRect) -> CGFloat { return base.get(midOf: rect) }
    public func offset(rect: CGRect, by value: CGFloat) -> CGRect { return base.offset(rect: rect, by: value) }

    public static var horizontal: RectAxis = Horizontal()
    internal struct Horizontal: RectAxis {
        func set(size: CGFloat, for rect: inout CGRect) { rect.size.width = size }
        func set(origin: CGFloat, for rect: inout CGRect) { rect.origin.x = origin }
        func get(originAt rect: CGRect) -> CGFloat { return rect.origin.x }
        func get(sizeAt rect: CGRect) -> CGFloat { return rect.width }
        func get(maxOf rect: CGRect) -> CGFloat { return rect.maxX }
        func get(minOf rect: CGRect) -> CGFloat { return rect.minX }
        func get(midOf rect: CGRect) -> CGFloat { return rect.midX }
        func offset(rect: CGRect, by value: CGFloat) -> CGRect { return rect.offsetBy(dx: value, dy: 0) }
    }

    public static var vertical: RectAxis = Vertical()
    internal struct Vertical: RectAxis {
        func set(size: CGFloat, for rect: inout CGRect) { rect.size.height = size }
        func set(origin: CGFloat, for rect: inout CGRect) { rect.origin.y = origin }
        func get(sizeAt rect: CGRect) -> CGFloat { return rect.height }
        func get(originAt rect: CGRect) -> CGFloat { return rect.origin.y }
        func get(maxOf rect: CGRect) -> CGFloat { return rect.maxY }
        func get(minOf rect: CGRect) -> CGFloat { return rect.minY }
        func get(midOf rect: CGRect) -> CGFloat { return rect.midY }
        func offset(rect: CGRect, by value: CGFloat) -> CGRect { return rect.offsetBy(dx: 0, dy: value) }
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
 */
