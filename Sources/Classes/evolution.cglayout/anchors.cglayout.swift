//
//  anchors.cglayout.swift
//  CGLayout-iOS
//
//  Created by Denis Koryttsev on 02/06/2018.
//
//  API v.2

import Foundation

// not uses
protocol Anchors: class {
    associatedtype Element: AnchoredLayoutElement & LayoutElement
    var left: SideAnchor<Element, LeftAnchor> { get set }
    var right: SideAnchor<Element, RightAnchor> { get set }
    var leading: SideAnchor<Element, RTLAnchor> { get set }
    var trailing: SideAnchor<Element, RTLAnchor> { get set }
    var bottom: SideAnchor<Element, BottomAnchor> { get set }
    var top: SideAnchor<Element, TopAnchor> { get set }
    var centerX: SideAnchor<Element, CenterXAnchor> { get set }
    var centerY: SideAnchor<Element, CenterYAnchor> { get set }
    var width: DimensionAnchor<Element, WidthAnchor> { get set }
    var height: DimensionAnchor<Element, HeightAnchor> { get set }
}

public protocol AnchoredLayoutElement: LayoutElement {}
extension AnchoredLayoutElement {
    public var layoutAnchors: LayoutAnchors<Self> { return LayoutAnchors(self) }
}

extension LayoutElement where Self: AnchoredLayoutElement {
    public func layoutBlock(constraints: (LayoutAnchors<Self>) -> Void) -> LayoutBlock<Self> {
        return layoutBlock(with: .equal, constraints: constraints)
    }
    public func layoutBlock(with layout: Layout, constraints: (LayoutAnchors<Self>) -> Void) -> LayoutBlock<Self> {
        let anchors = self.layoutAnchors
        constraints(anchors)
        return LayoutBlock(element: self, layout: layout, constraints: anchors.constraints())
    }
}
extension LayoutGuide: AnchoredLayoutElement {}

public final class LayoutAnchors<V: AnchoredLayoutElement>: Anchors {
    weak var element: V!

    public init(_ element: V) {
        self.element = element
    }

    public lazy var left: SideAnchor<V, LeftAnchor> = .init(anchors: self, anchor: .init())
    public lazy var right: SideAnchor<V, RightAnchor> = .init(anchors: self, anchor: .init())
    public lazy var leading: SideAnchor<V, RTLAnchor> = .init(anchors: self, anchor: .init(trailing: false, rtlMode: CGLConfiguration.default.isRTLMode))
    public lazy var trailing: SideAnchor<V, RTLAnchor> = .init(anchors: self, anchor: .init(trailing: true, rtlMode: CGLConfiguration.default.isRTLMode))
    public lazy var bottom: SideAnchor<V, BottomAnchor> = .init(anchors: self, anchor: .init())
    public lazy var top: SideAnchor<V, TopAnchor> = .init(anchors: self, anchor: .init())
    public lazy var centerX: SideAnchor<V, CenterXAnchor> = .init(anchors: self, anchor: .init(axis: .init()))
    public lazy var centerY: SideAnchor<V, CenterYAnchor> = .init(anchors: self, anchor: .init(axis: .init()))
    public lazy var width: DimensionAnchor<V, WidthAnchor> = .init(anchors: self, anchor: .width)
    public lazy var height: DimensionAnchor<V, HeightAnchor> = .init(anchors: self, anchor: .height)
    var _baseline: SideConstraintsContainer?

    internal func constraints(builder constraint: (LayoutElement, [RectBasedConstraint]) -> LayoutConstraintProtocol = { LayoutConstraint(element: $0, constraints: $1) }) -> [LayoutConstraintProtocol] {
        var layoutConstraints: [LayoutConstraintProtocol] = []

        left.pullConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        right.pullConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        leading.pullConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        trailing.pullConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        bottom.pullConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        top.pullConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        centerX.pullConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        centerY.pullConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _baseline?.pullConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }

        _ = left.limitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = right.limitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = leading.limitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = trailing.limitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = bottom.limitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = top.limitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = centerX.limitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = centerY.limitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _baseline?.limitConstraints.forEach { layoutConstraints.append(constraint($0.0, [$0.1])) }

        width.anonymConstraint.map { layoutConstraints.append(AnonymConstraint(anchors: [$0])) }
        height.anonymConstraint.map { layoutConstraints.append(AnonymConstraint(anchors: [$0])) }
        width.associatedConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        height.associatedConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        width.contentConstraint.map { layoutConstraints.append($0) }
        height.contentConstraint.map { layoutConstraints.append($0) }

        left.alignConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        right.alignConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        leading.alignConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        trailing.alignConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        bottom.alignConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        top.alignConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        centerX.alignConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        centerY.alignConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _baseline?.alignConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }

        _ = left.alignLimitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = right.alignLimitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = leading.alignLimitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = trailing.alignLimitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = bottom.alignLimitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = top.alignLimitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = centerX.alignLimitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = centerY.alignLimitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _baseline?.alignLimitConstraints.forEach { layoutConstraints.append(constraint($0.0, [$0.1])) }

        return layoutConstraints
    }
}
public extension LayoutAnchors where V: TextPresentedElement, V.BaselineElement: AnchoredLayoutElement {
    var baseline: SideAnchor<V.BaselineElement, TopAnchor> {
        set { _baseline = newValue }
        get {
            guard case let baseline as SideAnchor<V.BaselineElement, TopAnchor> = _baseline else {
                let baselineAnchor = element.baselineElement.layoutAnchors.top
                _baseline = baselineAnchor
                return baselineAnchor
            }
            return baseline
        }
    }
}

protocol SideConstraintsContainer {
    var pullConstraint: (LayoutElement, AnyRectBasedConstraint)? { get }
    var limitConstraints: [(LayoutElement, AnyRectBasedConstraint)] { get }
    var alignConstraint: (LayoutElement, AnyRectBasedConstraint)? { get }
    var alignLimitConstraints: [(LayoutElement, AnyRectBasedConstraint)] { get }
}

public struct SideAnchor<Item: AnchoredLayoutElement, Anchor: RectAnchorPoint>: SideConstraintsContainer {
    unowned let anchors: LayoutAnchors<Item>
    unowned let item: Item
    let anchor: Anchor

    init(anchors: LayoutAnchors<Item>, anchor: Anchor) {
        self.anchors = anchors
        self.item = anchors.element
        self.anchor = anchor
    }

    var pullConstraint: (LayoutElement, AnyRectBasedConstraint)? = nil
    var limitConstraints: [(LayoutElement, AnyRectBasedConstraint)] = []
    var alignConstraint: (LayoutElement, AnyRectBasedConstraint)? = nil
    var alignLimitConstraints: [(LayoutElement, AnyRectBasedConstraint)] = []

    mutating func setAlign(_ constraint: (LayoutElement, AnyRectBasedConstraint)) {
        alignConstraint = constraint
    }
    mutating func setPull(_ constraint: (LayoutElement, AnyRectBasedConstraint)) {
        pullConstraint = constraint
    }
    mutating func addLimit(_ constraint: (LayoutElement, AnyRectBasedConstraint)) {
        limitConstraints.append(constraint)
    }
    mutating func addAlignLimit(_ constraint: (LayoutElement, AnyRectBasedConstraint)) {
        alignLimitConstraints.append(constraint)
    }
}

public struct DimensionAnchor<Item: AnchoredLayoutElement, Anchor: AxisLayoutEntity & SizeRectAnchor> {
    unowned let anchors: LayoutAnchors<Item>
    unowned let item: Item
    let anchor: Anchor

    init(anchors: LayoutAnchors<Item>, anchor: Anchor) {
        self.anchors = anchors
        self.item = anchors.element
        self.anchor = anchor
    }

    var contentConstraint: LayoutConstraintProtocol?
    var associatedConstraint: (LayoutElement, AnyRectBasedConstraint)?
    var anonymConstraint: AnyRectBasedConstraint?

    var isDefined: Bool {
        return contentConstraint != nil || associatedConstraint != nil || anonymConstraint != nil
    }
}

public extension SideAnchor {
    mutating func align<A: AnchoredLayoutElement, A2: RectAnchorPoint>(by a2: SideAnchor<A, A2>)
        where Anchor.Metric == A2.Metric, Anchor.Axis == A2.Axis {
            checkConflictsOnAddAlign()
            setAlign((a2.item, anchor.align(by: a2.anchor)))
    }
    mutating func pull<A: AnchoredLayoutElement, A2: RectAnchorPoint>(to a2: SideAnchor<A, A2>)
        where Anchor.Metric == A2.Metric, Anchor.Axis == A2.Axis {
            checkConflictsOnAddPull()
            setPull((a2.item, anchor.pull(to: a2.anchor)))
    }
    fileprivate func checkConflictsOnAddAlign() {
        debugAction {
            // print(pullConstraint != nil, limitConstraints.count > 1, alignConstraint != nil)
            if pullConstraint != nil {
                debugWarning("We already have pull constraint, that makes align")
            } else if limitConstraints.count > 1 {
                debugWarning("We already have limit constraints. If you need align just remove limit constraints")
            } else if alignConstraint != nil {
                debugWarning("We already have align constraint. It will be replaced")
            }
        }
    }
    fileprivate func checkConflictsOnAddPull() {
        debugAction {
            let hasSize = (anchors.width.isDefined && anchor.axis.isHorizontal) ||
                (anchors.height.isDefined && anchor.axis.isVertical)
            // print(pullConstraint != nil, alignConstraint != nil, hasSize)
            if alignConstraint != nil {
                debugWarning("We already have align constraint. If you need pull just remove align constraint")
            } else if limitConstraints.count > 1 {
                // printWarning("We already have limit constraints. If you need pull just remove limit constraints")
            } else if pullConstraint != nil {
                debugWarning("We already have pull constraint. It will be replaced")
            } else if hasSize {
                debugWarning("We already define size anchor in this axis. We can get unexpected result")
            }
        }
    }
    fileprivate func checkConflictsOnAddLimit() {
        debugAction {
            // print(alignConstraint != nil)
            if alignConstraint != nil {
                debugWarning("We already have align constraint. Limit constraints can broken align behavior")
            }
        }
    }
    fileprivate func checkConflictsOnAddAlignLimit() {
        debugAction {
            // print(alignConstraint != nil)
            if pullConstraint != nil {
                debugWarning("We already have pull constraint. We can get unexpected result")
            } else if limitConstraints.count > 1 {
                debugWarning("We already have limit constraints. We can get unexpected result")
            }
        }
    }
}
public extension SideAnchor where Anchor == RTLAnchor {
    private var _limitFunc: (Anchor.Metric, Anchor.Metric) -> Anchor.Metric {
        if CGLConfiguration.default.isRTLMode {
            return anchor.isTrailing ? min : max
        } else {
            return anchor.isTrailing ? max : min
        }
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, RTLAnchor>) {
        checkConflictsOnAddLimit()
        addLimit((a2.item, anchor.limit(to: a2.anchor, compare: _limitFunc)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, LeftAnchor>) {
        checkConflictsOnAddLimit()
        addLimit((a2.item, anchor.limit(to: a2.anchor, compare: _limitFunc)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, RightAnchor>) {
        checkConflictsOnAddLimit()
        addLimit((a2.item, anchor.limit(to: a2.anchor, compare: _limitFunc)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, CenterXAnchor>) {
        checkConflictsOnAddLimit()
        addLimit((a2.item, anchor.limit(to: a2.anchor, compare: _limitFunc)))
    }
    mutating func fartherThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, RTLAnchor>) {
        checkConflictsOnAddAlignLimit()
        addLimit((a2.item, anchor.alignLimit(to: a2.anchor, compare: _limitFunc)))
    }
    mutating func fartherThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, LeftAnchor>) {
        checkConflictsOnAddAlignLimit()
        addLimit((a2.item, anchor.alignLimit(to: a2.anchor, compare: _limitFunc)))
    }
    mutating func fartherThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, RightAnchor>) {
        checkConflictsOnAddAlignLimit()
        addLimit((a2.item, anchor.alignLimit(to: a2.anchor, compare: _limitFunc)))
    }
    mutating func fartherThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, CenterXAnchor>) {
        checkConflictsOnAddAlignLimit()
        addLimit((a2.item, anchor.alignLimit(to: a2.anchor, compare: _limitFunc)))
    }
}
public extension SideAnchor where Anchor == LeftAnchor {
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, RTLAnchor>) {
        checkConflictsOnAddLimit()
        addLimit((a2.item, anchor.limit(to: a2.anchor, compare: max)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, LeftAnchor>) {
        checkConflictsOnAddLimit()
        addLimit((a2.item, anchor.limit(to: a2.anchor, compare: max)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, RightAnchor>) {
        checkConflictsOnAddLimit()
        addLimit((a2.item, anchor.limit(to: a2.anchor, compare: max)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, CenterXAnchor>) {
        checkConflictsOnAddLimit()
        addLimit((a2.item, anchor.limit(to: a2.anchor, compare: max)))
    }
    mutating func fartherThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, RTLAnchor>) {
        checkConflictsOnAddAlignLimit()
        addLimit((a2.item, anchor.alignLimit(to: a2.anchor, compare: max)))
    }
    mutating func fartherThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, LeftAnchor>) {
        checkConflictsOnAddAlignLimit()
        addLimit((a2.item, anchor.alignLimit(to: a2.anchor, compare: max)))
    }
    mutating func fartherThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, RightAnchor>) {
        checkConflictsOnAddAlignLimit()
        addLimit((a2.item, anchor.alignLimit(to: a2.anchor, compare: max)))
    }
    mutating func fartherThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, CenterXAnchor>) {
        checkConflictsOnAddAlignLimit()
        addLimit((a2.item, anchor.alignLimit(to: a2.anchor, compare: max)))
    }
}
public extension SideAnchor where Anchor == RightAnchor {
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, RTLAnchor>) {
        checkConflictsOnAddLimit()
        addLimit((a2.item, anchor.limit(to: a2.anchor, compare: min)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, LeftAnchor>) {
        checkConflictsOnAddLimit()
        addLimit((a2.item, anchor.limit(to: a2.anchor, compare: min)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, RightAnchor>) {
        checkConflictsOnAddLimit()
        addLimit((a2.item, anchor.limit(to: a2.anchor, compare: min)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, CenterXAnchor>) {
        checkConflictsOnAddLimit()
        addLimit((a2.item, anchor.limit(to: a2.anchor, compare: min)))
    }
    mutating func nearerThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, RTLAnchor>) {
        checkConflictsOnAddAlignLimit()
        addLimit((a2.item, anchor.alignLimit(to: a2.anchor, compare: min)))
    }
    mutating func nearerThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, LeftAnchor>) {
        checkConflictsOnAddAlignLimit()
        addLimit((a2.item, anchor.alignLimit(to: a2.anchor, compare: min)))
    }
    mutating func nearerThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, RightAnchor>) {
        checkConflictsOnAddAlignLimit()
        addLimit((a2.item, anchor.alignLimit(to: a2.anchor, compare: min)))
    }
    mutating func nearerThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, CenterXAnchor>) {
        checkConflictsOnAddAlignLimit()
        addLimit((a2.item, anchor.alignLimit(to: a2.anchor, compare: min)))
    }
}
public extension SideAnchor where Anchor == TopAnchor {
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, TopAnchor>) {
        checkConflictsOnAddLimit()
        addLimit((a2.item, anchor.limit(to: a2.anchor, compare: max)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, BottomAnchor>) {
        checkConflictsOnAddLimit()
        addLimit((a2.item, anchor.limit(to: a2.anchor, compare: max)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, CenterYAnchor>) {
        checkConflictsOnAddLimit()
        addLimit((a2.item, anchor.limit(to: a2.anchor, compare: max)))
    }
    mutating func fartherThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, TopAnchor>) {
        checkConflictsOnAddAlignLimit()
        addLimit((a2.item, anchor.alignLimit(to: a2.anchor, compare: max)))
    }
    mutating func fartherThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, BottomAnchor>) {
        checkConflictsOnAddAlignLimit()
        addLimit((a2.item, anchor.alignLimit(to: a2.anchor, compare: max)))
    }
    mutating func fartherThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, CenterYAnchor>) {
        checkConflictsOnAddAlignLimit()
        addLimit((a2.item, anchor.alignLimit(to: a2.anchor, compare: max)))
    }
}
public extension SideAnchor where Anchor == BottomAnchor {
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, TopAnchor>) {
        checkConflictsOnAddLimit()
        addLimit((a2.item, anchor.limit(to: a2.anchor, compare: min)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, BottomAnchor>) {
        checkConflictsOnAddLimit()
        addLimit((a2.item, anchor.limit(to: a2.anchor, compare: min)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, CenterYAnchor>) {
        checkConflictsOnAddLimit()
        addLimit((a2.item, anchor.limit(to: a2.anchor, compare: min)))
    }
    mutating func nearerThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, TopAnchor>) {
        checkConflictsOnAddAlignLimit()
        addLimit((a2.item, anchor.alignLimit(to: a2.anchor, compare: min)))
    }
    mutating func nearerThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, BottomAnchor>) {
        checkConflictsOnAddAlignLimit()
        addLimit((a2.item, anchor.alignLimit(to: a2.anchor, compare: min)))
    }
    mutating func nearerThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, CenterYAnchor>) {
        checkConflictsOnAddAlignLimit()
        addLimit((a2.item, anchor.alignLimit(to: a2.anchor, compare: min)))
    }
}
public extension DimensionAnchor {
    fileprivate func checkConflictsOnAddContentConstraint() {
        debugAction {
            let hasPull = ((anchors.left.pullConstraint != nil || anchors.right.pullConstraint != nil) && anchor.axis.isHorizontal) ||
                        ((anchors.bottom.pullConstraint != nil || anchors.top.pullConstraint != nil) && anchor.axis.isVertical)
            // print(contentConstraint != nil, anonymConstraint != nil, associatedConstraint != nil, hasPull)
            if contentConstraint != nil {
                debugWarning("We already have content constraint. It will be replaced")
            } else if anonymConstraint != nil {
                debugWarning("We already have value for anchor. We can get unexpected result")
            } else if associatedConstraint != nil {
                debugWarning("We already have associated constraint. We can get unexpected result")
            } else if hasPull {
                debugWarning("We already have pull constraint in the same axis. We can get unexpected result")
            }
        }
    }
    fileprivate func checkConflictsOnAddAnonymConstraint() {
        debugAction {
            let hasPull = ((anchors.left.pullConstraint != nil || anchors.right.pullConstraint != nil) && anchor.axis.isHorizontal) ||
                        ((anchors.bottom.pullConstraint != nil || anchors.top.pullConstraint != nil) && anchor.axis.isVertical)
            // print(contentConstraint != nil, anonymConstraint != nil, associatedConstraint != nil, hasPull)
            if contentConstraint != nil {
                debugWarning("We already have content constraint. We can get unexpected result")
            } else if anonymConstraint != nil {
                debugWarning("We already have value for anchor. It will be replaced")
            } else if associatedConstraint != nil {
                debugWarning("We already have associated constraint. We can get unexpected result")
            } else if hasPull {
                debugWarning("We already have pull constraint in the same axis. We can get unexpected result")
            }
        }
    }
    fileprivate func checkConflictsOnAddEqualConstraint() {
        debugAction {
            let hasPull = ((anchors.left.pullConstraint != nil || anchors.right.pullConstraint != nil) && anchor.axis.isHorizontal) ||
                        ((anchors.bottom.pullConstraint != nil || anchors.top.pullConstraint != nil) && anchor.axis.isVertical)
            // print(contentConstraint != nil, anonymConstraint != nil, associatedConstraint != nil, hasPull)
            if contentConstraint != nil {
                debugWarning("We already have content constraint. We can get unexpected result")
            } else if anonymConstraint != nil {
                debugWarning("We already have value for anchor. We can get unexpected result")
            } else if associatedConstraint != nil {
                debugWarning("We already have associated constraint. It will be replaced")
            } else if hasPull {
                debugWarning("We already have pull constraint in the same axis. We can get unexpected result")
            }
        }
    }
}
public extension DimensionAnchor {
    mutating func equal<LI: AnchoredLayoutElement, A2: SizeRectAnchor>(to a2: DimensionAnchor<LI, A2>)
        where Anchor.Metric == A2.Metric {
            checkConflictsOnAddEqualConstraint()
            associatedConstraint = (a2.item, anchor.equal(to: a2.anchor))
    }
    mutating func equal(to value: Anchor.Metric) {
        checkConflictsOnAddAnonymConstraint()
        anonymConstraint = anchor.equal(to: value)
    }
    mutating func boxed<LI: AnchoredLayoutElement, A2: SizeRectAnchor>(by a2: DimensionAnchor<LI, A2>, box: CGFloat)
        where Anchor.Metric == A2.Metric, Anchor.Metric == CGSize {
            checkConflictsOnAddEqualConstraint()
            associatedConstraint = (a2.item, anchor.boxed(by: a2.anchor, box: box))
    }
    mutating func scaled<LI: AnchoredLayoutElement, A2: SizeRectAnchor>(by a2: DimensionAnchor<LI, A2>, scale: CGFloat)
        where Anchor.Metric == A2.Metric, Anchor.Metric == CGSize {
            checkConflictsOnAddEqualConstraint()
            associatedConstraint = (a2.item, anchor.scaled(by: a2.anchor, scale: scale))
    }
}
// TODO: scaled, boxed to equal with parameters multiplier, constant
public extension DimensionAnchor where Anchor: AxisLayoutEntity {
    mutating func equal<LI: AnchoredLayoutElement, A2: SizeRectAnchor & AxisLayoutEntity>(to a2: DimensionAnchor<LI, A2>)
        where Anchor.Metric == A2.Metric, Anchor.Axis == A2.Axis {
            checkConflictsOnAddEqualConstraint()
            associatedConstraint = (a2.item, anchor.equal(to: a2.anchor))
    }
    mutating func boxed<LI: AnchoredLayoutElement, A2: SizeRectAnchor & AxisLayoutEntity>(by a2: DimensionAnchor<LI, A2>, box: CGFloat)
        where Anchor.Metric == A2.Metric, Anchor.Axis == A2.Axis, Anchor.Metric == CGFloat {
            checkConflictsOnAddEqualConstraint()
            associatedConstraint = (a2.item, anchor.boxed(by: a2.anchor, box: box))
    }
    mutating func scaled<LI: AnchoredLayoutElement, A2: SizeRectAnchor & AxisLayoutEntity>(by a2: DimensionAnchor<LI, A2>, scale: CGFloat)
        where Anchor.Metric == A2.Metric, Anchor.Axis == A2.Axis, Anchor.Metric == CGFloat {
            checkConflictsOnAddEqualConstraint()
            associatedConstraint = (a2.item, anchor.scaled(by: a2.anchor, scale: scale))
    }
}
public extension DimensionAnchor where Item: AdjustableLayoutElement, Anchor == WidthAnchor {
    mutating func equalIntrinsicSize(_ multiplier: CGFloat = 1, alignment: Layout.Alignment = .equal) {
        checkConflictsOnAddContentConstraint()
        contentConstraint = anchors.element.adjustLayoutConstraint(for: [.width(multiplier)], alignment: alignment)
    }
}
public extension DimensionAnchor where Item: AdjustableLayoutElement, Anchor == HeightAnchor {
    mutating func equalIntrinsicSize(_ multiplier: CGFloat = 1, alignment: Layout.Alignment = .equal) {
        checkConflictsOnAddContentConstraint()
        contentConstraint = anchors.element.adjustLayoutConstraint(for: [.height(multiplier)], alignment: alignment)
    }
}
