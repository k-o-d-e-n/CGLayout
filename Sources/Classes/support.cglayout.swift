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
extension CALayer: LayoutElement {
    public var inLayoutTime: ElementInLayoutTime { return _MainThreadItemInLayoutTime(item: self) }
    public var layoutBounds: CGRect { return bounds }
    public var superElement: LayoutElement? { return superlayer }
    public func removeFromSuperElement() { removeFromSuperlayer() }
}
#endif

#if os(iOS) || os(tvOS)
extension UIView: AdaptiveLayoutElement {
    public /// Entity that represents element in layout time
    var inLayoutTime: ElementInLayoutTime { return _MainThreadItemInLayoutTime(item: self) }
    @objc public /// Internal space for layout subelements
    var layoutBounds: CGRect { return bounds }
    /// Layout element that maintained this layout entity
    public var superElement: LayoutElement? { return superview }
    /// Removes layout element from hierarchy
    public func removeFromSuperElement() { removeFromSuperview() }
}
extension UIImageView: AdjustableLayoutElement {
    struct ContentConstraint: RectBasedConstraint {
        unowned var imageView: UIImageView

        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
            if let image = syncGuard(mainThread: imageView.image) {
                let imageSize = image.size
                let minWidth = rect.width < rect.height
                switch syncGuard(mainThread: imageView.contentMode) {
                case .scaleAspectFit:
                    if minWidth {
                        sourceRect.size.width = rect.width
                        sourceRect.size.height = (imageSize.height / imageSize.width) * rect.width
                    } else {
                        sourceRect.size.height = rect.height
                        sourceRect.size.width = (imageSize.width / imageSize.height) * rect.height
                    }
                case .scaleAspectFill:
                    if minWidth {
                        sourceRect.size.height = rect.height
                        sourceRect.size.width = (imageSize.width / imageSize.height) * rect.height
                    } else {
                        sourceRect.size.width = rect.width
                        sourceRect.size.height = (imageSize.height / imageSize.width) * rect.width
                    }
                default: break
                }
            } else {
                sourceRect.size = .zero
            }
        }
    }
    public var contentConstraint: RectBasedConstraint {
        return ContentConstraint(imageView: self)
    }
}
extension UILabel: TextPresentedElement, AdjustableLayoutElement {
    struct ContentConstraint: RectBasedConstraint {
        unowned let label: UILabel
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
            if let attrTxt = syncGuard(mainThread: label.attributedText) {
                sourceRect.size = attrTxt.boundingRect(with: rect.size, options: .usesLineFragmentOrigin, context: nil).size
            } else if let txt = syncGuard(mainThread: label.text) {
                sourceRect.size = txt.boundingRect(with: rect.size, options: .usesLineFragmentOrigin,
                                                   attributes: [NSAttributedStringKey.font: label.font], context: nil).size
            } else {
                sourceRect.size = .zero
            }
        }
    }
    public var contentConstraint: RectBasedConstraint {
        return ContentConstraint(label: self)
    }
    public var baselinePosition: CGFloat {
        return textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines).origin.y + font.ascender
    }
}
extension UIScrollView {
    public /// Internal space for layout subelements
    override var layoutBounds: CGRect { return CGRect(origin: .zero, size: contentSize) }
}
#endif
#if os(macOS)
public typealias CGRect = NSRect
extension NSView: LayoutElement {
    public /// Removes layout element from hierarchy
    func removeFromSuperElement() { removeFromSuperview() }
    public /// Entity that represents element in layout time
    var inLayoutTime: ElementInLayoutTime { return _MainThreadItemInLayoutTime(item: self) }
    public /// Layout element that maintains this layout entity
    weak var superElement: LayoutElement? { return superview }
    @objc public /// Internal space for layout subelements
    var layoutBounds: CGRect { return bounds }
}
extension NSScrollView {
    public /// Internal space for layout subelements
    override var layoutBounds: CGRect { return documentView?.bounds ?? contentView.bounds }
}
extension NSControl: AdaptiveLayoutElement, AdjustableLayoutElement {
    /// Constraint, that defines content size for item
    public var contentConstraint: RectBasedConstraint { return _MainThreadSizeThatFitsConstraint(item: self) }
}
#endif
