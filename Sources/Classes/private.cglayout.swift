//
//  CGLayoutPrivate.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 07/10/2017.
//

import Foundation

// MARK: Protocols

internal protocol AxisEntity {
    var axis: RectAxis { get }
    func by(axis: RectAxis) -> Self
}
internal protocol RectAxisLayout: RectBasedLayout, AxisEntity {}

// MARK: Implementations

internal struct ConstraintsAggregator: RectBasedConstraint {
    let constraints: [RectBasedConstraint]

    init(_ constraints: [RectBasedConstraint]) {
        self.constraints = constraints
    }

    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        constraints.forEach { $0.formConstrain(sourceRect: &sourceRect, by: rect) }
    }
}

/// Represents frame of block where was received. Contains snapshots for child blocks.
internal struct LayoutSnapshot: LayoutSnapshotProtocol {
    let childSnapshots: [LayoutSnapshotProtocol]
    let snapshotFrame: CGRect
}

internal struct _SizeThatFitsConstraint: RectBasedConstraint {
    weak var item: SelfSizedLayoutItem!
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        sourceRect.size = item.sizeThatFits(rect.size)
    }
}
internal struct _MainThreadSizeThatFitsConstraint: RectBasedConstraint {
    weak var item: SelfSizedLayoutItem!
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        sourceRect.size = syncGuard(mainThread: item.sizeThatFits(rect.size))
    }
}

internal struct _MainThreadItemInLayoutTime<Item: LayoutItem>: InLayoutTimeItem {
    var layoutBounds: CGRect { return syncGuard(mainThread: { item.layoutBounds }) }
    var superLayoutBounds: CGRect { return syncGuard(mainThread: { item.superItem!.layoutBounds }) }
    weak var superItem: LayoutItem? { return syncGuard(mainThread: { item.superItem }) }
    var frame: CGRect {
        set { syncGuard { item.frame = newValue } }
        get { return syncGuard { item.frame } }
    }
    var bounds: CGRect {
        set { syncGuard { item.bounds = newValue } }
        get { return syncGuard { item.bounds } }
    }

    var item: Item
}
