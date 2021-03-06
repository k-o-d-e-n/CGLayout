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
                default:
                    sourceRect.size = image.size
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
                #if os(iOS) && !os(tvOS)
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
    public var baselineElement: Baseline {
        let key = "cglayout.label.baseline"
        guard case let baseline as Baseline = layer.value(forKey: key) else {
            let baseline = Baseline(label: self)
            layer.setValue(baseline, forKey: key)
            return baseline
        }

        return baseline
    }

    public final class Baseline: AnchoredLayoutElement, ElementInLayoutTime {
        unowned let label: UILabel
        public var frame: CGRect {
            set(newValue) {
                _syncGuard({
                    var rect = newValue
                    rect.size.height = label.frame.height
                    rect.origin.x = label.frame.minX
                    #if os(iOS)
                    let font = label.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
                    #else
                    let font = label.font ?? UIFont.systemFont(ofSize: 14)
                    #endif
                    rect.origin.y -= label.textRect(forBounds: label.bounds, limitedToNumberOfLines: label.numberOfLines).origin.y + font.ascender
                    label.frame = rect
                })
            }
            get {
                return _syncGuard({
                    var rect = label.frame
                    rect.size.height = 0
                    #if os(iOS)
                    let font = label.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
                    #else
                    let font = label.font ?? UIFont.systemFont(ofSize: 14)
                    #endif
                    rect.origin.y += label.textRect(forBounds: label.bounds, limitedToNumberOfLines: label.numberOfLines).origin.y + font.ascender
                    return rect
                })
            }
        }
        public var bounds: CGRect {
            set {}
            get { return CGRect(origin: .zero, size: frame.size) }
        }
        public var superElement: LayoutElement? { return label.superview }
        public var layoutBounds: CGRect { return bounds }
        public var inLayoutTime: ElementInLayoutTime { return self }

        public func removeFromSuperElement() {}

        init(label: UILabel) {
            self.label = label
        }
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
extension NSView: AnchoredLayoutElement {}
#endif

#if os(iOS) || os(tvOS)
extension UIView: AnchoredLayoutElement {}
extension UILayoutGuide: AnchoredLayoutElement {}
#endif

#if os(iOS) || os(tvOS) || os(macOS)
extension CALayer: AnchoredLayoutElement {}
#endif
