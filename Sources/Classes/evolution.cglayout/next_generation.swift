//
//  CGLayoutPrivateEvolution.swift
//  CGLayout-iOS
//
//  Created by Denis Koryttsev on 07/10/2017.
//

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#elseif os(Linux)
import Foundation
#endif

#if os(macOS) || os(iOS) || os(tvOS)

@available(macOS 10.12, iOS 10.0, *)
public class LayoutManager<Item: LayoutElement>: NSObject {
    var deinitialization: (() -> Void)?
    weak var item: LayoutElement!
    var scheme: LayoutScheme!
    private var isNeedLayout: Bool = false

    public func setNeedsLayout() {
        if !isNeedLayout {
            isNeedLayout = true
            scheduleLayout()
        }
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard change != nil, item != nil else {
            return
        }
        scheduleLayout()
    }

    private func scheduleLayout() {
        RunLoop.current.perform {
            self.scheme.layout()
            self.isNeedLayout = false
        }
    }

    deinit {
        deinitialization?()
    }
}
#endif

#if os(iOS) || os(tvOS)
@available(iOS 10.0, *)
public extension LayoutManager where Item: UIView {
    convenience init(view: UIView, scheme: LayoutScheme) {
        self.init()
        self.item = view
        self.scheme = scheme
        self.deinitialization = { view.removeObserver(self, forKeyPath: "layer.bounds") }
        view.addObserver(self, forKeyPath: "layer.bounds", options: [], context: nil)
        scheme.layout()
    }
}

/// Base class with layout skeleton implementation.
open class AutolayoutViewController: UIViewController {
    fileprivate lazy var internalLayout: LayoutScheme = self.loadInternalLayout()
    public lazy internal(set) var layoutScheme: LayoutScheme = self.loadLayout()
    public lazy var freeAreaLayoutGuide = LayoutGuide<UIView>()

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.add(layoutGuide: freeAreaLayoutGuide)
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        internalLayout.layout()
        update(scheme: &layoutScheme)
        layout()
    }

    open func layout() {
        layoutScheme.layout()
    }

    open func update(scheme: inout LayoutScheme) {
        /// subclass override
        /// use for update dynamic elements
    }

    open func loadLayout() -> LayoutScheme {
        /// subclass override
        /// layout = LayoutScheme(blocks: [LayoutBlockProtocol])
        fatalError("You should override loading layout method")
    }

    fileprivate func loadInternalLayout() -> LayoutScheme {
        let visible: (inout CGRect) -> Void = { [unowned self] rect in
            if #available(iOS 11.0, tvOS 11.0, *) {
                rect = rect.inset(by: self.view.safeAreaInsets)
            } else {
                rect = rect.inset(by: self.viewContentInsets)
            }
        }
        return LayoutScheme(
            blocks: [freeAreaLayoutGuide.layoutBlock(constraints: [AnonymConstraint(transform: visible)])]
        )
    }

    @available(iOS 9.0, *)
    private var viewContentInsets: UIEdgeInsets {
        let bars = heightBars
        return UIEdgeInsets(top: bars.top,
                            left: 0,
                            bottom: bars.bottom,
                            right: 0)
    }

    @available(iOS 9.0, *)
    private var heightBars: (top: CGFloat, bottom: CGFloat) {
        guard let window = UIApplication.shared.delegate.flatMap({ $0.window }).flatMap({ $0 }), let superview = viewIfLoaded?.superview else {
            return (UIApplication.shared.statusBarFrame.height + (navigationController.map { $0.isNavigationBarHidden ? 0 : $0.navigationBar.frame.height } ?? 0),
                    tabBarController.map { $0.tabBar.isHidden ? 0 : $0.tabBar.frame.height } ?? 0)
        }

        var topFrame = window.convert(UIApplication.shared.statusBarFrame, to: superview)
        topFrame = topFrame.union(navigationController.map { contr -> CGRect in
            contr.isNavigationBarHidden ?
                .zero :
                superview.convert(contr.navigationBar.frame, from: contr.navigationBar.superview)
            } ?? .zero)

        let bottomBarsTop = tabBarController.map { contr -> CGPoint in
            contr.tabBar.isHidden ?
                .zero :
                superview.convert(contr.tabBar.frame.origin, from: contr.tabBar.superview)
        }

        return (max(0, topFrame.maxY - view.frame.origin.y),
                max(0, bottomBarsTop.map { $0.y - view.frame.maxY } ?? 0))
    }
}

open class ScrollLayoutViewController: AutolayoutViewController {
    private var isNeedCalculateContent: Bool = true
    public var scrollView: UIScrollView! { return view as? UIScrollView }
    var isScrolling: Bool { return scrollView.isDragging || scrollView.isDecelerating || scrollView.isZooming }

    open override func viewDidLayoutSubviews() {
        if isNeedCalculateContent || !isScrolling {
            internalLayout.layout()
            update(scheme: &layoutScheme)
            layout()
            isNeedCalculateContent = false
        }
    }

    open override func layout() {
        super.layout()
        let contentRect = layoutScheme.currentRect
        scrollView.contentSize = CGSize(width: contentRect.maxX, height: contentRect.maxY)
    }

    public func setNeedsUpdateContentSize() {
        isNeedCalculateContent = true
        view.setNeedsLayout()
    }
}
#endif

// MARK: Layout

public protocol AxisLayoutEntity {
    associatedtype Axis: RectAxis
    var axis: Axis { get }
}

extension RectAnchorPoint {
    public func align<A2: RectAnchorPoint>(by a2: A2) -> AnyRectBasedConstraint
        where Metric == A2.Metric, Axis == A2.Axis {
        return AnyRectBasedConstraint { self.offset(rect: &$0, by: a2.get(for: $1)) }
    }
    public func alignLimit<A2: RectAnchorPoint>(to a2: A2, compare: @escaping (Metric, Metric) -> Metric) -> AnyRectBasedConstraint
        where Metric == A2.Metric, Axis == A2.Axis {
            return AnyRectBasedConstraint {
                let current = self.get(for: $0)
                let limited = a2.get(for: $1)
                if compare(current, limited) != current {
                    self.offset(rect: &$0, by: limited)
                }
            }
    }
    public func pull<A2: RectAnchorPoint>(to a2: A2) -> AnyRectBasedConstraint
        where Metric == A2.Metric, Axis == A2.Axis {
            return AnyRectBasedConstraint { self.move(in: &$0, to: a2.get(for: $1)) }
    }
    public func limit<A2: RectAnchorPoint>(to a2: A2, compare: @escaping (Metric, Metric) -> Metric) -> AnyRectBasedConstraint
        where Metric == A2.Metric, Axis == A2.Axis {
            return AnyRectBasedConstraint {
                let current = self.get(for: $0)
                let limited = a2.get(for: $1)
                if compare(current, limited) != current {
                    self.move(in: &$0, to: limited)
                }
            }
    }
}
extension SizeRectAnchor {
    public func equal<A2: SizeRectAnchor>(to a2: A2) -> AnyRectBasedConstraint
        where Metric == A2.Metric {
            return AnyRectBasedConstraint { self.set(a2.get(for: $1), for: &$0) }
    }
    public func equal(to value: Metric) -> AnyRectBasedConstraint {
        return AnyRectBasedConstraint { source, _ in self.set(value, for: &source) }
    }
    public func boxed<A2: SizeRectAnchor>(by a2: A2, box: CGFloat) -> AnyRectBasedConstraint
        where Metric == A2.Metric, Metric == CGSize {
            return AnyRectBasedConstraint { self.set(a2.get(for: $1) - box, for: &$0) }
    }
    public func scaled<A2: SizeRectAnchor>(by a2: A2, scale: CGFloat) -> AnyRectBasedConstraint
        where Metric == A2.Metric, Metric == CGSize {
            return AnyRectBasedConstraint { self.set(a2.get(for: $1) * scale, for: &$0) }
    }
}
extension SizeRectAnchor where Self: AxisLayoutEntity {
    public func equal<A2: SizeRectAnchor & AxisLayoutEntity>(to a2: A2) -> AnyRectBasedConstraint
        where Metric == A2.Metric, Axis == A2.Axis {
            return AnyRectBasedConstraint { self.set(a2.get(for: $1), for: &$0) }
    }
    public func boxed<A2: SizeRectAnchor & AxisLayoutEntity>(by a2: A2, box: CGFloat) -> AnyRectBasedConstraint
        where Metric == A2.Metric, Axis == A2.Axis, Metric == CGFloat {
            return AnyRectBasedConstraint { self.set(a2.get(for: $1) - box, for: &$0) }
    }
    public func scaled<A2: SizeRectAnchor & AxisLayoutEntity>(by a2: A2, scale: CGFloat) -> AnyRectBasedConstraint
        where Metric == A2.Metric, Axis == A2.Axis, Metric == CGFloat {
            return AnyRectBasedConstraint { self.set(a2.get(for: $1) * scale, for: &$0) }
    }
}

public protocol AnyRectAnchor {
    associatedtype Metric: Equatable
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
extension SizeRectAnchor where Metric == CGFloat {}
extension SizeRectAnchor where Metric == CGSize {
    public func set(_ value: CGSize, for rect: inout CGRect) { rect.size = value }
    public func get(for rect: CGRect) -> CGSize { return rect.size }
}

public typealias CenterXAnchor = AxisCenterAnchor<CGRectAxis.Horizontal>
public typealias CenterYAnchor = AxisCenterAnchor<CGRectAxis.Vertical>
public struct AxisCenterAnchor<Axis: RectAxis>: RectAnchorPoint {
    static var horizontal: AxisCenterAnchor<CGRectAxis.Horizontal> { return .init(axis: .init()) }
    static var vertical: AxisCenterAnchor<CGRectAxis.Vertical> { return .init(axis: .init()) }

    public let axis: Axis
    public func offset(rect: inout CGRect, by value: CGFloat) { axis.offset(midOf: &rect, to: value) }
    public func move(in rect: inout CGRect, to value: CGFloat) { axis.move(midOf: &rect, to: value) }
    public func get(for rect: CGRect) -> CGFloat { return axis.get(midOf: rect) }
}
public struct BottomAnchor: RectAnchorPoint {
    public let axis = CGRectAxis.vertical
    public func offset(rect: inout CGRect, by value: CGFloat) { axis.offset(maxOf: &rect, to: value) }
    public func move(in rect: inout CGRect, to value: CGFloat) { axis.move(maxOf: &rect, to: value) }
    public func get(for rect: CGRect) -> CGFloat { return axis.get(maxOf: rect) }
}
public struct RightAnchor: RectAnchorPoint {
    public let axis = CGRectAxis.horizontal
    public func offset(rect: inout CGRect, by value: CGFloat) { axis.offset(maxOf: &rect, to: value) }
    public func move(in rect: inout CGRect, to value: CGFloat) { axis.move(maxOf: &rect, to: value) }
    public func get(for rect: CGRect) -> CGFloat { return axis.get(maxOf: rect) }
}
public typealias WidthAnchor = AxisSizeAnchor<CGRectAxis.Horizontal>
public typealias HeightAnchor = AxisSizeAnchor<CGRectAxis.Vertical>
public struct AxisSizeAnchor<Axis: RectAxis>: AxisLayoutEntity, SizeRectAnchor {
    static var width: WidthAnchor { return .init(axis: .init()) }
    static var height: HeightAnchor { return .init(axis: .init()) }

    public let axis: Axis
    public func set(_ value: CGFloat, for rect: inout CGRect) { axis.set(size: value, for: &rect) }
    public func get(for rect: CGRect) -> CGFloat { return axis.get(sizeAt: rect) }
}
public struct TopAnchor: RectAnchorPoint {
    public let axis = CGRectAxis.vertical
    public func offset(rect: inout CGRect, by value: CGFloat) { axis.offset(minOf: &rect, to: value) }
    public func move(in rect: inout CGRect, to value: CGFloat) { axis.move(minOf: &rect, to: value) }
    public func get(for rect: CGRect) -> CGFloat { return axis.get(minOf: rect) }
}
public struct LeftAnchor: RectAnchorPoint {
    public let axis = CGRectAxis.horizontal
    public func offset(rect: inout CGRect, by value: CGFloat) { axis.offset(minOf: &rect, to: value) }
    public func move(in rect: inout CGRect, to value: CGFloat) { axis.move(minOf: &rect, to: value) }
    public func get(for rect: CGRect) -> CGFloat { return axis.get(minOf: rect) }
}
public typealias HorizontalAnchor = AnyAxisAnchorPoint<CGRectAxis.Horizontal>
public typealias VerticalAnchor = AnyAxisAnchorPoint<CGRectAxis.Vertical>
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
    public let axis = CGRectAxis.xy
    public var horizontal: AxisCenterAnchor<CGRectAxis.Horizontal> { return .horizontal }
    public var vertical: AxisCenterAnchor<CGRectAxis.Vertical> { return .vertical }
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
    public let axis = CGRectAxis.xy
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
    var isHorizontal: Bool { get }
    var isVertical: Bool { get }
    func transverse() -> RectAxis
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
    public func transverse() -> RectAxis { return isHorizontal ? CGRectAxis.vertical : CGRectAxis.horizontal }
}

public struct CGRectAxis: RectAxis {
    let base: RectAxis

    public var isHorizontal: Bool { return base.isHorizontal }
    public var isVertical: Bool { return base.isVertical }
    public func set(size: CGFloat, for rect: inout CGRect) { base.set(size: size, for: &rect) }
    public func set(origin: CGFloat, for rect: inout CGRect) { base.set(origin: origin, for: &rect) }
    public func get(originAt rect: CGRect) -> CGFloat { return base.get(originAt: rect) }
    public func get(sizeAt rect: CGRect) -> CGFloat { return base.get(sizeAt: rect) }
    public func get(maxOf rect: CGRect) -> CGFloat { return base.get(maxOf: rect) }
    public func get(minOf rect: CGRect) -> CGFloat { return base.get(minOf: rect) }
    public func get(midOf rect: CGRect) -> CGFloat { return base.get(midOf: rect) }
    public func offset(rect: CGRect, by value: CGFloat) -> CGRect { return base.offset(rect: rect, by: value) }

    public static var xy: CGRectAxis.XY = .init()
    /// not completed
    public struct XY: RectAxis { // TODO:
        let x = CGRectAxis.horizontal
        let y = CGRectAxis.vertical

        public var isHorizontal: Bool { return true }
        public var isVertical: Bool { return true }
        public func transverse() -> RectAxis { return self }
        public func set(size: CGFloat, for rect: inout CGRect) { x.set(size: size, for: &rect); y.set(size: size, for: &rect) }
        public func set(origin: CGFloat, for rect: inout CGRect) { x.set(origin: origin, for: &rect); y.set(origin: origin, for: &rect) }
        public func get(originAt rect: CGRect) -> CGFloat { return rect.origin.x }
        public func get(sizeAt rect: CGRect) -> CGFloat { return rect.width }
        public func get(maxOf rect: CGRect) -> CGFloat { return rect.maxX }
        public func get(minOf rect: CGRect) -> CGFloat { return rect.minX }
        public func get(midOf rect: CGRect) -> CGFloat { return rect.midX }
        public func offset(rect: CGRect, by value: CGFloat) -> CGRect { return rect.offsetBy(dx: value, dy: value) }
    }

    public static var horizontal: CGRectAxis.Horizontal = Horizontal()
    public struct Horizontal: RectAxis {
        public var isHorizontal: Bool { return true }
        public var isVertical: Bool { return false }
        public func set(size: CGFloat, for rect: inout CGRect) { rect.size.width = size }
        public func set(origin: CGFloat, for rect: inout CGRect) { rect.origin.x = origin }
        public func get(originAt rect: CGRect) -> CGFloat { return rect.origin.x }
        public func get(sizeAt rect: CGRect) -> CGFloat { return rect.width }
        public func get(maxOf rect: CGRect) -> CGFloat { return rect.maxX }
        public func get(minOf rect: CGRect) -> CGFloat { return rect.minX }
        public func get(midOf rect: CGRect) -> CGFloat { return rect.midX }
        public func offset(rect: CGRect, by value: CGFloat) -> CGRect { return rect.offsetBy(dx: value, dy: 0) }
    }

    public static var vertical: CGRectAxis.Vertical = Vertical()
    public struct Vertical: RectAxis {
        public var isHorizontal: Bool { return false }
        public var isVertical: Bool { return true }
        public func set(size: CGFloat, for rect: inout CGRect) { rect.size.height = size }
        public func set(origin: CGFloat, for rect: inout CGRect) { rect.origin.y = origin }
        public func get(sizeAt rect: CGRect) -> CGFloat { return rect.height }
        public func get(originAt rect: CGRect) -> CGFloat { return rect.origin.y }
        public func get(maxOf rect: CGRect) -> CGFloat { return rect.maxY }
        public func get(minOf rect: CGRect) -> CGFloat { return rect.minY }
        public func get(midOf rect: CGRect) -> CGFloat { return rect.midY }
        public func offset(rect: CGRect, by value: CGFloat) -> CGRect { return rect.offsetBy(dx: 0, dy: value) }
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
    static var leadingHorizontal = AnyAnchor<CGFloat>(getter: CGRectAxis.horizontal.get(minOf:))
    static var trailingHorizontal = AnyAnchor<CGFloat>(getter: CGRectAxis.horizontal.get(maxOf:))
    static var leadingVertical = AnyAnchor<CGFloat>(getter: CGRectAxis.vertical.get(minOf:))
    static var trailingVertical = AnyAnchor<CGFloat>(getter: CGRectAxis.vertical.get(maxOf:))
    static var centerHorizontal = AnyAnchor<CGFloat>(getter: CGRectAxis.horizontal.get(midOf:))
    static var centerVertical = AnyAnchor<CGFloat>(getter: CGRectAxis.vertical.get(midOf:))
    static var center = AnyAnchor<CGPoint>(getter: { CGPoint(x: CGRectAxis.horizontal.get(midOf: $0), y: CGRectAxis.vertical.get(midOf: $0)) })
    static var sizeHorizontal = AnyAnchor<CGFloat>(getter: CGRectAxis.horizontal.get(sizeAt:))
    static var sizeVertical = AnyAnchor<CGFloat>(getter: CGRectAxis.vertical.get(sizeAt:))
    static var size = AnyAnchor<CGSize>(getter: { $0.size })//CGSize(width: CGRectAxis.horizontal.get(sizeAt: $0), height: CGRectAxis.vertical.get(sizeAt: $0)) })
}
struct AnyAnchor<Metric: Equatable>: AnyRectAnchor /*, OptionSet*/ {
    fileprivate let getter: (CGRect) -> Metric
    //    fileprivate let setter: (Metric, inout CGRect)
    //    func set(value: Metric, for rect: inout CGRect) { setter(value, &rect) }
    func get(for rect: CGRect) -> Metric { return getter(rect) }
}

public protocol RectAxisAnchor {
    //    func set(value: CGFloat, for rect: inout CGRect, in axis: RectAxis)
    func get(for rect: CGRect, in axis: RectAxis) -> CGFloat
}
public struct CGRectAxisAnchor {
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
    public static var size: RectAxisAnchor = Size()
    struct Size: RectAxisAnchor {
        func get(for rect: CGRect, in axis: RectAxis) -> CGFloat {
            return axis.get(sizeAt: rect)
        }
    }
}
