//
//  CommonExtensions.swift
//  Pods
//
//  Created by Denis Koryttsev on 04/09/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

import Foundation

extension CGRect {
    var left: CGFloat { return minX }
    var right: CGFloat { return maxX }
    var top: CGFloat { return minY }
    var bottom: CGFloat { return maxY }

    var distanceFromOrigin: CGSize { return CGSize(width: maxX, height: maxY) }

    mutating func apply(edgeInsets: UIEdgeInsets) {
        self = UIEdgeInsetsInsetRect(self, edgeInsets)
    }
}

extension UIEdgeInsets {
    var horizontal: CGFloat { return left + right }
    var vertical: CGFloat { return top + bottom }
}

@available(iOS 9.0, *)
extension UILayoutGuide: LayoutItem {
    public var frame: CGRect { get { return layoutFrame } set {} }
    public var bounds: CGRect { get { return CGRect(origin: .zero, size: layoutFrame.size) } set {} }
    public var superItem: LayoutItem? { return owningView }
    public func removeFromSuperItem() { owningView.map { $0.removeLayoutGuide(self) } }
}

public extension CALayer {
    convenience init(frame: CGRect) {
        self.init()
        self.frame = frame
    }
}

extension Collection where IndexDistance == Int, Index == Int {
    var centerIndex: Self.Index? {
        let center: Double = Double(count / 2)
        return center.rounded(.down) == center ? Int(center) : nil
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
