//
//  anchors.cglayout.swift
//  CGLayout-iOS
//
//  Created by Denis Koryttsev on 02/06/2018.
//
//  API v.2

import Foundation

protocol Anchors: class {
    associatedtype Item: AnchoredLayoutElement & LayoutElement
    var left: SideAnchor<Item, LeftAnchor> { get set }
    var right: SideAnchor<Item, RightAnchor> { get set }
    var bottom: SideAnchor<Item, BottomAnchor> { get set }
    var top: SideAnchor<Item, TopAnchor> { get set }
    var centerX: SideAnchor<Item, CenterXAnchor> { get set }
    var centerY: SideAnchor<Item, CenterYAnchor> { get set }
    var width: DimensionAnchor<Item, WidthAnchor> { get set }
    var height: DimensionAnchor<Item, HeightAnchor> { get set }
}

public protocol AnchoredLayoutElement: LayoutElement {
    associatedtype Item: AnchoredLayoutElement /// = Self
    var layoutAnchors: LayoutAnchors<Item> { get }
}

extension LayoutElement where Self: AnchoredLayoutElement {
    public func block(with layout: (inout LayoutAnchors<Self>) -> Void) -> LayoutBlock<Self> {
        return block(with: .equal, constrains: layout)
    }
    public func block(with layout: Layout, constrains: (inout LayoutAnchors<Self>) -> Void) -> LayoutBlock<Self> {
        var anchors = unsafeBitCast(self.layoutAnchors, to: LayoutAnchors<Self>.self)
        constrains(&anchors)
        return LayoutBlock(element: self, layout: layout, constraints: anchors.constraints())
    }
}

extension LayoutGuide: AnchoredLayoutElement {
    public var layoutAnchors: LayoutAnchors<LayoutGuide<Super>> { return LayoutAnchors(self) }
}

public class LayoutAnchors<V: AnchoredLayoutElement>: Anchors {
    weak var item: V!

    public init(_ item: V) {
        self.item = item
    }

    public lazy var left: SideAnchor<V, LeftAnchor> = .init(anchors: self, anchor: .init())
    public lazy var right: SideAnchor<V, RightAnchor> = .init(anchors: self, anchor: .init())
    public lazy var bottom: SideAnchor<V, BottomAnchor> = .init(anchors: self, anchor: .init())
    public lazy var top: SideAnchor<V, TopAnchor> = .init(anchors: self, anchor: .init())
    public lazy var centerX: SideAnchor<V, CenterXAnchor> = .init(anchors: self, anchor: .init(axis: .init()))
    public lazy var centerY: SideAnchor<V, CenterYAnchor> = .init(anchors: self, anchor: .init(axis: .init()))
    public lazy var width: DimensionAnchor<V, WidthAnchor> = .init(anchors: self, anchor: .width)
    public lazy var height: DimensionAnchor<V, HeightAnchor> = .init(anchors: self, anchor: .height)

    internal func constraints(builder constraint: (LayoutElement, [RectBasedConstraint]) -> LayoutConstraintProtocol = { LayoutConstraint(element: $0, constraints: $1) }) -> [LayoutConstraintProtocol] {
        var layoutConstraints: [LayoutConstraintProtocol] = []

        left.pullConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        right.pullConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        bottom.pullConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        top.pullConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        centerX.pullConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        centerY.pullConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }

        _ = left.limitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = right.limitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = bottom.limitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = top.limitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = centerX.limitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = centerY.limitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }

        width.anonymConstraint.map { layoutConstraints.append(AnonymConstraint(anchors: [$0])) }
        height.anonymConstraint.map { layoutConstraints.append(AnonymConstraint(anchors: [$0])) }
        width.associatedConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        height.associatedConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        width.contentConstraint.map { layoutConstraints.append($0) }
        height.contentConstraint.map { layoutConstraints.append($0) }

        left.alignConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        right.alignConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        bottom.alignConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        top.alignConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        centerX.alignConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        centerY.alignConstraint.map { layoutConstraints.append(constraint($0.0, [$0.1])) }

        _ = left.alignLimitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = right.alignLimitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = bottom.alignLimitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = top.alignLimitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = centerX.alignLimitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }
        _ = centerY.alignLimitConstraints.map { layoutConstraints.append(constraint($0.0, [$0.1])) }

        return layoutConstraints
    }
}

public struct SideAnchor<Item: AnchoredLayoutElement, Anchor: RectAnchorPoint> {
    unowned var anchors: LayoutAnchors<Item>
    unowned var item: Item
    let anchor: Anchor

    init(anchors: LayoutAnchors<Item>, anchor: Anchor) {
        self.anchors = anchors
        self.item = anchors.item
        self.anchor = anchor
    }

    var pullConstraint: (LayoutElement, AnyRectBasedConstraint)? = nil
    var limitConstraints: [(LayoutElement, AnyRectBasedConstraint)] = []
    var alignConstraint: (LayoutElement, AnyRectBasedConstraint)? = nil
    var alignLimitConstraints: [(LayoutElement, AnyRectBasedConstraint)] = []
}

public struct DimensionAnchor<Item: AnchoredLayoutElement, Anchor: AxisLayoutEntity & SizeRectAnchor> {
    unowned var anchors: LayoutAnchors<Item>
    unowned var item: Item
    let anchor: Anchor

    init(anchors: LayoutAnchors<Item>, anchor: Anchor) {
        self.anchors = anchors
        self.item = anchors.item
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
            debugAction {
                // print(pullConstraint != nil, limitConstraints.count > 1, alignConstraint != nil)
                if pullConstraint != nil {
                    print("We already have pull constraint, that makes align")
                } else if limitConstraints.count > 1 {
                    print("We already have limit constraints. If you need align just remove limit constraints")
                } else if alignConstraint != nil {
                    print("We already have align constraint. It will be replaced")
                }
            }

            alignConstraint = (a2.item, anchor.align(by: a2.anchor))
    }
    mutating func pull<A: AnchoredLayoutElement, A2: RectAnchorPoint>(to a2: SideAnchor<A, A2>)
        where Anchor.Metric == A2.Metric, Anchor.Axis == A2.Axis {
            debugAction {
                let hasSize = (anchors.width.isDefined && anchor.axis.isHorizontal) ||
                        	  (anchors.height.isDefined && anchor.axis.isVertical)
                // print(pullConstraint != nil, alignConstraint != nil, hasSize)
                if alignConstraint != nil {
                    print("We already have align constraint. If you need pull just remove align constraint")
                } else if limitConstraints.count > 1 {
                    // printWarning("We already have limit constraints. If you need pull just remove limit constraints")
                } else if pullConstraint != nil {
                    print("We already have pull constraint. It will be replaced")
                } else if hasSize {
                    print("We already define size anchor in this axis. We can get unexpected result")
                }
            }
            pullConstraint = (a2.item, anchor.pull(to: a2.anchor))
    }
    fileprivate func checkConflictsOnAddLimit() {
        debugAction {
            // print(alignConstraint != nil)
            if alignConstraint != nil {
                print("We already have align constraint. Limit constraints can broken align behavior")
            }
        }
    }
    fileprivate func checkConflictsOnAddAlignLimit() {
        debugAction {
            // print(alignConstraint != nil)
            if pullConstraint != nil {
                print("We already have pull constraint. We can get unexpected result")
            } else if limitConstraints.count > 1 {
                print("We already have limit constraints. We can get unexpected result")
            }
        }
    }
}
public extension SideAnchor where Anchor == LeftAnchor {
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, LeftAnchor>) {
        checkConflictsOnAddLimit()
        limitConstraints.append((a2.item, anchor.limit(to: a2.anchor, compare: max)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, RightAnchor>) {
        checkConflictsOnAddLimit()
        limitConstraints.append((a2.item, anchor.limit(to: a2.anchor, compare: max)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, CenterXAnchor>) {
        checkConflictsOnAddLimit()
        limitConstraints.append((a2.item, anchor.limit(to: a2.anchor, compare: max)))
    }
    mutating func fartherThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, LeftAnchor>) {
        checkConflictsOnAddAlignLimit()
        limitConstraints.append((a2.item, anchor.alignLimit(to: a2.anchor, compare: max)))
    }
    mutating func fartherThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, RightAnchor>) {
        checkConflictsOnAddAlignLimit()
        limitConstraints.append((a2.item, anchor.alignLimit(to: a2.anchor, compare: max)))
    }
    mutating func fartherThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, CenterXAnchor>) {
        checkConflictsOnAddAlignLimit()
        limitConstraints.append((a2.item, anchor.alignLimit(to: a2.anchor, compare: max)))
    }
}
public extension SideAnchor where Anchor == RightAnchor {
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, LeftAnchor>) {
        checkConflictsOnAddLimit()
        limitConstraints.append((a2.item, anchor.limit(to: a2.anchor, compare: min)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, RightAnchor>) {
        checkConflictsOnAddLimit()
        limitConstraints.append((a2.item, anchor.limit(to: a2.anchor, compare: min)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, CenterXAnchor>) {
        checkConflictsOnAddLimit()
        limitConstraints.append((a2.item, anchor.limit(to: a2.anchor, compare: min)))
    }
    mutating func nearerThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, LeftAnchor>) {
        checkConflictsOnAddAlignLimit()
        limitConstraints.append((a2.item, anchor.alignLimit(to: a2.anchor, compare: min)))
    }
    mutating func nearerThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, RightAnchor>) {
        checkConflictsOnAddAlignLimit()
        limitConstraints.append((a2.item, anchor.alignLimit(to: a2.anchor, compare: min)))
    }
    mutating func nearerThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, CenterXAnchor>) {
        checkConflictsOnAddAlignLimit()
        limitConstraints.append((a2.item, anchor.alignLimit(to: a2.anchor, compare: min)))
    }
}
public extension SideAnchor where Anchor == TopAnchor {
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, TopAnchor>) {
        checkConflictsOnAddLimit()
        limitConstraints.append((a2.item, anchor.limit(to: a2.anchor, compare: max)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, BottomAnchor>) {
        checkConflictsOnAddLimit()
        limitConstraints.append((a2.item, anchor.limit(to: a2.anchor, compare: max)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, CenterYAnchor>) {
        checkConflictsOnAddLimit()
        limitConstraints.append((a2.item, anchor.limit(to: a2.anchor, compare: max)))
    }
    mutating func fartherThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, TopAnchor>) {
        checkConflictsOnAddAlignLimit()
        limitConstraints.append((a2.item, anchor.alignLimit(to: a2.anchor, compare: max)))
    }
    mutating func fartherThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, BottomAnchor>) {
        checkConflictsOnAddAlignLimit()
        limitConstraints.append((a2.item, anchor.alignLimit(to: a2.anchor, compare: max)))
    }
    mutating func fartherThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, CenterYAnchor>) {
        checkConflictsOnAddAlignLimit()
        limitConstraints.append((a2.item, anchor.alignLimit(to: a2.anchor, compare: max)))
    }
}
public extension SideAnchor where Anchor == BottomAnchor {
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, TopAnchor>) {
        checkConflictsOnAddLimit()
        limitConstraints.append((a2.item, anchor.limit(to: a2.anchor, compare: min)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, BottomAnchor>) {
        checkConflictsOnAddLimit()
        limitConstraints.append((a2.item, anchor.limit(to: a2.anchor, compare: min)))
    }
    mutating func limit<A: AnchoredLayoutElement>(by a2: SideAnchor<A, CenterYAnchor>) {
        checkConflictsOnAddLimit()
        limitConstraints.append((a2.item, anchor.limit(to: a2.anchor, compare: min)))
    }
    mutating func nearerThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, TopAnchor>) {
        checkConflictsOnAddAlignLimit()
        limitConstraints.append((a2.item, anchor.alignLimit(to: a2.anchor, compare: min)))
    }
    mutating func nearerThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, BottomAnchor>) {
        checkConflictsOnAddAlignLimit()
        limitConstraints.append((a2.item, anchor.alignLimit(to: a2.anchor, compare: min)))
    }
    mutating func nearerThanOrEqual<A: AnchoredLayoutElement>(to a2: SideAnchor<A, CenterYAnchor>) {
        checkConflictsOnAddAlignLimit()
        limitConstraints.append((a2.item, anchor.alignLimit(to: a2.anchor, compare: min)))
    }
}
public extension DimensionAnchor {
    fileprivate func checkConflictsOnAddContentConstraint() {
        debugAction {
            let hasPull = ((anchors.left.pullConstraint != nil || anchors.right.pullConstraint != nil) && anchor.axis.isHorizontal) ||
                        ((anchors.bottom.pullConstraint != nil || anchors.top.pullConstraint != nil) && anchor.axis.isVertical)
            // print(contentConstraint != nil, anonymConstraint != nil, associatedConstraint != nil, hasPull)
            if contentConstraint != nil {
                print("We already have content constraint. It will be replaced")
            } else if anonymConstraint != nil {
                print("We already have value for anchor. We can get unexpected result")
            } else if associatedConstraint != nil {
                print("We already have associated constraint. We can get unexpected result")
            } else if hasPull {
                print("We already have pull constraint in the same axis. We can get unexpected result")
            }
        }
    }
    fileprivate func checkConflictsOnAddAnonymConstraint() {
        debugAction {
            let hasPull = ((anchors.left.pullConstraint != nil || anchors.right.pullConstraint != nil) && anchor.axis.isHorizontal) ||
                        ((anchors.bottom.pullConstraint != nil || anchors.top.pullConstraint != nil) && anchor.axis.isVertical)
            // print(contentConstraint != nil, anonymConstraint != nil, associatedConstraint != nil, hasPull)
            if contentConstraint != nil {
                print("We already have content constraint. We can get unexpected result")
            } else if anonymConstraint != nil {
                print("We already have value for anchor. It will be replaced")
            } else if associatedConstraint != nil {
                print("We already have associated constraint. We can get unexpected result")
            } else if hasPull {
                print("We already have pull constraint in the same axis. We can get unexpected result")
            }
        }
    }
    fileprivate func checkConflictsOnAddEqualConstraint() {
        debugAction {
            let hasPull = ((anchors.left.pullConstraint != nil || anchors.right.pullConstraint != nil) && anchor.axis.isHorizontal) ||
                        ((anchors.bottom.pullConstraint != nil || anchors.top.pullConstraint != nil) && anchor.axis.isVertical)
            // print(contentConstraint != nil, anonymConstraint != nil, associatedConstraint != nil, hasPull)
            if contentConstraint != nil {
                print("We already have content constraint. We can get unexpected result")
            } else if anonymConstraint != nil {
                print("We already have value for anchor. We can get unexpected result")
            } else if associatedConstraint != nil {
                print("We already have associated constraint. It will be replaced")
            } else if hasPull {
                print("We already have pull constraint in the same axis. We can get unexpected result")
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
    mutating func equalIntrinsicSize(_ multiplier: CGFloat = 1) {
        checkConflictsOnAddContentConstraint()
        contentConstraint = anchors.item.adjustLayoutConstraint(for: [.width(multiplier)])
    }
}
public extension DimensionAnchor where Item: AdjustableLayoutElement, Anchor == HeightAnchor {
    mutating func equalIntrinsicSize(_ multiplier: CGFloat = 1) {
        checkConflictsOnAddContentConstraint()
        contentConstraint = anchors.item.adjustLayoutConstraint(for: [.height(multiplier)])
    }
}
