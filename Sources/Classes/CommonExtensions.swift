//
//  CommonExtensions.swift
//  Pods
//
//  Created by Denis Koryttsev on 04/09/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

import Foundation

internal func warning(_ isTruth: Bool, _ message: String) {
    debugAction { if isTruth { printWarning(message) } }
}

internal func debugAction(_ action: () -> Void) {
    #if DEBUG
        action()
    #endif
}

internal func printWarning(_ message: String) {
    #if DEBUG
        debugPrint("CGLayout warning: \(message)")
    #endif
}

#if os(iOS) || os(tvOS)
    public typealias EdgeInsets = UIEdgeInsets
#endif

#if os(Linux)
    public typealias EdgeInsets = NSEdgeInsets
#endif

func -(l: CGSize, r: CGFloat) -> CGSize { return CGSize(width: l.width - r, height: l.height - r) }
func +(l: CGSize, r: CGFloat) -> CGSize { return CGSize(width: l.width + r, height: l.height + r) }
func *(l: CGSize, r: CGFloat) -> CGSize { return CGSize(width: l.width * r, height: l.height * r) }

extension CGPoint {
    func positive() -> CGPoint { return CGPoint(x: abs(x), y: abs(y)) }
    func negated() -> CGPoint { return CGPoint(x: -x, y: -y) }
}

extension CGRect {
    var left: CGFloat { return minX }
    var right: CGFloat { return maxX }
    var top: CGFloat { return minY }
    var bottom: CGFloat { return maxY }
    
    var distanceFromOrigin: CGSize { return CGSize(width: maxX, height: maxY) }
    func distance(from point: CGPoint) -> CGSize { return CGSize(width: maxX - point.x, height: maxY - point.y) }
}
extension CGRect {
    mutating func apply(edgeInsets: EdgeInsets) {
        #if os(iOS) || os(tvOS)
            self = UIEdgeInsetsInsetRect(self, edgeInsets)
        #else
            self = CGRect(x: origin.x + edgeInsets.left, y: origin.y + edgeInsets.top,
                          width: size.width - edgeInsets.horizontal, height: size.height - edgeInsets.vertical)
        #endif
    }
    func applying(edgeInsets: EdgeInsets) -> CGRect { var this = self; this.apply(edgeInsets: edgeInsets); return this }

    public func asLayout() -> RectBasedLayout { return Layout(x: .left(origin.x), y: .top(origin.y), width: .fixed(width), height: .fixed(height)) }
}

extension EdgeInsets {
    var horizontal: CGFloat { return left + right }
    var vertical: CGFloat { return top + bottom }
#if os(macOS) || os(Linux)
    public static var zero: EdgeInsets { return EdgeInsets(top: 0, left: 0, bottom: 0, right: 0) }
#endif
}

#if os(iOS) || os(tvOS)
@available(iOS 9.0, *)
extension UILayoutGuide: LayoutItem {
    public var layoutBounds: CGRect { return bounds }
    public var inLayoutTime: InLayoutTimeItem { return _MainThreadItemInLayoutTime(item: self) }
    public var frame: CGRect { get { return layoutFrame } set {} }
    public var bounds: CGRect { get { return CGRect(origin: .zero, size: layoutFrame.size) } set {} }
    public var superItem: LayoutItem? { return owningView }
    public func removeFromSuperItem() { owningView.map { $0.removeLayoutGuide(self) } }
}
#endif


#if os(macOS) || os(iOS) || os(tvOS)
public extension CALayer {
    convenience init(frame: CGRect) {
        self.init()
        self.frame = frame
    }
}
#endif

extension Collection where IndexDistance == Int, Index == Int {
    var halfIndex: (index: Self.Index, isCentered: Bool) {
        let center: Double = Double(count / 2)
        return (Int(center), center.rounded(.down) == center)
    }
}

extension Bool {
    mutating func `switch`() {
        self = self ? false : true
    }
}

extension Collection where IndexDistance == Index {
    func halfSplitIterator() -> AnyIterator<Self.SubSequence.Iterator.Element> {
        let firstIndex = count / 2
        var left = prefix(through: firstIndex).reversed().makeIterator()
        var right = suffix(from: firstIndex).makeIterator()

        var fromLeft = true
        return AnyIterator {
            defer { fromLeft.switch() }
            return fromLeft ? left.next() : right.next()
        }
    }
}


#if os(Linux)
extension FloatingPoint {
    func multiplied(by value: Self) -> Self {
        return self * value
    }
    func subtracting(_ value: Self) -> Self {
        return self - value
    }
}

extension CGRect {
    public static let null = CGRect(x: CGFloat.infinity,
                                    y: CGFloat.infinity,
                                    width: CGFloat(0),
                                    height: CGFloat(0))
    
    public static let infinite = CGRect(x: -CGFloat.greatestFiniteMagnitude / 2,
                                        y: -CGFloat.greatestFiniteMagnitude / 2,
                                        width: CGFloat.greatestFiniteMagnitude,
                                        height: CGFloat.greatestFiniteMagnitude)

    public var width: CGFloat { return abs(self.size.width) }
    public var height: CGFloat { return abs(self.size.height) }

    public var minX: CGFloat { return self.origin.x + min(self.size.width, 0) }
    public var midX: CGFloat { return (self.minX + self.maxX) * 0.5 }
    public var maxX: CGFloat { return self.origin.x + max(self.size.width, 0) }

    public var minY: CGFloat { return self.origin.y + min(self.size.height, 0) }
    public var midY: CGFloat { return (self.minY + self.maxY) * 0.5 }
    public var maxY: CGFloat { return self.origin.y + max(self.size.height, 0) }

    public var isEmpty: Bool { return self.isNull || self.size.width == 0 || self.size.height == 0 }
    public var isInfinite: Bool { return self == .infinite }
    public var isNull: Bool { return self.origin.x == .infinity || self.origin.y == .infinity }

    public func contains(_ point: CGPoint) -> Bool {
        if self.isNull || self.isEmpty { return false }

        return (self.minX..<self.maxX).contains(point.x) && (self.minY..<self.maxY).contains(point.y)
    }

    public func contains(_ rect2: CGRect) -> Bool {
        return self.union(rect2) == self
    }

    public var standardized: CGRect {
        if self.isNull { return .null }

        return CGRect(x: self.minX,
                      y: self.minY,
                      width: self.width,
                      height: self.height)
    }

    public var integral: CGRect {
        if self.isNull { return self }

        let standardized = self.standardized
        let x = standardized.origin.x.rounded(.down)
        let y = standardized.origin.y.rounded(.down)
        let width = (standardized.origin.x + standardized.size.width).rounded(.up) - x
        let height = (standardized.origin.y + standardized.size.height).rounded(.up) - y
        return CGRect(x: x, y: y, width: width, height: height)
    }

    public func insetBy(dx: CGFloat, dy: CGFloat) -> CGRect {
        if self.isNull { return self }

        var rect = self.standardized

        rect.origin.x += dx
        rect.origin.y += dy
        rect.size.width -= 2 * dx
        rect.size.height -= 2 * dy

        if rect.size.width < 0 || rect.size.height < 0 {
            return .null
        }

        return rect
    }

    public func union(_ r2: CGRect) -> CGRect {
        if self.isNull {
            return r2
        }
        else if r2.isNull {
            return self
        }

        let rect1 = self.standardized
        let rect2 = r2.standardized

        let minX = min(rect1.minX, rect2.minX)
        let minY = min(rect1.minY, rect2.minY)
        let maxX = max(rect1.maxX, rect2.maxX)
        let maxY = max(rect1.maxY, rect2.maxY)

        return CGRect(x: minX,
                      y: minY,
                      width: maxX - minX,
                      height: maxY - minY)
    }

    public func intersection(_ r2: CGRect) -> CGRect {
        if self.isNull || r2.isNull { return .null }

        let rect1 = self.standardized
        let rect2 = r2.standardized

        let rect1SpanH = rect1.minX...rect1.maxX
        let rect1SpanV = rect1.minY...rect1.maxY

        let rect2SpanH = rect2.minX...rect2.maxX
        let rect2SpanV = rect2.minY...rect2.maxY

        if !rect1SpanH.overlaps(rect2SpanH) || !rect1SpanV.overlaps(rect2SpanV) {
            return .null
        }

        let overlapH = rect1SpanH.clamped(to: rect2SpanH)
        let overlapV = rect1SpanV.clamped(to: rect2SpanV)

        return CGRect(x: overlapH.lowerBound,
                      y: overlapV.lowerBound,
                      width: overlapH.upperBound - overlapH.lowerBound,
                      height: overlapV.upperBound - overlapV.lowerBound)
    }

    public func intersects(_ r2: CGRect) -> Bool {
        return !self.intersection(r2).isNull
    }

    public func offsetBy(dx: CGFloat, dy: CGFloat) -> CGRect {
        if self.isNull { return self }

        var rect = self.standardized
        rect.origin.x += dx
        rect.origin.y += dy
        return rect
    }

    public func divided(atDistance: CGFloat, from fromEdge: CGRectEdge) -> (slice: CGRect, remainder: CGRect) {
        if self.isNull { return (.null, .null) }

        let splitLocation: CGFloat
        switch fromEdge {
        case .minXEdge: splitLocation = min(max(atDistance, 0), self.width)
        case .maxXEdge: splitLocation = min(max(self.width - atDistance, 0), self.width)
        case .minYEdge: splitLocation = min(max(atDistance, 0), self.height)
        case .maxYEdge: splitLocation = min(max(self.height - atDistance, 0), self.height)
        }

        let rect = self.standardized
        var rect1 = rect
        var rect2 = rect

        switch fromEdge {
        case .minXEdge: fallthrough
        case .maxXEdge:
            rect1.size.width = splitLocation
            rect2.origin.x = rect1.maxX
            rect2.size.width = rect.width - splitLocation
        case .minYEdge: fallthrough
        case .maxYEdge:
            rect1.size.height = splitLocation
            rect2.origin.y = rect1.maxY
            rect2.size.height = rect.height - splitLocation
        }

        switch fromEdge {
        case .minXEdge: fallthrough
        case .minYEdge: return (rect1, rect2)
        case .maxXEdge: fallthrough
        case .maxYEdge: return (rect2, rect1)
        }
    }
}
#endif
