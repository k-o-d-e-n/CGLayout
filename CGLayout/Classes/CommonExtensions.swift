//
//  CommonExtensions.swift
//  Pods
//
//  Created by Denis Koryttsev on 04/09/2017.
//
//

import Foundation

extension CGRect {
    var left: CGFloat { return minX }
    var right: CGFloat { return maxX }
    var top: CGFloat { return minY }
    var bottom: CGFloat { return maxY }
}

extension UIEdgeInsets {
    var horizontal: CGFloat { return left + right }
    var vertical: CGFloat { return top + bottom }

    public struct Vertical {
        public var top: CGFloat
        public var bottom: CGFloat
        var full: CGFloat { return top + bottom }

        public init(top: CGFloat, bottom: CGFloat) {
            self.top = top
            self.bottom = bottom
        }
    }
    public struct Horizontal {
        public var left: CGFloat
        public var right: CGFloat
        var full: CGFloat { return left + right }

        public init(left: CGFloat, right: CGFloat) {
            self.left = left
            self.right = right
        }
    }
    public init(vertical: Vertical, horizontal: Horizontal) {
        self.init(top: vertical.top, left: horizontal.left, bottom: vertical.bottom, right: horizontal.right)
    }
}
