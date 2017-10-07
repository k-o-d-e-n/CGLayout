//
//  CommonExtensions.swift
//  Pods
//
//  Created by Denis Koryttsev on 04/09/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS)
    public typealias EdgeInsets = UIEdgeInsets
#endif

extension CGRect {
    var left: CGFloat { return minX }
    var right: CGFloat { return maxX }
    var top: CGFloat { return minY }
    var bottom: CGFloat { return maxY }
    
    var distanceFromOrigin: CGSize { return CGSize(width: maxX, height: maxY) }
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
}

extension EdgeInsets {
    var horizontal: CGFloat { return left + right }
    var vertical: CGFloat { return top + bottom }
#if os(macOS)
    public static var zero: EdgeInsets { return EdgeInsets(top: 0, left: 0, bottom: 0, right: 0) }
#endif
}

#if os(iOS) || os(tvOS)
@available(iOS 9.0, *)
extension UILayoutGuide: LayoutItem {
    public var inLayoutTime: InLayoutTimeItem { return _MainThreadItemInLayoutTime(item: self) }
    public var frame: CGRect { get { return layoutFrame } set {} }
    public var bounds: CGRect { get { return CGRect(origin: .zero, size: layoutFrame.size) } set {} }
    public var superItem: LayoutItem? { return owningView }
    public func removeFromSuperItem() { owningView.map { $0.removeLayoutGuide(self) } }
}
#endif

public extension CALayer {
    convenience init(frame: CGRect) {
        self.init()
        self.frame = frame
    }
}

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

