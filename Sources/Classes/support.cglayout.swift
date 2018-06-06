//
//  Layout.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 29/08/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#elseif os(Linux)
import Foundation
#endif

#if os(iOS) || os(tvOS) || os(macOS)
extension CALayer: LayoutItem {
    public var inLayoutTime: InLayoutTimeItem { return _MainThreadItemInLayoutTime(item: self) }
    public var layoutBounds: CGRect { return bounds }
    public var superItem: LayoutItem? { return superlayer }
    public func removeFromSuperItem() { removeFromSuperlayer() }
}
#endif

#if os(iOS) || os(tvOS)
extension UIView: SelfSizedLayoutItem, AdjustableLayoutItem {
    /// Constraint, that defines content size for item
    public var contentConstraint: RectBasedConstraint { return _MainThreadSizeThatFitsConstraint(item: self) } // TODO: For UILabel need calculate through .boundingRect function
    public /// Entity that represents item in layout time
    var inLayoutTime: InLayoutTimeItem { return _MainThreadItemInLayoutTime(item: self) }
    public /// Internal space for layout subitems
    var layoutBounds: CGRect { return bounds }
    /// Layout item that maintained this layout entity
    public var superItem: LayoutItem? { return superview }
    /// Removes layout item from hierarchy
    public func removeFromSuperItem() { removeFromSuperview() }
}
extension UILabel: TextPresentedItem {
    var baselinePosition: CGFloat {
        return textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines).origin.y + font.ascender
    }
}
extension UITextView: TextPresentedItem { // UITextView scrollable, because baseLine is not responsible
    var baselinePosition: CGFloat {
        return UIEdgeInsetsInsetRect(CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height), textContainerInsets).origin.y + font.ascender
    }
}
extension UIScrollView {
    public /// Internal space for layout subitems
    override var layoutBounds: CGRect { return CGRect(origin: .zero, size: contentSize) }
}
#endif
#if os(macOS)
extension NSView: LayoutItem {
    public /// Removes layout item from hierarchy
    func removeFromSuperItem() { removeFromSuperview() }
    public /// Entity that represents item in layout time
    var inLayoutTime: InLayoutTimeItem { return _MainThreadItemInLayoutTime(item: self) }
    public /// Layout item that maintains this layout entity
    weak var superItem: LayoutItem? { return superview }
    public /// Internal space for layout subitems
    var layoutBounds: CGRect { return bounds }
}
extension NSScrollView {
    public /// Internal space for layout subitems
    override var layoutBounds: CGRect { return documentView?.bounds ?? contentView.bounds } // TODO: Research NSScrollView
}
extension NSControl: SelfSizedLayoutItem, AdjustableLayoutItem {
    /// Constraint, that defines content size for item
    public var contentConstraint: RectBasedConstraint { return _MainThreadSizeThatFitsConstraint(item: self) }
}
#endif