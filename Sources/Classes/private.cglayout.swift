//
//  CGLayoutPrivate.swift
//  CGLayout
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
    let frame: CGRect
}

internal struct _SizeThatFitsConstraint: RectBasedConstraint {
    weak var item: AdaptiveLayoutElement!
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        sourceRect.size = item.sizeThatFits(rect.size)
    }
}
internal struct _MainThreadSizeThatFitsConstraint: RectBasedConstraint {
    weak var item: AdaptiveLayoutElement!
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        sourceRect.size = syncGuard(mainThread: item.sizeThatFits(rect.size))
    }
}

internal struct _MainThreadItemInLayoutTime<Item: LayoutElement>: ElementInLayoutTime {
    var layoutBounds: CGRect { return syncGuard(mainThread: { item.layoutBounds }) }
    var superLayoutBounds: CGRect { return syncGuard(mainThread: { item.superElement!.layoutBounds }) }
    weak var superElement: LayoutElement? { return syncGuard(mainThread: { item.superElement }) }
    var frame: CGRect {
        set {
            let item = self.item
            syncGuard { item.frame = newValue }()
        }
        get { return syncGuard { item.frame } }
    }
    var bounds: CGRect {
        set {
            let item = self.item
            syncGuard { item.bounds = newValue }()
        }
        get { return syncGuard { item.bounds } }
    }

    var item: Item
}
