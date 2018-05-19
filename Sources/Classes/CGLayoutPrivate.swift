//
//  CGLayoutPrivate.swift
//  CGLayout-iOS
//
//  Created by Denis Koryttsev on 07/10/2017.
//

import Foundation
#if os(Linux)
import Dispatch
#endif

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
        guard Thread.isMainThread else {
            DispatchQueue.main.sync { sourceRect.size = item.sizeThatFits(rect.size) }
            return
        }
        sourceRect.size = item.sizeThatFits(rect.size)
    }
}

internal struct _MainThreadItemInLayoutTime<Item: LayoutItem>: InLayoutTimeItem {
    var superLayoutBounds: CGRect {
        if Thread.isMainThread { return item.superItem!.layoutBounds }
        var _bounds: CGRect?
        DispatchQueue.main.sync { _bounds = item.superItem!.layoutBounds }
        return _bounds!
    }
    weak var superItem: LayoutItem? {
        if Thread.isMainThread { return item.superItem }
        var _super: LayoutItem?
        DispatchQueue.main.sync { _super = item.superItem }
        return _super
    }
    var frame: CGRect { set {}
        get {
            if Thread.isMainThread { return item.frame }
            var _frame: CGRect?
            DispatchQueue.main.sync { _frame = item.frame }
            return _frame!
        }
    }
    var bounds: CGRect { set {}
        get {
            if Thread.isMainThread { return item.bounds }
            var _bounds: CGRect?
            DispatchQueue.main.sync { _bounds = item.bounds }
            return _bounds!
        }
    }

    var item: Item
}
