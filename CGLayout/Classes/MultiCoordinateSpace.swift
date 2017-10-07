//
//  MultiCoordinateSpace.swift
//  Pods
//
//  Created by Denis Koryttsev on 08/09/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

import Foundation

// TODO: !!! Add MacOS support (conversions more complex)

// MARK: LayoutCoordinateSpace

/// Common protocol for anyone `LayoutItem`.
/// Used for multi-converting coordinates between `LayoutItem` items.
/// Converting between UIView and CALayer has low performance in comparison converting with same type.
/// Therefore should UIView.layer property when creates constraint relationship between UIView and CALayer.
public protocol LayoutCoordinateSpace {
    func convert(point: CGPoint, to item: LayoutItem) -> CGPoint
    func convert(point: CGPoint, from item: LayoutItem) -> CGPoint
    func convert(rect: CGRect, to item: LayoutItem) -> CGRect
    func convert(rect: CGRect, from item: LayoutItem) -> CGRect

    var bounds: CGRect { get }
    var frame: CGRect { get }
}
extension LayoutCoordinateSpace where Self: UICoordinateSpace, Self: LayoutItem {
    public func convert(point: CGPoint, to item: LayoutItem) -> CGPoint {
        guard !(item is UICoordinateSpace) else { return convert(point, to: item as! UICoordinateSpace) }

        return Self.convert(point: point, from: self, to: item)
    }
    public func convert(point: CGPoint, from item: LayoutItem) -> CGPoint {
        guard !(item is UICoordinateSpace) else { return convert(point, from: item as! UICoordinateSpace) }

        return Self.convert(point: point, from: item, to: self)
    }
    public func convert(rect: CGRect, to item: LayoutItem) -> CGRect {
        guard !(item is UICoordinateSpace) else { return convert(rect, to: item as! UICoordinateSpace) }

        var rect = rect
        rect.origin = Self.convert(point: rect.origin, from: self, to: item)
        return rect
    }
    public func convert(rect: CGRect, from item: LayoutItem) -> CGRect {
        guard !(item is UICoordinateSpace) else { return convert(rect, from: item as! UICoordinateSpace) }

        var rect = rect
        rect.origin = Self.convert(point: rect.origin, from: item, to: self)
        return rect
    }
}
/// UIView.convert(_ point: CGPoint, to view: UIView?) faster than UICoordinateSpace.convert(_ point: CGPoint, to coordinateSpace: UICoordinateSpace)
/// Therefore makes extension for UIView.
extension LayoutCoordinateSpace where Self: UIView {
    public func convert(point: CGPoint, to item: LayoutItem) -> CGPoint {
        guard !(item is UIView) else { return convert(point, to: item as! UIView) }

        return Self.convert(point: point, from: self, to: item)
    }
    public func convert(point: CGPoint, from item: LayoutItem) -> CGPoint {
        guard !(item is UIView) else { return convert(point, from: item as! UIView) }

        return Self.convert(point: point, from: item, to: self)
    }
    public func convert(rect: CGRect, to item: LayoutItem) -> CGRect {
        guard !(item is UIView) else { return convert(rect, to: item as! UIView) }

        var rect = rect
        rect.origin = Self.convert(point: rect.origin, from: self, to: item)
        return rect
    }
    public func convert(rect: CGRect, from item: LayoutItem) -> CGRect {
        guard !(item is UIView) else { return convert(rect, from: item as! UIView) }

        var rect = rect
        rect.origin = Self.convert(point: rect.origin, from: item, to: self)
        return rect
    }
}
extension LayoutCoordinateSpace where Self: CALayer {
    public func convert(point: CGPoint, to item: LayoutItem) -> CGPoint {
        guard !(item is CALayer) else { return convert(point, to: item as? CALayer) }

        return Self.convert(point: point, from: self, to: item)
    }
    public func convert(point: CGPoint, from item: LayoutItem) -> CGPoint {
        guard !(item is CALayer) else { return convert(point, from: item as? CALayer) }

        return Self.convert(point: point, from: item, to: self)
    }
    public func convert(rect: CGRect, to item: LayoutItem) -> CGRect {
        guard !(item is CALayer) else { return convert(rect, to: item as? CALayer) }

        var rect = rect
        rect.origin = Self.convert(point: rect.origin, from: self, to: item)
        return rect
    }
    public func convert(rect: CGRect, from item: LayoutItem) -> CGRect {
        guard !(item is CALayer) else { return convert(rect, from: item as? CALayer) }

        var rect = rect
        rect.origin = Self.convert(point: rect.origin, from: item, to: self)
        return rect
    }
}
@available(iOS 9.0, *)
extension LayoutCoordinateSpace where Self: UILayoutGuide {
    public func convert(point: CGPoint, to item: LayoutItem) -> CGPoint {
        guard !(item is UIView) else { return convert(point, to: item as! UIView) }

        return Self.convert(point: point, from: self, to: item)
    }
    public func convert(point: CGPoint, from item: LayoutItem) -> CGPoint {
        guard !(item is UIView) else { return convert(point, from: item as! UIView) }

        return Self.convert(point: point, from: item, to: self)
    }
    public func convert(rect: CGRect, to item: LayoutItem) -> CGRect {
        guard !(item is UIView) else { return convert(rect, to: item as! UIView) }

        var rect = rect
        rect.origin = Self.convert(point: rect.origin, from: self, to: item)
        return rect
    }
    public func convert(rect: CGRect, from item: LayoutItem) -> CGRect {
        guard !(item is UIView) else { return convert(rect, from: item as! UIView) }

        var rect = rect
        rect.origin = Self.convert(point: rect.origin, from: item, to: self)
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

// TODO: Add search nearest common ancestor to implementation
extension LayoutCoordinateSpace where Self: LayoutItem {
    fileprivate static func convert(point: CGPoint, from: LayoutItem, to: LayoutItem) -> CGPoint {
        let list1Iterator = LinkedList(start: from) { $0.inLayoutTime.superItem }.makeIterator()
        var list2Iterator = LinkedList(start: to) { $0.inLayoutTime.superItem }.reversed().makeIterator()

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
    public func convert(point: CGPoint, to item: LayoutItem) -> CGPoint {
        return Self.convert(point: point, from: self, to: item)
    }

    public func convert(point: CGPoint, from item: LayoutItem) -> CGPoint {
        return Self.convert(point: point, from: item, to: self)
    }
    public func convert(rect: CGRect, to item: LayoutItem) -> CGRect {
        var rect = rect
        rect.origin = convert(point: rect.origin, to: item)
        return rect
    }
    public func convert(rect: CGRect, from item: LayoutItem) -> CGRect {
        var rect = rect
        rect.origin = convert(point: rect.origin, from: item)
        return rect
    }
}

// MARK: LayoutGuide convertions

extension LayoutGuide where Super: UICoordinateSpace {
    public func convert(point: CGPoint, to item: LayoutItem) -> CGPoint {
        guard !(item is UICoordinateSpace) else { return convert(point, to: item as! UICoordinateSpace) }

        return LayoutGuide.convert(point: point, from: self, to: item)
    }
    public func convert(point: CGPoint, from item: LayoutItem) -> CGPoint {
        guard !(item is UICoordinateSpace) else { return convert(point, from: item as! UICoordinateSpace) }

        return LayoutGuide.convert(point: point, from: item, to: self)
    }
    public func convert(rect: CGRect, to item: LayoutItem) -> CGRect {
        guard !(item is UICoordinateSpace) else { return convert(rect, to: item as! UICoordinateSpace) }

        var rect = rect
        rect.origin = LayoutGuide.convert(point: rect.origin, from: self, to: item)
        return rect
    }
    public func convert(rect: CGRect, from item: LayoutItem) -> CGRect {
        guard !(item is UICoordinateSpace) else { return convert(rect, from: item as! UICoordinateSpace) }

        var rect = rect
        rect.origin = LayoutGuide.convert(point: rect.origin, from: item, to: self)
        return rect
    }
}
/// UIView.convert(_ point: CGPoint, to view: UIView?) faster than UICoordinateSpace.convert(_ point: CGPoint, to coordinateSpace: UICoordinateSpace)
/// Therefore makes extension for UIView.
extension LayoutGuide where Super: UIView {
    public func convert(point: CGPoint, to item: LayoutItem) -> CGPoint {
        guard !(item is UIView) else { return convert(point, to: item as! UIView) }

        return LayoutGuide.convert(point: point, from: self, to: item)
    }
    public func convert(point: CGPoint, from item: LayoutItem) -> CGPoint {
        guard !(item is UIView) else { return convert(point, from: item as! UIView) }

        return LayoutGuide.convert(point: point, from: item, to: self)
    }
    public func convert(rect: CGRect, to item: LayoutItem) -> CGRect {
        guard !(item is UIView) else { return convert(rect, to: item as! UIView) }

        var rect = rect
        rect.origin = LayoutGuide.convert(point: rect.origin, from: self, to: item)
        return rect
    }
    public func convert(rect: CGRect, from item: LayoutItem) -> CGRect {
        guard !(item is UIView) else { return convert(rect, from: item as! UIView) }

        var rect = rect
        rect.origin = LayoutGuide.convert(point: rect.origin, from: item, to: self)
        return rect
    }
}
extension LayoutGuide where Super: CALayer {
    public func convert(point: CGPoint, to item: LayoutItem) -> CGPoint {
        guard !(item is CALayer) else { return convert(point, to: item as! CALayer) }

        return LayoutGuide.convert(point: point, from: self, to: item)
    }
    public func convert(point: CGPoint, from item: LayoutItem) -> CGPoint {
        guard !(item is CALayer) else { return convert(point, from: item as! CALayer) }

        return LayoutGuide.convert(point: point, from: item, to: self)
    }
    public func convert(rect: CGRect, to item: LayoutItem) -> CGRect {
        guard !(item is CALayer) else { return convert(rect, to: item as! CALayer) }

        var rect = rect
        rect.origin = LayoutGuide.convert(point: rect.origin, from: self, to: item)
        return rect
    }
    public func convert(rect: CGRect, from item: LayoutItem) -> CGRect {
        guard !(item is CALayer) else { return convert(rect, from: item as! CALayer) }

        var rect = rect
        rect.origin = LayoutGuide.convert(point: rect.origin, from: item, to: self)
        return rect
    }
}
extension LayoutGuide where Super: UICoordinateSpace {
    @available(iOS 8.0, *)
    public func convert(_ point: CGPoint, to coordinateSpace: UICoordinateSpace) -> CGPoint {
        let pointInSuper = CGPoint(x: frame.origin.x + point.x - bounds.origin.x, y: frame.origin.y + point.y - bounds.origin.y)
        return ownerItem!.convert(pointInSuper, to: coordinateSpace)
    }

    @available(iOS 8.0, *)
    public func convert(_ point: CGPoint, from coordinateSpace: UICoordinateSpace) -> CGPoint {
        let pointInSuper = ownerItem!.convert(point, from: coordinateSpace)
        return CGPoint(x: pointInSuper.x - frame.origin.x + bounds.origin.x, y: pointInSuper.y - frame.origin.y + bounds.origin.y)
    }

    @available(iOS 8.0, *)
    public func convert(_ rect: CGRect, to coordinateSpace: UICoordinateSpace) -> CGRect {
        let rectInSuper = CGRect(x: frame.origin.x + rect.origin.x - bounds.origin.x, y: frame.origin.y + rect.origin.y - bounds.origin.y, width: rect.width, height: rect.height)
        return ownerItem!.convert(rectInSuper, to: coordinateSpace)
    }

    @available(iOS 8.0, *)
    public func convert(_ rect: CGRect, from coordinateSpace: UICoordinateSpace) -> CGRect {
        let rectInSuper = ownerItem!.convert(rect, from: coordinateSpace)
        return CGRect(x: rectInSuper.origin.x - frame.origin.x + bounds.origin.x, y: rectInSuper.origin.y - frame.origin.y + bounds.origin.y, width: rectInSuper.width, height: rectInSuper.height)
    }
}
extension LayoutGuide where Super: UIView {
    public func convert(_ point: CGPoint, to view: UIView) -> CGPoint {
        let pointInSuper = CGPoint(x: frame.origin.x + point.x - bounds.origin.x, y: frame.origin.y + point.y - bounds.origin.y)
        return ownerItem!.convert(pointInSuper, to: view)
    }

    public func convert(_ point: CGPoint, from view: UIView) -> CGPoint {
        let pointInSuper = ownerItem!.convert(point, from: view)
        return CGPoint(x: pointInSuper.x - frame.origin.x + bounds.origin.x, y: pointInSuper.y - frame.origin.y + bounds.origin.y)
    }

    public func convert(_ rect: CGRect, to view: UIView) -> CGRect {
        let rectInSuper = CGRect(x: frame.origin.x + rect.origin.x - bounds.origin.x, y: frame.origin.y + rect.origin.y - bounds.origin.y, width: rect.width, height: rect.height)
        return ownerItem!.convert(rectInSuper, to: view)
    }

    public func convert(_ rect: CGRect, from view: UIView) -> CGRect {
        let rectInSuper = ownerItem!.convert(rect, from: view)
        return CGRect(x: rectInSuper.origin.x - frame.origin.x + bounds.origin.x, y: rectInSuper.origin.y - frame.origin.y + bounds.origin.y, width: rectInSuper.width, height: rectInSuper.height)
    }
}
extension LayoutGuide where Super: CALayer {
    public func convert(_ point: CGPoint, to coordinateSpace: CALayer) -> CGPoint {
        let pointInSuper = CGPoint(x: frame.origin.x + point.x - bounds.origin.x, y: frame.origin.y + point.y - bounds.origin.y)
        return ownerItem!.convert(pointInSuper, to: coordinateSpace)
    }

    public func convert(_ point: CGPoint, from coordinateSpace: CALayer) -> CGPoint {
        let pointInSuper = ownerItem!.convert(point, from: coordinateSpace)
        return CGPoint(x: pointInSuper.x - frame.origin.x + bounds.origin.x, y: pointInSuper.y - frame.origin.y + bounds.origin.y)
    }

    public func convert(_ rect: CGRect, to coordinateSpace: CALayer) -> CGRect {
        let rectInSuper = CGRect(x: frame.origin.x + rect.origin.x - bounds.origin.x, y: frame.origin.y + rect.origin.y - bounds.origin.y, width: rect.width, height: rect.height)
        return ownerItem!.convert(rectInSuper, to: coordinateSpace)
    }

    public func convert(_ rect: CGRect, from coordinateSpace: CALayer) -> CGRect {
        let rectInSuper = ownerItem!.convert(rect, from: coordinateSpace)
        return CGRect(x: rectInSuper.origin.x - frame.origin.x + bounds.origin.x, y: rectInSuper.origin.y - frame.origin.y + bounds.origin.y, width: rectInSuper.width, height: rectInSuper.height)
    }
}

// MARK: CoordinateConvertable

/// Common protocol for anyone `LayoutItem` item that coordinates can be converted to other space.
/// Used for converting coordinates of UIView and CALayer.
/// Converting from UIView coordinate space to CALayer (or conversely) coordinate while not possible.
/// Therefore can use constraints only from same `LayoutItem` type space.
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
