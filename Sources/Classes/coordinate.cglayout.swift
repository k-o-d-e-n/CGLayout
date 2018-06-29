//
//  MultiCoordinateSpace.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 08/09/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#elseif os(Linux)
import Foundation
#endif

// MARK: LayoutCoordinateSpace

/// Common protocol for anyone `LayoutElement`.
/// Used for multi-converting coordinates between `LayoutElement` items.
/// Converting between UIView and CALayer has low performance in comparison converting with same type.
/// Therefore should UIView.layer property when creates constraint relationship between UIView and CALayer.
public protocol LayoutCoordinateSpace {
    func convert(point: CGPoint, to item: LayoutElement) -> CGPoint
    func convert(point: CGPoint, from item: LayoutElement) -> CGPoint
    func convert(rect: CGRect, to item: LayoutElement) -> CGRect
    func convert(rect: CGRect, from item: LayoutElement) -> CGRect

    var bounds: CGRect { get }
    var frame: CGRect { get }
}
#if os(iOS) || os(tvOS)
extension LayoutCoordinateSpace where Self: UICoordinateSpace, Self: LayoutElement {
    public func convert(point: CGPoint, to element: LayoutElement) -> CGPoint {
        guard !(element is UICoordinateSpace) else { return syncGuard(mainThread: { convert(point, to: element as! UICoordinateSpace) }) }

        return Self.convert(point: point, from: self, to: element)
    }
    public func convert(point: CGPoint, from element: LayoutElement) -> CGPoint {
        guard !(element is UICoordinateSpace) else { return syncGuard(mainThread: { convert(point, from: element as! UICoordinateSpace) }) }

        return Self.convert(point: point, from: element, to: self)
    }
    public func convert(rect: CGRect, to element: LayoutElement) -> CGRect {
        guard !(element is UICoordinateSpace) else { return syncGuard(mainThread: { convert(rect, to: element as! UICoordinateSpace) }) }

        var rect = rect
        rect.origin = Self.convert(point: rect.origin, from: self, to: element)
        return rect
    }
    public func convert(rect: CGRect, from element: LayoutElement) -> CGRect {
        guard !(element is UICoordinateSpace) else { return syncGuard(mainThread: { convert(rect, from: element as! UICoordinateSpace) }) }

        var rect = rect
        rect.origin = Self.convert(point: rect.origin, from: element, to: self)
        return rect
    }
}
/// UIView.convert(_ point: CGPoint, to view: UIView?) faster than UICoordinateSpace.convert(_ point: CGPoint, to coordinateSpace: UICoordinateSpace)
/// Therefore makes extension for UIView.
extension LayoutCoordinateSpace where Self: UIView {
    public func convert(point: CGPoint, to element: LayoutElement) -> CGPoint {
        if let element = element as? UIView { return syncGuard(mainThread: { convert(point, to: element) }) }
        if let element = element as? CALayer { return syncGuard(mainThread: { layer.convert(point, to: element) }) }

        return Self.convert(point: point, from: self, to: element)
    }
    public func convert(point: CGPoint, from element: LayoutElement) -> CGPoint {
        if let element = element as? UIView { return syncGuard(mainThread: { convert(point, from: element) }) }
        if let element = element as? CALayer { return syncGuard(mainThread: { layer.convert(point, from: element) }) }

        return Self.convert(point: point, from: element, to: self)
    }
    public func convert(rect: CGRect, to element: LayoutElement) -> CGRect {
        if let element = element as? UIView { return syncGuard(mainThread: { convert(rect, to: element) }) }
        if let element = element as? CALayer { return syncGuard(mainThread: { layer.convert(rect, to: element) }) }

        var rect = rect
        rect.origin = Self.convert(point: rect.origin, from: self, to: element)
        return rect
    }
    public func convert(rect: CGRect, from element: LayoutElement) -> CGRect {
        if let element = element as? UIView { return syncGuard(mainThread: { convert(rect, from: element) }) }
        if let element = element as? CALayer { return syncGuard(mainThread: { layer.convert(rect, from: element) }) }

        var rect = rect
        rect.origin = Self.convert(point: rect.origin, from: element, to: self)
        return rect
    }
}
#endif

#if os(macOS) || os(iOS) || os(tvOS)
extension LayoutCoordinateSpace where Self: CALayer {
    public func convert(point: CGPoint, to item: LayoutElement) -> CGPoint {
        if let item = item as? CALayer { return syncGuard(mainThread: { convert(point, to: item) }) }

        return Self.convert(point: point, from: self, to: item)
    }
    public func convert(point: CGPoint, from item: LayoutElement) -> CGPoint {
        if let item = item as? CALayer { return syncGuard(mainThread: { convert(point, from: item) }) }

        return Self.convert(point: point, from: item, to: self)
    }
    public func convert(rect: CGRect, to item: LayoutElement) -> CGRect {
        if let item = item as? CALayer { return syncGuard(mainThread: { convert(rect, to: item) }) }

        var rect = rect
        rect.origin = Self.convert(point: rect.origin, from: self, to: item)
        return rect
    }
    public func convert(rect: CGRect, from item: LayoutElement) -> CGRect {
        if let item = item as? CALayer { return syncGuard(mainThread: { convert(rect, from: item) }) }

        var rect = rect
        rect.origin = Self.convert(point: rect.origin, from: item, to: self)
        return rect
    }
}
#endif

#if os(iOS) || os(tvOS)
@available(iOS 9.0, *)
extension LayoutCoordinateSpace where Self: UILayoutGuide {
    public func convert(point: CGPoint, to element: LayoutElement) -> CGPoint {
        guard !(element is UIView) else { return convert(point, to: element as! UIView) }

        return Self.convert(point: point, from: self, to: element)
    }
    public func convert(point: CGPoint, from element: LayoutElement) -> CGPoint {
        guard !(element is UIView) else { return convert(point, from: element as! UIView) }

        return Self.convert(point: point, from: element, to: self)
    }
    public func convert(rect: CGRect, to element: LayoutElement) -> CGRect {
        guard !(element is UIView) else { return convert(rect, to: element as! UIView) }

        var rect = rect
        rect.origin = Self.convert(point: rect.origin, from: self, to: element)
        return rect
    }
    public func convert(rect: CGRect, from element: LayoutElement) -> CGRect {
        guard !(element is UIView) else { return convert(rect, from: element as! UIView) }

        var rect = rect
        rect.origin = Self.convert(point: rect.origin, from: element, to: self)
        return rect
    }
    public func convert(_ point: CGPoint, to view: UIView) -> CGPoint {
        let pointInSuper = CGPoint(x: frame.origin.x + point.x, y: frame.origin.y + point.y)
        return owningView!.convert(pointInSuper, to: view)
    }
    public func convert(_ point: CGPoint, from view: UIView) -> CGPoint {
        let pointInSuper = owningView!.convert(point, from: view)
        return CGPoint(x: pointInSuper.x - frame.origin.x, y: pointInSuper.y - frame.origin.y)
    }
    public func convert(_ rect: CGRect, to view: UIView) -> CGRect {
        let rectInSuper = CGRect(x: frame.origin.x + rect.origin.x, y: frame.origin.y + rect.origin.y, width: rect.width, height: rect.height)
        return owningView!.convert(rectInSuper, to: view)
    }
    public func convert(_ rect: CGRect, from view: UIView) -> CGRect {
        let rectInSuper = owningView!.convert(rect, from: view)
        return CGRect(x: rectInSuper.origin.x - frame.origin.x, y: rectInSuper.origin.y - frame.origin.y, width: rectInSuper.width, height: rectInSuper.height)
    }
}
#endif
#if os(macOS)
    extension LayoutCoordinateSpace where Self: NSView {
        public func convert(point: CGPoint, to item: LayoutElement) -> CGPoint {
            if let item = item as? NSView { return syncGuard(mainThread: { convert(point, to: item) }) }
            if let item = item as? CALayer, let layer = layer { return syncGuard(mainThread: { layer.convert(point, to: item) }) }

            return Self.convert(point: point, from: self, to: item)
        }
        public func convert(point: CGPoint, from item: LayoutElement) -> CGPoint {
            if let item = item as? NSView { return syncGuard(mainThread: { convert(point, from: item) }) }
            if let item = item as? CALayer, let layer = layer { return syncGuard(mainThread: { layer.convert(point, from: item) }) }

            return Self.convert(point: point, from: item, to: self)
        }
        public func convert(rect: CGRect, to item: LayoutElement) -> CGRect {
            if let item = item as? NSView { return syncGuard(mainThread: { convert(rect, to: item) }) }
            if let item = item as? CALayer, let layer = layer { return syncGuard(mainThread: { layer.convert(rect, to: item) }) }

            var rect = rect
            rect.origin = Self.convert(point: rect.origin, from: self, to: item)
            return rect
        }
        public func convert(rect: CGRect, from item: LayoutElement) -> CGRect {
            if let item = item as? NSView { return syncGuard(mainThread: { convert(rect, from: item) }) }
            if let item = item as? CALayer, let layer = layer { return syncGuard(mainThread: { layer.convert(rect, from: item) }) }

            var rect = rect
            rect.origin = Self.convert(point: rect.origin, from: item, to: self)
            return rect
        }
    }
#endif

fileprivate struct LinkedList<T>: Sequence {
    private let startObject: T
    private let next: (T) -> T?

    init(start: T, next: @escaping (T) -> T?) {
        self.startObject = start
        self.next = next
    }

    func makeIterator() -> AnyIterator<T> {
        var current: T? = startObject
        return AnyIterator {
            let next = current
            current = current.flatMap { self.next($0) }
            return next
        }
    }
}

extension LayoutCoordinateSpace where Self: LayoutElement {
    fileprivate static func convert(point: CGPoint, from: LayoutElement, to: LayoutElement) -> CGPoint {
        let list1Iterator = LinkedList(start: from) { $0.inLayoutTime.superElement }.makeIterator()
        var list2Iterator = LinkedList(start: to) { $0.inLayoutTime.superElement }.reversed().makeIterator()

        var converted = point
        while let next = list1Iterator.next()?.inLayoutTime {
            converted.x = next.frame.origin.x + converted.x - next.bounds.origin.x
            converted.y = next.frame.origin.y + converted.y - next.bounds.origin.y
        }

        while let next = list2Iterator.next()?.inLayoutTime {
            converted.x = converted.x - next.frame.origin.x + next.bounds.origin.x
            converted.y = converted.y - next.frame.origin.y + next.bounds.origin.y
        }

        return converted
    }
    public func convert(point: CGPoint, to item: LayoutElement) -> CGPoint {
        return Self.convert(point: point, from: self, to: item)
    }

    public func convert(point: CGPoint, from item: LayoutElement) -> CGPoint {
        return Self.convert(point: point, from: item, to: self)
    }
    public func convert(rect: CGRect, to item: LayoutElement) -> CGRect {
        var rect = rect
        rect.origin = convert(point: rect.origin, to: item)
        return rect
    }
    public func convert(rect: CGRect, from item: LayoutElement) -> CGRect {
        var rect = rect
        rect.origin = convert(point: rect.origin, from: item)
        return rect
    }
}

// MARK: LayoutGuide conversions

#if os(iOS) || os(tvOS)
extension LayoutGuide where Super: UICoordinateSpace {
    public func convert(point: CGPoint, to element: LayoutElement) -> CGPoint {
        guard !(element is UICoordinateSpace) else { return convert(point, to: element as! UICoordinateSpace) }

        return LayoutGuide.convert(point: point, from: self, to: element)
    }
    public func convert(point: CGPoint, from element: LayoutElement) -> CGPoint {
        guard !(element is UICoordinateSpace) else { return convert(point, from: element as! UICoordinateSpace) }

        return LayoutGuide.convert(point: point, from: element, to: self)
    }
    public func convert(rect: CGRect, to element: LayoutElement) -> CGRect {
        guard !(element is UICoordinateSpace) else { return convert(rect, to: element as! UICoordinateSpace) }

        var rect = rect
        rect.origin = LayoutGuide.convert(point: rect.origin, from: self, to: element)
        return rect
    }
    public func convert(rect: CGRect, from element: LayoutElement) -> CGRect {
        guard !(element is UICoordinateSpace) else { return convert(rect, from: element as! UICoordinateSpace) }

        var rect = rect
        rect.origin = LayoutGuide.convert(point: rect.origin, from: element, to: self)
        return rect
    }
}
/// UIView.convert(_ point: CGPoint, to view: UIView?) faster than UICoordinateSpace.convert(_ point: CGPoint, to coordinateSpace: UICoordinateSpace)
/// Therefore makes extension for UIView.
extension LayoutGuide where Super: UIView {
    public func convert(point: CGPoint, to element: LayoutElement) -> CGPoint {
        if let element = element as? UIView { return convert(point, to: element) }
        if let element = element as? CALayer { return convert(point, to: element) }

        return LayoutGuide.convert(point: point, from: self, to: element)
    }
    public func convert(point: CGPoint, from element: LayoutElement) -> CGPoint {
        if let element = element as? UIView { return convert(point, from: element) }
        if let element = element as? CALayer { return convert(point, from: element) }

        return LayoutGuide.convert(point: point, from: element, to: self)
    }
    public func convert(rect: CGRect, to element: LayoutElement) -> CGRect {
        if let element = element as? UIView { return convert(rect, to: element) }
        if let element = element as? CALayer { return convert(rect, to: element) }

        var rect = rect
        rect.origin = LayoutGuide.convert(point: rect.origin, from: self, to: element)
        return rect
    }
    public func convert(rect: CGRect, from element: LayoutElement) -> CGRect {
        if let element = element as? UIView { return convert(rect, from: element) }
        if let element = element as? CALayer { return convert(rect, from: element) }

        var rect = rect
        rect.origin = LayoutGuide.convert(point: rect.origin, from: element, to: self)
        return rect
    }
}
#endif
#if os(macOS)
    extension LayoutGuide where Super: NSView {
        public func convert(point: CGPoint, to item: LayoutElement) -> CGPoint {
            if let item = item as? NSView { return convert(point, to: item) }
            if let item = item as? CALayer, let layer = ownerElement?.layer { return convert(point, to: item, superLayer: layer) }

            return LayoutGuide.convert(point: point, from: self, to: item)
        }
        public func convert(point: CGPoint, from item: LayoutElement) -> CGPoint {
            if let item = item as? NSView { return convert(point, from: item) }
            if let item = item as? CALayer, let layer = ownerElement?.layer { return convert(point, from: item, superLayer: layer) }

            return LayoutGuide.convert(point: point, from: item, to: self)
        }
        public func convert(rect: CGRect, to item: LayoutElement) -> CGRect {
            if let item = item as? NSView { return convert(rect, to: item) }
            if let item = item as? CALayer, let layer = ownerElement?.layer { return convert(rect, to: item, superLayer: layer) }

            var rect = rect
            rect.origin = LayoutGuide.convert(point: rect.origin, from: self, to: item)
            return rect
        }
        public func convert(rect: CGRect, from item: LayoutElement) -> CGRect {
            if let item = item as? NSView { return convert(rect, from: item) }
            if let item = item as? CALayer, let layer = ownerElement?.layer { return convert(rect, from: item, superLayer: layer) }

            var rect = rect
            rect.origin = LayoutGuide.convert(point: rect.origin, from: item, to: self)
            return rect
        }
    }
#endif

#if os(macOS) || os(iOS) || os(tvOS)
extension LayoutGuide where Super: CALayer {
    public func convert(point: CGPoint, to item: LayoutElement) -> CGPoint {
        guard !(item is CALayer) else { return convert(point, to: item as! CALayer) }

        return LayoutGuide.convert(point: point, from: self, to: item)
    }
    public func convert(point: CGPoint, from item: LayoutElement) -> CGPoint {
        guard !(item is CALayer) else { return convert(point, from: item as! CALayer) }

        return LayoutGuide.convert(point: point, from: item, to: self)
    }
    public func convert(rect: CGRect, to item: LayoutElement) -> CGRect {
        guard !(item is CALayer) else { return convert(rect, to: item as! CALayer) }

        var rect = rect
        rect.origin = LayoutGuide.convert(point: rect.origin, from: self, to: item)
        return rect
    }
    public func convert(rect: CGRect, from item: LayoutElement) -> CGRect {
        guard !(item is CALayer) else { return convert(rect, from: item as! CALayer) }

        var rect = rect
        rect.origin = LayoutGuide.convert(point: rect.origin, from: item, to: self)
        return rect
    }
}
#endif

#if os(iOS) || os(tvOS)
extension LayoutGuide where Super: UICoordinateSpace {
    @available(iOS 8.0, *)
    public func convert(_ point: CGPoint, to coordinateSpace: UICoordinateSpace) -> CGPoint {
        let pointInSuper = CGPoint(x: frame.origin.x + point.x - bounds.origin.x, y: frame.origin.y + point.y - bounds.origin.y)
        return syncGuard(mainThread: ownerElement!.convert(pointInSuper, to: coordinateSpace))
    }

    @available(iOS 8.0, *)
    public func convert(_ point: CGPoint, from coordinateSpace: UICoordinateSpace) -> CGPoint {
        let pointInSuper = syncGuard(mainThread: ownerElement!.convert(point, from: coordinateSpace))
        return CGPoint(x: pointInSuper.x - frame.origin.x + bounds.origin.x, y: pointInSuper.y - frame.origin.y + bounds.origin.y)
    }

    @available(iOS 8.0, *)
    public func convert(_ rect: CGRect, to coordinateSpace: UICoordinateSpace) -> CGRect {
        let rectInSuper = CGRect(x: frame.origin.x + rect.origin.x - bounds.origin.x, y: frame.origin.y + rect.origin.y - bounds.origin.y, width: rect.width, height: rect.height)
        return syncGuard(mainThread: ownerElement!.convert(rectInSuper, to: coordinateSpace))
    }

    @available(iOS 8.0, *)
    public func convert(_ rect: CGRect, from coordinateSpace: UICoordinateSpace) -> CGRect {
        let rectInSuper = syncGuard(mainThread: ownerElement!.convert(rect, from: coordinateSpace))
        return CGRect(x: rectInSuper.origin.x - frame.origin.x + bounds.origin.x, y: rectInSuper.origin.y - frame.origin.y + bounds.origin.y, width: rectInSuper.width, height: rectInSuper.height)
    }
}
extension LayoutGuide where Super: UIView {
    public func convert(_ point: CGPoint, to view: UIView) -> CGPoint {
        let pointInSuper = CGPoint(x: frame.origin.x + point.x - bounds.origin.x, y: frame.origin.y + point.y - bounds.origin.y)
        return syncGuard(mainThread: ownerElement!.convert(pointInSuper, to: view))
    }

    public func convert(_ point: CGPoint, from view: UIView) -> CGPoint {
        let pointInSuper = syncGuard(mainThread: ownerElement!.convert(point, from: view))
        return CGPoint(x: pointInSuper.x - frame.origin.x + bounds.origin.x, y: pointInSuper.y - frame.origin.y + bounds.origin.y)
    }

    public func convert(_ rect: CGRect, to view: UIView) -> CGRect {
        let rectInSuper = CGRect(x: frame.origin.x + rect.origin.x - bounds.origin.x, y: frame.origin.y + rect.origin.y - bounds.origin.y, width: rect.width, height: rect.height)
        return syncGuard(mainThread: ownerElement!.convert(rectInSuper, to: view))
    }

    public func convert(_ rect: CGRect, from view: UIView) -> CGRect {
        let rectInSuper = syncGuard(mainThread: ownerElement!.convert(rect, from: view))
        return CGRect(x: rectInSuper.origin.x - frame.origin.x + bounds.origin.x, y: rectInSuper.origin.y - frame.origin.y + bounds.origin.y, width: rectInSuper.width, height: rectInSuper.height)
    }
    public func convert(_ point: CGPoint, to layer: CALayer) -> CGPoint {
        let pointInSuper = CGPoint(x: frame.origin.x + point.x - bounds.origin.x, y: frame.origin.y + point.y - bounds.origin.y)
        return syncGuard(mainThread: ownerElement!.layer.convert(pointInSuper, to: layer))
    }

    public func convert(_ point: CGPoint, from layer: CALayer) -> CGPoint {
        let pointInSuper = syncGuard(mainThread: ownerElement!.layer.convert(point, from: layer))
        return CGPoint(x: pointInSuper.x - frame.origin.x + bounds.origin.x, y: pointInSuper.y - frame.origin.y + bounds.origin.y)
    }

    public func convert(_ rect: CGRect, to layer: CALayer) -> CGRect {
        let rectInSuper = CGRect(x: frame.origin.x + rect.origin.x - bounds.origin.x, y: frame.origin.y + rect.origin.y - bounds.origin.y, width: rect.width, height: rect.height)
        return syncGuard(mainThread: ownerElement!.layer.convert(rectInSuper, to: layer))
    }

    public func convert(_ rect: CGRect, from layer: CALayer) -> CGRect {
        let rectInSuper = syncGuard(mainThread: ownerElement!.layer.convert(rect, from: layer))
        return CGRect(x: rectInSuper.origin.x - frame.origin.x + bounds.origin.x, y: rectInSuper.origin.y - frame.origin.y + bounds.origin.y, width: rectInSuper.width, height: rectInSuper.height)
    }
}
#endif
#if os(macOS)
    extension LayoutGuide where Super: NSView {
        public func convert(_ point: CGPoint, to view: NSView) -> CGPoint {
            let pointInSuper = CGPoint(x: frame.origin.x + point.x - bounds.origin.x, y: frame.origin.y + point.y - bounds.origin.y)
            return syncGuard(mainThread: ownerElement!.convert(pointInSuper, to: view))
        }

        public func convert(_ point: CGPoint, from view: NSView) -> CGPoint {
            let pointInSuper = syncGuard(mainThread: ownerElement!.convert(point, from: view))
            return CGPoint(x: pointInSuper.x - frame.origin.x + bounds.origin.x, y: pointInSuper.y - frame.origin.y + bounds.origin.y)
        }

        public func convert(_ rect: CGRect, to view: NSView) -> CGRect {
            let rectInSuper = CGRect(x: frame.origin.x + rect.origin.x - bounds.origin.x, y: frame.origin.y + rect.origin.y - bounds.origin.y, width: rect.width, height: rect.height)
            return syncGuard(mainThread: ownerElement!.convert(rectInSuper, to: view))
        }

        public func convert(_ rect: CGRect, from view: NSView) -> CGRect {
            let rectInSuper = syncGuard(mainThread: ownerElement!.convert(rect, from: view))
            return CGRect(x: rectInSuper.origin.x - frame.origin.x + bounds.origin.x, y: rectInSuper.origin.y - frame.origin.y + bounds.origin.y, width: rectInSuper.width, height: rectInSuper.height)
        }
        public func convert(_ point: CGPoint, to layer: CALayer, superLayer: CALayer) -> CGPoint {
            let pointInSuper = CGPoint(x: frame.origin.x + point.x - bounds.origin.x, y: frame.origin.y + point.y - bounds.origin.y)
            return syncGuard(mainThread: superLayer.convert(pointInSuper, to: layer))
        }

        public func convert(_ point: CGPoint, from layer: CALayer, superLayer: CALayer) -> CGPoint {
            let pointInSuper = syncGuard(mainThread: superLayer.convert(point, from: layer))
            return CGPoint(x: pointInSuper.x - frame.origin.x + bounds.origin.x, y: pointInSuper.y - frame.origin.y + bounds.origin.y)
        }

        public func convert(_ rect: CGRect, to layer: CALayer, superLayer: CALayer) -> CGRect {
            let rectInSuper = CGRect(x: frame.origin.x + rect.origin.x - bounds.origin.x, y: frame.origin.y + rect.origin.y - bounds.origin.y, width: rect.width, height: rect.height)
            return syncGuard(mainThread: superLayer.convert(rectInSuper, to: layer))
        }

        public func convert(_ rect: CGRect, from layer: CALayer, superLayer: CALayer) -> CGRect {
            let rectInSuper = syncGuard(mainThread: superLayer.convert(rect, from: layer))
            return CGRect(x: rectInSuper.origin.x - frame.origin.x + bounds.origin.x, y: rectInSuper.origin.y - frame.origin.y + bounds.origin.y, width: rectInSuper.width, height: rectInSuper.height)
        }
    }
#endif

#if os(macOS) || os(iOS) || os(tvOS)
extension LayoutGuide where Super: CALayer {
    public func convert(_ point: CGPoint, to coordinateSpace: CALayer) -> CGPoint {
        let pointInSuper = CGPoint(x: frame.origin.x + point.x - bounds.origin.x, y: frame.origin.y + point.y - bounds.origin.y)
        return syncGuard(mainThread: ownerElement!.convert(pointInSuper, to: coordinateSpace))
    }

    public func convert(_ point: CGPoint, from coordinateSpace: CALayer) -> CGPoint {
        let pointInSuper = syncGuard(mainThread: ownerElement!.convert(point, from: coordinateSpace))
        return CGPoint(x: pointInSuper.x - frame.origin.x + bounds.origin.x, y: pointInSuper.y - frame.origin.y + bounds.origin.y)
    }

    public func convert(_ rect: CGRect, to coordinateSpace: CALayer) -> CGRect {
        let rectInSuper = CGRect(x: frame.origin.x + rect.origin.x - bounds.origin.x, y: frame.origin.y + rect.origin.y - bounds.origin.y, width: rect.width, height: rect.height)
        return syncGuard(mainThread: ownerElement!.convert(rectInSuper, to: coordinateSpace))
    }

    public func convert(_ rect: CGRect, from coordinateSpace: CALayer) -> CGRect {
        let rectInSuper = syncGuard(mainThread: ownerElement!.convert(rect, from: coordinateSpace))
        return CGRect(x: rectInSuper.origin.x - frame.origin.x + bounds.origin.x, y: rectInSuper.origin.y - frame.origin.y + bounds.origin.y, width: rectInSuper.width, height: rectInSuper.height)
    }
}
#endif

// MARK: CoordinateConvertable

/// Common protocol for anyone `LayoutElement` item that coordinates can be converted to other space.
/// Used for converting coordinates of UIView and CALayer.
/// Converting from UIView coordinate space to CALayer (or conversely) coordinate while not possible.
/// Therefore can use constraints only from same `LayoutElement` type space.
/*public protocol CoordinateConvertable {
    @available(iOS 8.0, *)
    func convert(_ point: CGPoint, to item: CoordinateConvertable?) -> CGPoint

    @available(iOS 8.0, *)
    func convert(_ point: CGPoint, from item: CoordinateConvertable?) -> CGPoint

    @available(iOS 8.0, *)
    func convert(_ rect: CGRect, to item: CoordinateConvertable?) -> CGRect

    @available(iOS 8.0, *)
    func convert(_ rect: CGRect, from item: CoordinateConvertable?) -> CGRect
}

extension UIView: CoordinateConvertable {
    public func convert(_ point: CGPoint, to item: CoordinateConvertable?) -> CGPoint {
        return convert(point, to: item as! UIView?)
    }

    public func convert(_ point: CGPoint, from item: CoordinateConvertable?) -> CGPoint {
        return convert(point, from: item as! UIView?)
    }

    public func convert(_ rect: CGRect, to item: CoordinateConvertable?) -> CGRect {
        return convert(rect, to: item as! UIView?)
    }

    public func convert(_ rect: CGRect, from item: CoordinateConvertable?) -> CGRect {
        return convert(rect, from: item as! UIView?)
    }
}
extension CALayer: CoordinateConvertable {
    public func convert(_ point: CGPoint, to item: CoordinateConvertable?) -> CGPoint {
        return convert(point, to: item as! CALayer?)
    }

    public func convert(_ point: CGPoint, from item: CoordinateConvertable?) -> CGPoint {
        return convert(point, from: item as! CALayer?)
    }

    public func convert(_ rect: CGRect, to item: CoordinateConvertable?) -> CGRect {
        return convert(rect, to: item as! CALayer?)
    }

    public func convert(_ rect: CGRect, from item: CoordinateConvertable?) -> CGRect {
        return convert(rect, from: item as! CALayer?)
    }
}*/
