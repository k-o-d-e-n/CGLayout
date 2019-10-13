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
            // TODO: numberOfLines
            if let txt = syncGuard(mainThread: label.text) {
                #if os(iOS)
                let font = syncGuard(mainThread: label.font) ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
                #else
                let font = syncGuard(mainThread: label.font) ?? UIFont.systemFont(ofSize: 14)
                #endif
                sourceRect.size = txt.boundingRect(
                    with: rect.size,
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: font],
                    context: nil
                ).size
            } else if let attrTxt = syncGuard(mainThread: label.attributedText) {
                sourceRect.size = attrTxt.boundingRect(
                    with: rect.size,
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).size
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

@available(iOS 9.0, *)
extension UILayoutGuide: LayoutElement {
    @objc open var layoutBounds: CGRect { return bounds }
    public var inLayoutTime: ElementInLayoutTime { return _MainThreadItemInLayoutTime(item: self) }
    @objc open var frame: CGRect { get { return layoutFrame } set {} }
    @objc open var bounds: CGRect { get { return CGRect(origin: .zero, size: layoutFrame.size) } set {} }
    public var superElement: LayoutElement? { return owningView }
    @objc open func removeFromSuperElement() { owningView.map { $0.removeLayoutGuide(self) } }
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

#if os(iOS) || os(tvOS)
extension UIView: AnchoredLayoutElement {
    public var layoutAnchors: LayoutAnchors<UIView> { return LayoutAnchors(self) }
}
extension UILayoutGuide: AnchoredLayoutElement {
    public var layoutAnchors: LayoutAnchors<UILayoutGuide> { return LayoutAnchors(self) }
}
#endif

#if os(iOS) || os(tvOS) || os(macOS)
extension CALayer: AnchoredLayoutElement {
    public var layoutAnchors: LayoutAnchors<CALayer> { return LayoutAnchors(self) }
}
#endif
