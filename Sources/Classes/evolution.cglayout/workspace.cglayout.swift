//
//  workspace.cglayout.swift
//  Pods
//
//  Created by Denis Koryttsev on 12/10/2019.
//

import Foundation

protocol RectAxisAnchor {
    //    func set(value: CGFloat, for rect: inout CGRect, in axis: RectAxis)
    func get(for rect: CGRect, in axis: RectAxis) -> CGFloat
}
struct CGRectAxisAnchor {
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

struct LayoutWorkspace {
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
