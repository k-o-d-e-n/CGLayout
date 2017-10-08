//
//  CGLayoutPrivateEvolution.swift
//  CGLayout-iOS
//
//  Created by Denis Koryttsev on 07/10/2017.
//

import Foundation

public protocol RectAnchorDefining { // TODO: Create CGRect wrapper ?? CGRect
    var left: LeftAnchor { get }
    var right: RightAnchor { get }
    var bottom: VerticalAnchor { get }
    var top: VerticalAnchor { get }
    var leading: HorizontalAnchor { get }
    var trailing: HorizontalAnchor { get }
    var center: CenterAnchor { get }
    var width: WidthAnchor { get }
    var height: HeightAnchor { get }
    var size: SizeAnchor { get }
    var origin: OriginAnchor { get }
}
public protocol AnchoredItem {
    associatedtype Anchors: RectAnchorDefining
    var anchors: Anchors { get }
}
extension UIView: AnchoredItem {
    public var anchors: Anchors { return Anchors(self) }
    public class Anchors: RectAnchorDefining {
        var view: UIView
        init(_ view: UIView) {
            self.view = view
        }
        public lazy var left: LeftAnchor = .init()
        public lazy var right: RightAnchor = .init()
        public lazy var bottom: VerticalAnchor = .init(BottomAnchor())
        public lazy var top: VerticalAnchor = .init(TopAnchor())
        public lazy var leading: HorizontalAnchor = { return UIView.userInterfaceLayoutDirection(for: self.view.semanticContentAttribute) == .rightToLeft ? .init(self.left) : .init(self.right) }()
        public lazy var trailing: HorizontalAnchor = { return UIView.userInterfaceLayoutDirection(for: self.view.semanticContentAttribute) == .rightToLeft ? .init(self.right) : .init(self.left) }()
        public lazy var center: CenterAnchor = .init()
        public lazy var width: WidthAnchor = .width
        public lazy var height: HeightAnchor = .height
        public lazy var size: SizeAnchor = .init()
        public lazy var origin: OriginAnchor = .init(horizontalAnchor: .init(self.left), verticalAnchor: .init(self.top))
    }
}
public struct AnyRectBasedConstraint: RectBasedConstraint {
    let constrain: (inout CGRect, CGRect) -> Void

    public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        constrain(&sourceRect, rect)
    }
}
extension AnyRectBasedConstraint {
    public static func align<A1: AxisRectAnchor, A2: AxisRectAnchor>(_ a1: A1, to a2: A2) -> AnyRectBasedConstraint where A1.Metric == A2.Metric, A1.Axis == A2.Axis {
        return AnyRectBasedConstraint { a1.offset(rect: &$0, by: a2.get(for: $1)) }
    }
}
extension LayoutItem {
    public func anchorConstraint(for anchors: [AnyRectBasedConstraint]) -> LayoutConstraint {
        return LayoutConstraint(item: self, constraints: anchors)
    }
}

public protocol AnyRectAnchor {
    associatedtype Metric
//    func set(_ value: Metric, for rect: inout CGRect)
    func get(for rect: CGRect) -> Metric
}
public protocol AxisRectAnchor: AnyRectAnchor {
    associatedtype Metric = CGFloat
    associatedtype Axis: RectAxis
    var axis: Axis { get }
    func offset(rect: inout CGRect, by value: Metric)
    func move(in rect: inout CGRect, to value: Metric)
}
public protocol PointRectAnchor: AnyRectAnchor {
    associatedtype Metric = CGPoint
    func offset(rect: inout CGRect, by value: Metric)
    func move(in rect: inout CGRect, to value: Metric)
}
public protocol SizeRectAnchor: AnyRectAnchor {
    associatedtype Metric = CGSize
    func set(_ value: CGSize, for rect: inout CGRect)
}
extension SizeRectAnchor {
    public func set(_ value: CGSize, for rect: inout CGRect) { rect.size = value }
    public func get(for rect: CGRect) -> CGSize { return rect.size }
    public func box(rect: inout CGRect, by value: CGFloat) { set(get(for: rect) - value, for: &rect) }
    public func scale(in rect: inout CGRect, to value: CGFloat) { set(get(for: rect) * value, for: &rect) }
}
extension AxisRectAnchor {
    public func offset<Anchor: AxisRectAnchor>(rect: inout CGRect, by anchor: (CGRect, Anchor)) where Anchor.Metric == Metric, Anchor.Axis == Axis {
        offset(rect: &rect, by: anchor.1.get(for: anchor.0))
    }
}

public struct AxisCenterAnchor<Axis: RectAxis>: AxisRectAnchor {
    static var horizontal: AxisCenterAnchor<_RectAxis.Horizontal> { return .init(axis: .init()) }
    static var vertical: AxisCenterAnchor<_RectAxis.Vertical> { return .init(axis: .init()) }

    public let axis: Axis
    public func offset(rect: inout CGRect, by value: CGFloat) { axis.offset(midOf: &rect, to: value) }
    public func move(in rect: inout CGRect, to value: CGFloat) { axis.move(midOf: &rect, to: value) }
    public func get(for rect: CGRect) -> CGFloat { return axis.get(midOf: rect) }
}
public struct BottomAnchor: AxisRectAnchor {
    public let axis = _RectAxis.vertical
    public func offset(rect: inout CGRect, by value: CGFloat) { axis.offset(maxOf: &rect, to: value) }
    public func move(in rect: inout CGRect, to value: CGFloat) { axis.move(maxOf: &rect, to: value) }
    public func get(for rect: CGRect) -> CGFloat { return axis.get(maxOf: rect) }
}
public struct RightAnchor: AxisRectAnchor {
    public let axis = _RectAxis.horizontal
    public func offset(rect: inout CGRect, by value: CGFloat) { axis.offset(maxOf: &rect, to: value) }
    public func move(in rect: inout CGRect, to value: CGFloat) { axis.move(maxOf: &rect, to: value) }
    public func get(for rect: CGRect) -> CGFloat { return axis.get(maxOf: rect) }
}
public typealias WidthAnchor = AxisSizeAnchor<_RectAxis.Horizontal>
public typealias HeightAnchor = AxisSizeAnchor<_RectAxis.Vertical>
public struct AxisSizeAnchor<Axis: RectAxis>: AxisRectAnchor {
    static var width: WidthAnchor { return .init(axis: .init()) }
    static var height: HeightAnchor { return .init(axis: .init()) }

    public let axis: Axis
    public func offset(rect: inout CGRect, by value: CGFloat) { axis.offset(minOf: &rect, to: value) }
    public func move(in rect: inout CGRect, to value: CGFloat) { axis.move(minOf: &rect, to: value) }
    public func get(for rect: CGRect) -> CGFloat { return axis.get(sizeAt: rect) }
}
public struct TopAnchor: AxisRectAnchor {
    public let axis = _RectAxis.vertical
    public func offset(rect: inout CGRect, by value: CGFloat) { axis.offset(minOf: &rect, to: value) }
    public func move(in rect: inout CGRect, to value: CGFloat) { axis.move(minOf: &rect, to: value) }
    public func get(for rect: CGRect) -> CGFloat { return axis.get(minOf: rect) }
}
public struct LeftAnchor: AxisRectAnchor {
    public let axis = _RectAxis.horizontal
    public func offset(rect: inout CGRect, by value: CGFloat) { axis.offset(minOf: &rect, to: value) }
    public func move(in rect: inout CGRect, to value: CGFloat) { axis.move(minOf: &rect, to: value) }
    public func get(for rect: CGRect) -> CGFloat { return axis.get(minOf: rect) }
}
public typealias HorizontalAnchor = AnyAxisAnchor<_RectAxis.Horizontal>
public typealias VerticalAnchor = AnyAxisAnchor<_RectAxis.Vertical>
public struct AnyAxisAnchor<Axis: RectAxis>: AxisRectAnchor {
    let offset: (inout CGRect, CGFloat) -> Void
    let move: (inout CGRect, CGFloat) -> Void
    let get: (CGRect) -> CGFloat
    public let axis: Axis

    init<T: AxisRectAnchor>(_ base: T) where Axis == T.Axis, T.Metric == Metric {
        self.axis = base.axis
        self.offset = base.offset(rect:by:)
        self.move = base.move(in:to:)
        self.get = base.get(for:)
    }

    public func offset(rect: inout CGRect, by value: CGFloat) { offset(&rect, value) }
    public func move(in rect: inout CGRect, to value: CGFloat) { move(&rect, value) }
    public func get(for rect: CGRect) -> CGFloat { return get(rect) }
}
public struct CenterAnchor: PointRectAnchor {
    public var horizontal: AxisCenterAnchor<_RectAxis.Horizontal> { return .horizontal }
    public var vertical: AxisCenterAnchor<_RectAxis.Vertical> { return .vertical }
    public func offset(rect: inout CGRect, by value: CGPoint) {
        horizontal.offset(rect: &rect, by: value.x)
        vertical.offset(rect: &rect, by: value.y)
    }

    public func move(in rect: inout CGRect, to value: CGPoint) {
        horizontal.move(in: &rect, to: value.x)
        vertical.move(in: &rect, to: value.y)
    }

    public func get(for rect: CGRect) -> CGPoint { return CGPoint(x: horizontal.get(for: rect), y: vertical.get(for: rect)) }
}
public struct OriginAnchor: PointRectAnchor {
    let horizontalAnchor: HorizontalAnchor
    let verticalAnchor: VerticalAnchor
    public func offset(rect: inout CGRect, by value: CGPoint) {
        horizontalAnchor.offset(rect: &rect, by: value.x)
        verticalAnchor.offset(rect: &rect, by: value.y)
    }

    public func move(in rect: inout CGRect, to value: CGPoint) {
        horizontalAnchor.move(in: &rect, to: value.x)
        verticalAnchor.move(in: &rect, to: value.y)
    }

    public func get(for rect: CGRect) -> CGPoint { return CGPoint(x: _RectAxis.horizontal.get(midOf: rect), y: _RectAxis.vertical.get(midOf: rect)) }
}
public struct SizeAnchor: SizeRectAnchor {}


public protocol RectAxis {
    func set(size: CGFloat, for rect: inout CGRect)
    func get(sizeAt rect: CGRect) -> CGFloat
    func set(origin: CGFloat, for rect: inout CGRect)
    func get(originAt rect: CGRect) -> CGFloat

    func get(maxOf rect: CGRect) -> CGFloat
    func get(minOf rect: CGRect) -> CGFloat
    func get(midOf rect: CGRect) -> CGFloat
    func offset(rect: CGRect, by value: CGFloat) -> CGRect

//    // offset setters
//    func offset(minOf rect: inout CGRect, to newMin: CGFloat)
//    func offset(midOf rect: inout CGRect, to newMid: CGFloat)
//    func offset(maxOf rect: inout CGRect, to newMax: CGFloat)
//
//    // stretch setters
//    func move(minOf rect: inout CGRect, to newMin: CGFloat)
//    func move(midOf rect: inout CGRect, to newMid: CGFloat)
//    func move(maxOf rect: inout CGRect, to newMax: CGFloat)
}
extension RectAxis {
    // offset setters
    func offset(minOf rect: inout CGRect, to newMin: CGFloat) { set(origin: newMin, for: &rect) }
    func offset(midOf rect: inout CGRect, to newMid: CGFloat) { set(origin: newMid - get(sizeAt: rect)*0.5, for: &rect) }
    func offset(maxOf rect: inout CGRect, to newMax: CGFloat) { set(origin: newMax - get(sizeAt: rect), for: &rect) }

    // stretch setters
    func move(minOf rect: inout CGRect, to newMin: CGFloat) { set(size: max(0, get(maxOf: rect) - newMin), for: &rect); set(origin: newMin, for: &rect) }
    func move(midOf rect: inout CGRect, to newMid: CGFloat) {
        let diff = get(midOf: rect) - newMid
        let size: CGFloat
        if diff > 0 {
            size = (newMid - get(minOf: rect)) * 2
        } else {
            let max = get(maxOf: rect)
            size = (max - newMid) * 2
            set(origin: max - size, for: &rect)
        }
        set(size: max(0, size), for: &rect)
    }
    func move(maxOf rect: inout CGRect, to newMax: CGFloat) { rect.size.width = max(0, newMax - rect.minX) }
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

    public static var horizontal: _RectAxis.Horizontal = Horizontal()
    public struct Horizontal: RectAxis {
        public func set(size: CGFloat, for rect: inout CGRect) { rect.size.width = size }
        public func set(origin: CGFloat, for rect: inout CGRect) { rect.origin.x = origin }
        public func get(originAt rect: CGRect) -> CGFloat { return rect.origin.x }
        public func get(sizeAt rect: CGRect) -> CGFloat { return rect.width }
        public func get(maxOf rect: CGRect) -> CGFloat { return rect.maxX }
        public func get(minOf rect: CGRect) -> CGFloat { return rect.minX }
        public func get(midOf rect: CGRect) -> CGFloat { return rect.midX }
        public func offset(rect: CGRect, by value: CGFloat) -> CGRect { return rect.offsetBy(dx: value, dy: 0) }

//        // offset setters
//        func offset(minOf rect: inout CGRect, to newMin: CGFloat) { rect.origin.x = newMin }
//        func offset(midOf rect: inout CGRect, to newMid: CGFloat) { rect.origin.x = newMid - rect.width/2 }
//        func offset(maxOf rect: inout CGRect, to newMax: CGFloat) { rect.origin.x = newMax - rect.width }
//
//        // stretch setters
//        func move(minOf rect: inout CGRect, to newMin: CGFloat) { rect.size.width = max(0, rect.maxX - newMin); rect.origin.x = newMin }
//        func move(midOf rect: inout CGRect, to newMid: CGFloat) {
//            let diff = rect.midX - newMid
//            let width: CGFloat
//            if diff > 0 {
//                width = (newMid - rect.minX) * 2
//            } else {
//                width = (rect.maxX - newMid) * 2
//                rect.origin.x = rect.maxX - width
//            }
//            rect.size.width = max(0, width)
//        }
//        func move(maxOf rect: inout CGRect, to newMax: CGFloat) { rect.size.width = max(0, newMax - rect.minX) }
    }

    public static var vertical: _RectAxis.Vertical = Vertical()
    public struct Vertical: RectAxis {
        public func set(size: CGFloat, for rect: inout CGRect) { rect.size.height = size }
        public func set(origin: CGFloat, for rect: inout CGRect) { rect.origin.y = origin }
        public func get(sizeAt rect: CGRect) -> CGFloat { return rect.height }
        public func get(originAt rect: CGRect) -> CGFloat { return rect.origin.y }
        public func get(maxOf rect: CGRect) -> CGFloat { return rect.maxY }
        public func get(minOf rect: CGRect) -> CGFloat { return rect.minY }
        public func get(midOf rect: CGRect) -> CGFloat { return rect.midY }
        public func offset(rect: CGRect, by value: CGFloat) -> CGRect { return rect.offsetBy(dx: 0, dy: value) }
//
//        // offset setters
//        func offset(minOf rect: inout CGRect, to newMin: CGFloat) { rect.origin.y = newMin }
//        func offset(midOf rect: inout CGRect, to newMid: CGFloat) { rect.origin.y = newMid - rect.height/2 }
//        func offset(maxOf rect: inout CGRect, to newMax: CGFloat) { rect.origin.y = newMax - rect.height }
//
//        // stretch setters
//        func move(minOf rect: inout CGRect, to newMin: CGFloat) { rect.size.height = max(0, rect.maxY - newMin); rect.origin.y = newMin }
//        func move(midOf rect: inout CGRect, to newMid: CGFloat) {
//            let diff = rect.midY - newMid
//            let height: CGFloat
//            if diff > 0 {
//                height = (newMid - rect.minY) * 2
//            } else {
//                height = (rect.maxY - newMid) * 2
//                rect.origin.y = rect.maxY - height
//            }
//            rect.size.height = max(0, height)
//        }
//        func move(maxOf rect: inout CGRect, to newMax: CGFloat) { rect.size.height = max(0, newMax - rect.minY) }
    }
}


public struct LayoutWorkspace {
    public struct Before {
        public static func align(axis: RectAxis, anchor: RectAxisAnchor) -> RectBasedConstraint { return Align(axis: axis, anchor: anchor) }
        internal struct Align: RectBasedConstraint {
            let axis: RectAxis
            let anchor: RectAxisAnchor

            public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
                axis.set(origin: anchor.get(for: rect, in: axis) - axis.get(sizeAt: sourceRect), for: &sourceRect)
            }
        }
        public static func limit(axis: RectAxis, anchor: RectAxisAnchor) -> RectBasedConstraint { return Limit(axis: axis, anchor: anchor) }
        internal struct Limit: RectBasedConstraint {
            let axis: RectAxis
            let anchor: RectAxisAnchor

            public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
                let anchorPosition = anchor.get(for: rect, in: axis)
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
                let anchorPosition = anchor.get(for: rect, in: axis)
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
                axis.set(origin: anchor.get(for: rect, in: axis), for: &sourceRect)
            }
        }
        public static func limit(axis: RectAxis, anchor: RectAxisAnchor) -> RectBasedConstraint { return Limit(axis: axis, anchor: anchor) }
        internal struct Limit: RectBasedConstraint {
            let axis: RectAxis
            let anchor: RectAxisAnchor

            public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
                let anchorPosition = anchor.get(for: rect, in: axis)
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
                let anchorPosition = anchor.get(for: rect, in: axis)
                axis.set(size: max(0, axis.get(maxOf: sourceRect) - anchorPosition),
                         for: &sourceRect)
                axis.set(origin: anchorPosition, for: &sourceRect)
            }
        }
    }
    public struct Center {
        public static func align(axis: RectAxis, anchor: RectAxisAnchor) -> RectBasedConstraint { return Align(axis: axis, anchor: anchor) }
        internal struct Align: RectBasedConstraint {
            let axis: RectAxis
            let anchor: RectAxisAnchor

            public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
                axis.set(origin: anchor.get(for: rect, in: axis) - axis.get(sizeAt: sourceRect) * 0.5, for: &sourceRect)
            }
        }
        //        public static func limit(axis: RectAxis, anchor: RectAxisAnchor, limit limitAnchor: RectAxisAnchor) -> RectBasedConstraint { return Limit(axis: axis, anchor: anchor, limitAnchor: limitAnchor) }
        //        internal struct Limit: RectBasedConstraint {
        //            let axis: RectAxis
        //            let anchor: RectAxisAnchor
        //            let limitAnchor: RectAxisAnchor
        //
        //            public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        //                let anchorPosition = anchor.value(for: rect, in: axis)
        //                let limitAnchorPosition = limitAnchor.value(for: sourceRect, in: axis)
        //                axis.set(size: max(0, min(axis.get(sizeAt: sourceRect), max( - anchorPosition))),
        //                         for: &sourceRect)
        //                axis.set(origin: max(anchorPosition, axis.get(minOf: sourceRect)), for: &sourceRect)
        //            }
        //        }
        //        public static func pull(axis: RectAxis, anchor: RectAxisAnchor, pull pullAnchor: RectAxisAnchor) -> RectBasedConstraint { return Pull(axis: axis, anchor: anchor, pullAnchor: pullAnchor) }
        //        internal struct Pull: RectBasedConstraint {
        //            let axis: RectAxis
        //            let anchor: RectAxisAnchor
        //            let pullAnchor: RectAxisAnchor
        //
        //            public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        //                let anchorPosition = anchor.value(for: rect, in: axis)
        //                axis.set(size: max(0, abs(pullAnchor.value(for: sourceRect, in: axis) - anchorPosition)),
        //                         for: &sourceRect)
        //                axis.set(origin: anchorPosition, for: &sourceRect)
        //            }
        //        }
    }
}

struct _RectAnchor {
    static var leadingHorizontal = AnyAnchor<CGFloat>(getter: _RectAxis.horizontal.get(minOf:))
    static var trailingHorizontal = AnyAnchor<CGFloat>(getter: _RectAxis.horizontal.get(maxOf:))
    static var leadingVertical = AnyAnchor<CGFloat>(getter: _RectAxis.vertical.get(minOf:))
    static var trailingVertical = AnyAnchor<CGFloat>(getter: _RectAxis.vertical.get(maxOf:))
    static var centerHorizontal = AnyAnchor<CGFloat>(getter: _RectAxis.horizontal.get(midOf:))
    static var centerVertical = AnyAnchor<CGFloat>(getter: _RectAxis.vertical.get(midOf:))
    static var center = AnyAnchor<CGPoint>(getter: { CGPoint(x: _RectAxis.horizontal.get(midOf: $0), y: _RectAxis.vertical.get(midOf: $0)) })
    static var sizeHorizontal = AnyAnchor<CGFloat>(getter: _RectAxis.horizontal.get(sizeAt:))
    static var sizeVertical = AnyAnchor<CGFloat>(getter: _RectAxis.vertical.get(sizeAt:))
    static var size = AnyAnchor<CGSize>(getter: { $0.size })//CGSize(width: _RectAxis.horizontal.get(sizeAt: $0), height: _RectAxis.vertical.get(sizeAt: $0)) })
}
struct AnyAnchor<Metric>: AnyRectAnchor /*, OptionSet*/ {
    fileprivate let getter: (CGRect) -> Metric
    //    fileprivate let setter: (Metric, inout CGRect)
    //    func set(value: Metric, for rect: inout CGRect) { setter(value, &rect) }
    func get(for rect: CGRect) -> Metric { return getter(rect) }
}

public protocol RectAxisAnchor {
    //    func set(value: CGFloat, for rect: inout CGRect, in axis: RectAxis)
    func get(for rect: CGRect, in axis: RectAxis) -> CGFloat
}
public struct _RectAxisAnchor {
    public static var leading: RectAxisAnchor = Leading()
    struct Leading: RectAxisAnchor {
        func get(for rect: CGRect, in axis: RectAxis) -> CGFloat {
            return axis.get(minOf: rect)
        }
    }
    public static var trailing: RectAxisAnchor = Trailing()
    struct Trailing: RectAxisAnchor {
        func get(for rect: CGRect, in axis: RectAxis) -> CGFloat {
            return axis.get(maxOf: rect)
        }
    }
    public static var center: RectAxisAnchor = Center()
    struct Center: RectAxisAnchor {
        func get(for rect: CGRect, in axis: RectAxis) -> CGFloat {
            return axis.get(midOf: rect)
        }
    }
    struct Size: RectAxisAnchor {
        func get(for rect: CGRect, in axis: RectAxis) -> CGFloat {
            return axis.get(sizeAt: rect)
        }
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
