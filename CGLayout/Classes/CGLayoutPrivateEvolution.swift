//
//  CGLayoutPrivateEvolution.swift
//  CGLayout-iOS
//
//  Created by Denis Koryttsev on 07/10/2017.
//

import Foundation

// TODO: Research problems with Y axis and create 3D View ???



public protocol AxisLayoutEntity {
    associatedtype Axis: RectAxis
    var axis: Axis { get }
}

public protocol RectAnchorDefining {
    var left: AssociatedAnchor<LeftAnchor> { get set }
    var right: AssociatedAnchor<RightAnchor> { get set }
    var bottom: AssociatedAnchor<VerticalAnchor> { get set }
    var top: AssociatedAnchor<VerticalAnchor> { get set }
    var leading: AssociatedAnchor<HorizontalAnchor> { get set }
    var trailing: AssociatedAnchor<HorizontalAnchor> { get set }
    var center: AssociatedAnchor<CenterAnchor> { get set }
    var width: AssociatedAnchor<WidthAnchor> { get set }
    var height: AssociatedAnchor<HeightAnchor> { get set }
    var size: AssociatedAnchor<SizeAnchor> { get set }
    var origin: AssociatedAnchor<OriginAnchor> { get set }
}
extension RectAnchorDefining {
    // TODO: Bad implementation. Undefined behavior
    fileprivate var constraints: Zip2Sequence<[LayoutItem?], [[RectBasedConstraint]]> {
        var items: [LayoutItem] = []
        var constraints: [[RectBasedConstraint]] = []
        var anonymConstraints: [RectBasedConstraint] = []
        func index(of item: LayoutItem) -> Int {
            guard let index = items.index(where: { $0 === item }) else {
                defer { items.append(item) }
                return items.count
            }
            return index
        }
        func add(_ constraint: RectBasedConstraint, by index: Int) {
            if index < constraints.count {
                constraints[index] += [constraint]
            } else {
                constraints.append([constraint])
            }
        }
        let addition: (LayoutItem?, RectBasedConstraint) -> Void = { item, constrt in item.map { add(constrt, by: index(of: $0)) } ?? anonymConstraints.append(constrt) }

        // TODO: Unexpected priority
        origin.constraints.forEach(addition)
        size.constraints.forEach(addition)
        width.constraints.forEach(addition)
        height.constraints.forEach(addition)
        center.constraints.forEach(addition) // TODO: center.horizontal, center.vertical
        left.constraints.forEach(addition)
        right.constraints.forEach(addition)
        top.constraints.forEach(addition)
        bottom.constraints.forEach(addition)

        return anonymConstraints.isEmpty ? zip(items, constraints) : zip([nil] + items, [anonymConstraints] + constraints)
    }
}
public protocol AnchoredItem {
    var anchors: RectAnchorDefining { get }
}
public struct AssociatedAnchor<Anchor: AnyRectAnchor> {
    weak var item: LayoutItem!
    public let anchor: Anchor

    init(item: LayoutItem?, anchor: Anchor) {
        self.item = item
        self.anchor = anchor
    }

    fileprivate var constraints: [(LayoutItem?, RectBasedConstraint)] = []
}
extension UIView: AnchoredItem {
    private static var anchors: Anchors = Anchors(nil)
    public var anchors: RectAnchorDefining { return UIView.anchors.with(self) }
    public struct Anchors: RectAnchorDefining {
        var view: UIView? {
            didSet {
                if let view = view {
                    bind(view)
                }
            }
        }
        init(_ view: UIView?) {
            self.view = view
            if let view = view {
                self.bind(view)
            }
        }
        public var left: AssociatedAnchor<LeftAnchor> = .init(item: nil, anchor: .init())
        public var right: AssociatedAnchor<RightAnchor> = .init(item: nil, anchor: .init())
        public var bottom: AssociatedAnchor<VerticalAnchor> = .init(item: nil, anchor: .init(BottomAnchor()))
        public var top: AssociatedAnchor<VerticalAnchor> = .init(item: nil, anchor: .init(TopAnchor()))
        public var leading: AssociatedAnchor<HorizontalAnchor> = .init(item: nil, anchor: .init(LeftAnchor()))
        public var trailing: AssociatedAnchor<HorizontalAnchor> = .init(item: nil, anchor: .init(RightAnchor()))
        public var center: AssociatedAnchor<CenterAnchor> = .init(item: nil, anchor: .init())
        public var width: AssociatedAnchor<WidthAnchor> = .init(item: nil, anchor: .width)
        public var height: AssociatedAnchor<HeightAnchor> = .init(item: nil, anchor: .height)
        public var size: AssociatedAnchor<SizeAnchor> = .init(item: nil, anchor: .init())
        public var origin: AssociatedAnchor<OriginAnchor> = .init(item: nil, anchor: .init(horizontalAnchor: .init(LeftAnchor()), verticalAnchor: .init(TopAnchor())))

        mutating func loadTrailingLeading() {
            guard let view = view else { return }
            let left: AssociatedAnchor<HorizontalAnchor> = .init(item: nil, anchor: .init(LeftAnchor()))
            let right: AssociatedAnchor<HorizontalAnchor> = .init(item: nil, anchor: .init(RightAnchor()))
            leading = UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft ? right : left
            trailing = UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft ? left : right
        }

        func with(_ view: UIView) -> Anchors {
            var anchors = self
            anchors.view = view
            return anchors
        }
        private mutating func bind(_ view: UIView) {
            left.item = view
            right.item = view
            bottom.item = view
            top.item = view
            loadTrailingLeading()
            center.item = view
            width.item = view
            height.item = view
            size.item = view
            origin.item = view
        }
    }
}
public struct AxisAnchorPointConstraint: RectBasedConstraint {
    let constrain: (inout CGRect, CGRect) -> Void
    public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        constrain(&sourceRect, rect)
    }
}
extension AxisAnchorPointConstraint {
    public static func align<A1: RectAnchorPoint, A2: RectAnchorPoint>(_ a1: A1, by a2: A2) -> AxisAnchorPointConstraint
        where A1.Metric == A2.Metric, A1.Axis == A2.Axis {
        return AxisAnchorPointConstraint { a1.offset(rect: &$0, by: a2.get(for: $1)) }
    }
    // TODO: Limit
    public static func pull<A1: RectAnchorPoint, A2: RectAnchorPoint>(_ a1: A1, to a2: A2) -> AxisAnchorPointConstraint
        where A1.Metric == A2.Metric, A1.Axis == A2.Axis {
        return AxisAnchorPointConstraint { a1.move(in: &$0, to: a2.get(for: $1)) }
    }
}
extension LayoutItem {
    public func anchorPointConstraint(for anchors: [AxisAnchorPointConstraint]) -> LayoutConstraint {
        return LayoutConstraint(item: self, constraints: anchors)
    }
    public func anchorSizeConstraint(for anchors: [AnchorSizeConstraint]) -> LayoutConstraint {
        return LayoutConstraint(item: self, constraints: anchors)
    }
}
extension RectAnchorPoint {
    public func align<A2: RectAnchorPoint>(by a2: A2) -> AxisAnchorPointConstraint
        where Metric == A2.Metric, Axis == A2.Axis {
        return AxisAnchorPointConstraint { self.offset(rect: &$0, by: a2.get(for: $1)) }
    }
    public func pull<A2: RectAnchorPoint>(to a2: A2) -> AxisAnchorPointConstraint
        where Metric == A2.Metric, Axis == A2.Axis {
            return AxisAnchorPointConstraint { self.move(in: &$0, to: a2.get(for: $1)) }
    }
}
extension AssociatedAnchor where Anchor: RectAnchorPoint {
    public mutating func align<A2: RectAnchorPoint>(by a2: AssociatedAnchor<A2>)
        where Anchor.Metric == A2.Metric, Anchor.Axis == A2.Axis {
            constraints.append((a2.item, anchor.align(by: a2.anchor)))
    }
    public mutating func pull<A2: RectAnchorPoint>(to a2: AssociatedAnchor<A2>)
        where Anchor.Metric == A2.Metric, Anchor.Axis == A2.Axis {
            constraints.append((a2.item, anchor.pull(to: a2.anchor)))
    }
}
public struct AnchorSizeConstraint: RectBasedConstraint {
    let constrain: (inout CGRect, CGRect) -> Void
    public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        constrain(&sourceRect, rect)
    }
}
extension AnchorSizeConstraint {
    public static func equal<A1: SizeRectAnchor, A2: SizeRectAnchor>(_ a1: A1, to a2: A2) -> AnchorSizeConstraint
        where A1.Metric == A2.Metric {
        return AnchorSizeConstraint { a1.set(a2.get(for: $1), for: &$0) }
    }
    public static func equal<A1: SizeRectAnchor & AxisLayoutEntity, A2: SizeRectAnchor & AxisLayoutEntity>(_ a1: A1, to a2: A2) -> AnchorSizeConstraint
        where A1.Metric == A2.Metric, A1.Axis == A2.Axis {
        return AnchorSizeConstraint { a1.set(a2.get(for: $1), for: &$0) }
    }
    public static func boxed<A1: SizeRectAnchor, A2: SizeRectAnchor>(_ a1: A1, by a2: A2, box: CGFloat) -> AnchorSizeConstraint
        where A1.Metric == A2.Metric, A1.Metric == CGSize {
        return AnchorSizeConstraint { a1.set(a2.get(for: $1) - box, for: &$0) }
    }
    public static func boxed<A1: SizeRectAnchor & AxisLayoutEntity, A2: SizeRectAnchor & AxisLayoutEntity>(_ a1: A1, by a2: A2, box: CGFloat) -> AnchorSizeConstraint
        where A1.Metric == A2.Metric, A1.Axis == A2.Axis, A1.Metric == CGFloat {
        return AnchorSizeConstraint { a1.set(a2.get(for: $1) - box, for: &$0) }
    }
    public static func scaled<A1: SizeRectAnchor, A2: SizeRectAnchor>(_ a1: A1, by a2: A2, scale: CGFloat) -> AnchorSizeConstraint
        where A1.Metric == A2.Metric, A1.Metric == CGSize {
        return AnchorSizeConstraint { a1.set(a2.get(for: $1) * scale, for: &$0) }
    }
    public static func boxed<A1: SizeRectAnchor & AxisLayoutEntity, A2: SizeRectAnchor & AxisLayoutEntity>(_ a1: A1, by a2: A2, scale: CGFloat) -> AnchorSizeConstraint
        where A1.Metric == A2.Metric, A1.Axis == A2.Axis, A1.Metric == CGFloat {
        return AnchorSizeConstraint { a1.set(a2.get(for: $1) * scale, for: &$0) }
    }
}
extension SizeRectAnchor {
    public func equal<A2: SizeRectAnchor>(to a2: A2) -> AnchorSizeConstraint
        where Metric == A2.Metric {
            return AnchorSizeConstraint { self.set(a2.get(for: $1), for: &$0) }
    }
    public func equal(to value: Metric) -> AnchorSizeConstraint {
        return AnchorSizeConstraint { source, _ in self.set(value, for: &source) }
    }
    public func boxed<A2: SizeRectAnchor>(by a2: A2, box: CGFloat) -> AnchorSizeConstraint
        where Metric == A2.Metric, Metric == CGSize {
            return AnchorSizeConstraint { self.set(a2.get(for: $1) - box, for: &$0) }
    }
    public func scaled<A2: SizeRectAnchor>(by a2: A2, scale: CGFloat) -> AnchorSizeConstraint
        where Metric == A2.Metric, Metric == CGSize {
            return AnchorSizeConstraint { self.set(a2.get(for: $1) * scale, for: &$0) }
    }
}
extension SizeRectAnchor where Self: AxisLayoutEntity {
    public func equal<A2: SizeRectAnchor & AxisLayoutEntity>(to a2: A2) -> AnchorSizeConstraint
        where Metric == A2.Metric, Axis == A2.Axis {
            return AnchorSizeConstraint { self.set(a2.get(for: $1), for: &$0) }
    }
    public func boxed<A2: SizeRectAnchor & AxisLayoutEntity>(by a2: A2, box: CGFloat) -> AnchorSizeConstraint
        where Metric == A2.Metric, Axis == A2.Axis, Metric == CGFloat {
            return AnchorSizeConstraint { self.set(a2.get(for: $1) - box, for: &$0) }
    }
    public func scaled<A2: SizeRectAnchor & AxisLayoutEntity>(by a2: A2, scale: CGFloat) -> AnchorSizeConstraint
        where Metric == A2.Metric, Axis == A2.Axis, Metric == CGFloat {
            return AnchorSizeConstraint { self.set(a2.get(for: $1) * scale, for: &$0) }
    }
}
extension AssociatedAnchor where Anchor: SizeRectAnchor {
    public mutating func equal<A2: SizeRectAnchor>(to a2: AssociatedAnchor<A2>)
        where Anchor.Metric == A2.Metric {
            constraints.append((a2.item, anchor.equal(to: a2.anchor)))
    }
    public mutating func equal(to value: Anchor.Metric) {
            constraints.append((nil, anchor.equal(to: value)))
    }
    public mutating func boxed<A2: SizeRectAnchor>(by a2: AssociatedAnchor<A2>, box: CGFloat)
        where Anchor.Metric == A2.Metric, Anchor.Metric == CGSize {
            constraints.append((a2.item, anchor.boxed(by: a2.anchor, box: box)))
    }
    public mutating func scaled<A2: SizeRectAnchor>(by a2: AssociatedAnchor<A2>, scale: CGFloat)
        where Anchor.Metric == A2.Metric, Anchor.Metric == CGSize {
            constraints.append((a2.item, anchor.scaled(by: a2.anchor, scale: scale)))
    }
}
extension AssociatedAnchor where Anchor: SizeRectAnchor, Anchor: AxisLayoutEntity {
    public mutating func equal<A2: SizeRectAnchor & AxisLayoutEntity>(to a2: AssociatedAnchor<A2>)
        where Anchor.Metric == A2.Metric, Anchor.Axis == A2.Axis {
            constraints.append((a2.item, anchor.equal(to: a2.anchor)))
    }
    public mutating func boxed<A2: SizeRectAnchor & AxisLayoutEntity>(by a2: AssociatedAnchor<A2>, box: CGFloat)
        where Anchor.Metric == A2.Metric, Anchor.Axis == A2.Axis, Anchor.Metric == CGFloat {
            constraints.append((a2.item, anchor.boxed(by: a2.anchor, box: box)))
    }
    public mutating func scaled<A2: SizeRectAnchor & AxisLayoutEntity>(by a2: AssociatedAnchor<A2>, scale: CGFloat)
        where Anchor.Metric == A2.Metric, Anchor.Axis == A2.Axis, Anchor.Metric == CGFloat {
            constraints.append((a2.item, anchor.scaled(by: a2.anchor, scale: scale)))
    }
}
extension LayoutItem where Self: AnchoredItem {
    public func layout(with relating: (inout RectAnchorDefining) -> Void) -> LayoutBlock<Self> {
        var anchors = self.anchors
        relating(&anchors)
        return LayoutBlock(item: self, layout: Layout.equal, constraints: anchors.constraints.map { item, constraints -> LayoutConstraintProtocol in
            return item.map { LayoutConstraint(item: $0, constraints: constraints) } ?? AnonymConstraint(anchors: constraints)
        })
//        return layoutBlock(with: Layout.equal, constraints: anchors.constraints)
    }
}

public protocol AnyRectAnchor {
    associatedtype Metric
//    func set(_ value: Metric, for rect: inout CGRect)
    func get(for rect: CGRect) -> Metric
}
public protocol RectAnchorPoint: AnyRectAnchor, AxisLayoutEntity {
    func offset(rect: inout CGRect, by value: Metric)
    func move(in rect: inout CGRect, to value: Metric)
}
public protocol SizeRectAnchor: AnyRectAnchor {
    func set(_ value: Metric, for rect: inout CGRect)
}
extension SizeRectAnchor where Metric == CGFloat {
//    public func box(rect: inout CGRect, by value: CGFloat) { set(get(for: rect) - value, for: &rect) }
//    public func scale(in rect: inout CGRect, to value: CGFloat) { set(get(for: rect) * value, for: &rect) }
}
extension SizeRectAnchor where Metric == CGSize {
    public func set(_ value: CGSize, for rect: inout CGRect) { rect.size = value }
    public func get(for rect: CGRect) -> CGSize { return rect.size }
//    public func box(_ value: CGFloat, by box: CGFloat, for rect: inout CGRect) { set(get(for: rect) - value, for: &rect) }
//    public func scale(_ value: CGFloat, by scale: CGFloat, in rect: inout CGRect) { set(get(for: rect) * value, for: &rect) }
}

public struct AxisCenterAnchor<Axis: RectAxis>: RectAnchorPoint {
    static var horizontal: AxisCenterAnchor<_RectAxis.Horizontal> { return .init(axis: .init()) }
    static var vertical: AxisCenterAnchor<_RectAxis.Vertical> { return .init(axis: .init()) }

    public let axis: Axis
    public func offset(rect: inout CGRect, by value: CGFloat) { axis.offset(midOf: &rect, to: value) }
    public func move(in rect: inout CGRect, to value: CGFloat) { axis.move(midOf: &rect, to: value) }
    public func get(for rect: CGRect) -> CGFloat { return axis.get(midOf: rect) }
}
public struct BottomAnchor: RectAnchorPoint {
    public let axis = _RectAxis.vertical
    public func offset(rect: inout CGRect, by value: CGFloat) { axis.offset(maxOf: &rect, to: value) }
    public func move(in rect: inout CGRect, to value: CGFloat) { axis.move(maxOf: &rect, to: value) }
    public func get(for rect: CGRect) -> CGFloat { return axis.get(maxOf: rect) }
}
public struct RightAnchor: RectAnchorPoint {
    public let axis = _RectAxis.horizontal
    public func offset(rect: inout CGRect, by value: CGFloat) { axis.offset(maxOf: &rect, to: value) }
    public func move(in rect: inout CGRect, to value: CGFloat) { axis.move(maxOf: &rect, to: value) }
    public func get(for rect: CGRect) -> CGFloat { return axis.get(maxOf: rect) }
}
public typealias WidthAnchor = AxisSizeAnchor<_RectAxis.Horizontal>
public typealias HeightAnchor = AxisSizeAnchor<_RectAxis.Vertical>
public struct AxisSizeAnchor<Axis: RectAxis>: AxisLayoutEntity, SizeRectAnchor {
    static var width: WidthAnchor { return .init(axis: .init()) }
    static var height: HeightAnchor { return .init(axis: .init()) }

    public let axis: Axis
    public func set(_ value: CGFloat, for rect: inout CGRect) { axis.set(size: value, for: &rect) }
    public func get(for rect: CGRect) -> CGFloat { return axis.get(sizeAt: rect) }
}
public struct TopAnchor: RectAnchorPoint {
    public let axis = _RectAxis.vertical
    public func offset(rect: inout CGRect, by value: CGFloat) { axis.offset(minOf: &rect, to: value) }
    public func move(in rect: inout CGRect, to value: CGFloat) { axis.move(minOf: &rect, to: value) }
    public func get(for rect: CGRect) -> CGFloat { return axis.get(minOf: rect) }
}
public struct LeftAnchor: RectAnchorPoint {
    public let axis = _RectAxis.horizontal
    public func offset(rect: inout CGRect, by value: CGFloat) { axis.offset(minOf: &rect, to: value) }
    public func move(in rect: inout CGRect, to value: CGFloat) { axis.move(minOf: &rect, to: value) }
    public func get(for rect: CGRect) -> CGFloat { return axis.get(minOf: rect) }
}
public typealias HorizontalAnchor = AnyAxisAnchorPoint<_RectAxis.Horizontal>
public typealias VerticalAnchor = AnyAxisAnchorPoint<_RectAxis.Vertical>
public struct AnyAxisAnchorPoint<Axis: RectAxis>: RectAnchorPoint {
    let offset: (inout CGRect, CGFloat) -> Void
    let move: (inout CGRect, CGFloat) -> Void
    let get: (CGRect) -> CGFloat
    public let axis: Axis

    init<T: RectAnchorPoint & AxisLayoutEntity>(_ base: T) where Axis == T.Axis, T.Metric == Metric {
        self.axis = base.axis
        self.offset = base.offset(rect:by:)
        self.move = base.move(in:to:)
        self.get = base.get(for:)
    }

    public func offset(rect: inout CGRect, by value: CGFloat) { offset(&rect, value) }
    public func move(in rect: inout CGRect, to value: CGFloat) { move(&rect, value) }
    public func get(for rect: CGRect) -> CGFloat { return get(rect) }
}
public struct CenterAnchor: RectAnchorPoint {
    public let axis = _RectAxis.xy
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
public struct OriginAnchor: RectAnchorPoint {
    public let axis = _RectAxis.xy
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

    public func get(for rect: CGRect) -> CGPoint { return CGPoint(x: horizontalAnchor.get(for: rect), y: verticalAnchor.get(for: rect)) }
}
public struct SizeAnchor: SizeRectAnchor {
    public typealias Metric = CGSize
}

public protocol RectAxis { // TODO: Add associatedtype Metric, 
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
    func move(maxOf rect: inout CGRect, to newMax: CGFloat) { set(size: max(0, newMax - get(minOf: rect)), for: &rect) }
}
extension RectAxis {
    func transverse() -> RectAxis { return self is _RectAxis.Horizontal ? _RectAxis.vertical : _RectAxis.horizontal }
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

    public static var xy: _RectAxis.XY = .init()
    public struct XY: RectAxis {
        let x = _RectAxis.horizontal
        let y = _RectAxis.vertical

        public func set(size: CGFloat, for rect: inout CGRect) { x.set(size: size, for: &rect); y.set(size: size, for: &rect) }
        public func set(origin: CGFloat, for rect: inout CGRect) { x.set(origin: origin, for: &rect); y.set(origin: origin, for: &rect) }
        public func get(originAt rect: CGRect) -> CGFloat { return rect.origin.x }
        public func get(sizeAt rect: CGRect) -> CGFloat { return rect.width }
        public func get(maxOf rect: CGRect) -> CGFloat { return rect.maxX }
        public func get(minOf rect: CGRect) -> CGFloat { return rect.minX }
        public func get(midOf rect: CGRect) -> CGFloat { return rect.midX }
        public func offset(rect: CGRect, by value: CGFloat) -> CGRect { return rect.offsetBy(dx: value, dy: value) }
    }

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
