//
//  CommonExtensions.swift
//  Pods
//
//  Created by Denis Koryttsev on 04/09/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS)
    typealias EdgeInsets = UIEdgeInsets
#endif

extension CGRect {
    var left: CGFloat { return minX }
    var right: CGFloat { return maxX }
    var top: CGFloat { return minY }
    var bottom: CGFloat { return maxY }
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
}

#if os(iOS) || os(tvOS)
@available(iOS 9.0, *)
extension UILayoutGuide: LayoutItem {
    public var frame: CGRect { get { return layoutFrame } set {} }
    public var bounds: CGRect { get { return CGRect(origin: .zero, size: layoutFrame.size) } set {} }
    public var superItem: LayoutItem? { return owningView }
}
#endif

public extension CALayer {
    convenience init(frame: CGRect) {
        self.init()
        self.frame = frame
    }
}
